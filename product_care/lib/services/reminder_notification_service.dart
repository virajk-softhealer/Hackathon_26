import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../app/app_localizations.dart';
import '../models/product.dart';
import 'product_store.dart';

class ReminderNotificationService {
  ReminderNotificationService();

  static const _channelId = 'product_care_reminders';
  static const _testNotificationId = 2147000000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  void Function(String? productId)? _onNotificationTap;
  bool _initialized = false;

  Future<void> initialize({
    required void Function(String? productId) onNotificationTap,
  }) async {
    _onNotificationTap = onNotificationTap;
    if (_initialized) return;

    timezone_data.initializeTimeZones();
    if (!kIsWeb) {
      try {
        final deviceTimezone = await FlutterTimezone.getLocalTimezone();
        timezone.setLocalLocation(timezone.getLocation(deviceTimezone.identifier));
      } catch (_) {
        timezone.setLocalLocation(timezone.getLocation('Etc/UTC'));
      }
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        web: WebInitializationSettings(defaultIcon: 'icons/Icon-192.png'),
      ),
      onDidReceiveNotificationResponse: (response) {
        _onNotificationTap?.call(response.payload);
      },
    );
    _initialized = true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _onNotificationTap?.call(
        launchDetails?.notificationResponse?.payload,
      );
    }
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    if (kIsWeb) {
      final web = _plugin.resolvePlatformSpecificImplementation<
        WebFlutterLocalNotificationsPlugin
      >();
      if (web == null) return false;
      if (web.permissionStatus == WebNotificationPermission.granted) return true;
      return web.requestNotificationsPermission();
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
      if (await android?.areNotificationsEnabled() ?? false) return true;
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
      final current = await ios?.checkPermissions();
      if (current?.isEnabled ?? false) return true;
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<bool> hasPermission() async {
    if (!_initialized) return false;
    if (kIsWeb) {
      final web = _plugin.resolvePlatformSpecificImplementation<
        WebFlutterLocalNotificationsPlugin
      >();
      return web?.permissionStatus == WebNotificationPermission.granted;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return status?.isEnabled ?? false;
    }
    return true;
  }

  Future<bool> syncSchedule(
    ProductStore store, {
    bool forceReschedule = false,
  }) async {
    if (!_initialized) return false;
    if (!await hasPermission()) return false;

    final language = ProductCareLocalizations(Locale(store.languageCode));
    final now = timezone.TZDateTime.now(timezone.local);
    final pending = await _plugin.pendingNotificationRequests();
    if (forceReschedule) {
      for (final request in pending) {
        await _plugin.cancel(id: request.id);
      }
      pending.clear();
    }
    final pendingIds = pending.map((request) => request.id).toSet();
    final desiredIds = <int>{};
    var storeChanged = false;

    for (final product in store.products) {
      for (final event in _eventsFor(product)) {
        final eventDate = _dateAtMidnight(event.date);
        for (final leadDays in <int>{...store.reminderDays, 0}) {
          final key = _eventKey(product, event, leadDays);
          final id = _stableId(key);
          final trigger = _scheduledTime(eventDate, leadDays);

          if (trigger == null || !trigger.isAfter(now)) {
            final daysUntil = eventDate.difference(_dateAtMidnight(DateTime.now())).inDays;
            final isDueTodayOrPast = leadDays == 0 && daysUntil <= 0;
            final isMissedLeadDay =
                leadDays > 0 && daysUntil > 0 && daysUntil <= leadDays;
            if ((isDueTodayOrPast || isMissedLeadDay) &&
                !store.notificationKeys.contains(key)) {
              await _showEventNow(
                id: id,
                product: product,
                event: event,
                daysUntil: daysUntil,
                isDue: isDueTodayOrPast,
                language: language,
              );
              store.notificationKeys.add(key);
              storeChanged = true;
            }
            continue;
          }

          desiredIds.add(id);
          if (pendingIds.contains(id)) continue;
          await _plugin.zonedSchedule(
            id: id,
            title: _title(product, event, leadDays == 0, language),
            body: _body(product, event, leadDays, language),
            scheduledDate: trigger,
            notificationDetails: _notificationDetails(language),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: product.id,
          );
          store.notificationKeys.add(key);
          storeChanged = true;
        }
      }
    }

    for (final request in pending) {
      if (!desiredIds.contains(request.id)) {
        await _plugin.cancel(id: request.id);
      }
    }
    if (storeChanged) await store.persist();
    return true;
  }

  Future<void> sendTestNotification(ProductStore store) async {
    if (!await hasPermission()) return;
    final candidates = store.products
        .expand((product) => _eventsFor(product).map((event) => (product, event)))
        .toList();
    if (candidates.isEmpty) return;
    final (product, _) = candidates.first;
    final language = ProductCareLocalizations(Locale(store.languageCode));
    await _plugin.show(
      id: _testNotificationId,
      title: language.translate('Test notification: {name}', {'name': product.name}),
      body: language.translate('This is a Product Care reminder test.'),
      notificationDetails: _notificationDetails(language),
      payload: product.id,
    );
  }

  List<_ReminderEvent> _eventsFor(Product product) {
    if (product.kind == ProductKind.storable &&
        product.quantity > 0 &&
        product.expiry != null) {
      return [_ReminderEvent(ReminderType.expiry, product.expiry!)];
    }
    if (product.kind == ProductKind.service) {
      return [
        if (product.service != null)
          _ReminderEvent(ReminderType.service, product.service!),
        if (product.warranty != null)
          _ReminderEvent(ReminderType.warranty, product.warranty!),
      ];
    }
    return const [];
  }

  timezone.TZDateTime? _scheduledTime(DateTime dueDate, int leadDays) {
    final now = timezone.TZDateTime.now(timezone.local);
    final reminderDate = dueDate.subtract(Duration(days: leadDays));
    var scheduled = timezone.TZDateTime(
      timezone.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
    );
    if (scheduled.isBefore(now)) {
      final today = _dateAtMidnight(DateTime.now());
      if (_dateAtMidnight(reminderDate).isAtSameMomentAs(today)) {
        scheduled = now.add(const Duration(minutes: 1));
      } else {
        return null;
      }
    }
    return scheduled;
  }

  DateTime _dateAtMidnight(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _eventKey(Product product, _ReminderEvent event, int leadDays) =>
      '${product.id}|${event.type.name}|${event.date.toIso8601String().substring(0, 10)}|$leadDays';

  int _stableId(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7FFFFFFF;
    }
    return hash == 0 ? 1 : hash;
  }

  Future<void> _showEventNow({
    required int id,
    required Product product,
    required _ReminderEvent event,
    required int daysUntil,
    required bool isDue,
    required ProductCareLocalizations language,
  }) async {
    await _plugin.show(
      id: id,
      title: _title(product, event, isDue, language),
      body: _body(product, event, isDue ? 0 : daysUntil, language),
      notificationDetails: _notificationDetails(language),
      payload: product.id,
    );
  }

  String _title(
    Product product,
    _ReminderEvent event,
    bool isDue,
    ProductCareLocalizations language,
  ) {
    final source = switch (event.type) {
      ReminderType.expiry => 'Expiry Reminder: {name}',
      ReminderType.service => 'Service Reminder: {name}',
      ReminderType.warranty => 'Warranty Reminder: {name}',
    };
    final title = language.translate(source, {'name': product.name});
    return isDue
        ? language.translate('Due today: {title}', {'title': title})
        : title;
  }

  String _body(
    Product product,
    _ReminderEvent event,
    int days,
    ProductCareLocalizations language,
  ) {
    if (days <= 0) {
      final source = switch (event.type) {
        ReminderType.expiry => 'This product expires today. Review your stock.',
        ReminderType.service => 'This product is due for service today.',
        ReminderType.warranty => 'This product warranty expires today.',
      };
      return language.translate(source, {'name': product.name});
    }
    final source = switch (event.type) {
      ReminderType.expiry => 'This product expires in {days} days. Review your stock.',
      ReminderType.service => 'This product requires service in {days} days.',
      ReminderType.warranty => 'This product warranty expires in {days} days.',
    };
    return language.translate(source, {'name': product.name, 'days': days});
  }

  NotificationDetails _notificationDetails(
    ProductCareLocalizations language,
  ) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          language.translate('Product Care reminders'),
          channelDescription: language.translate(
            'Expiry, service, and warranty reminders',
          ),
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
}

enum ReminderType { expiry, service, warranty }

class _ReminderEvent {
  const _ReminderEvent(this.type, this.date);

  final ReminderType type;
  final DateTime date;
}
