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
        web: WebInitializationSettings(),
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
      return await web.requestNotificationsPermission() ?? false;
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
          final isExpired = leadDays == 0 && eventDate.isBefore(_dateAtMidnight(DateTime.now()));
          final key = _eventKey(product, event, leadDays, isExpired: isExpired);
          final id = _stableId(key);
          final trigger = _scheduledTime(eventDate, leadDays);

          if (trigger == null || !trigger.isAfter(now)) {
            final daysUntil = eventDate.difference(_dateAtMidnight(DateTime.now())).inDays;
            final isDueOrExpired = leadDays == 0 && daysUntil <= 0;
            final isMissedLeadDay =
                leadDays > 0 && daysUntil > 0 && daysUntil <= leadDays;
            if ((isDueOrExpired || isMissedLeadDay) &&
                !store.notificationKeys.contains(key)) {
              await _showEventNow(
                id: id,
                product: product,
                event: event,
                daysUntil: daysUntil,
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
            title: _title(product, event, leadDays, language),
            body: _body(product, event, leadDays, language),
            scheduledDate: trigger,
            notificationDetails: _notificationDetails(language),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: product.id,
          );
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

  Future<void> checkAndTriggerImmediateAlert({
    required Product product,
    required ProductStore store,
  }) async {
    if (!_initialized) return;
    if (!await hasPermission()) return;
    final language = ProductCareLocalizations(Locale(store.languageCode));
    final now = _dateAtMidnight(DateTime.now());
    final reminderThreshold = store.reminderDays.isEmpty ? 3 : store.reminderDays.first;

    for (final event in _eventsFor(product)) {
      final eventDate = _dateAtMidnight(event.date);
      final daysUntil = eventDate.difference(now).inDays;

      if (daysUntil <= reminderThreshold) {
        final isExpired = daysUntil < 0;
        final key = _eventKey(product, event, 0, isExpired: isExpired);
        if (!store.notificationKeys.contains(key)) {
          final id = _stableId(key);
          await _plugin.show(
            id: id,
            title: _title(product, event, daysUntil, language),
            body: _body(product, event, daysUntil, language),
            notificationDetails: _notificationDetails(language),
            payload: product.id,
          );
          store.notificationKeys.add(key);
          await store.persist();
        }
      }
    }
  }

  Future<bool> sendTestNotification(ProductStore store) async {
    if (!await hasPermission()) return false;
    final candidates = store.products
        .expand((product) => _eventsFor(product).map((event) => (product, event)))
        .toList();
    if (candidates.isEmpty) return false;
    final (product, _) = candidates.first;
    final language = ProductCareLocalizations(Locale(store.languageCode));
    await _plugin.show(
      id: _testNotificationId,
      title: language.translate('Test notification: {name}', {'name': product.name}),
      body: language.translate('This is a Product Care reminder test.'),
      notificationDetails: _notificationDetails(language),
      payload: product.id,
    );
    return true;
  }

  List<_ReminderEvent> _eventsFor(Product product) {
    final events = <_ReminderEvent>[];
    if (product.expiry != null &&
        (product.kind != ProductKind.storable || product.quantity > 0)) {
      events.add(_ReminderEvent(ReminderType.expiry, product.expiry!));
    }
    final serviceDate = product.serviceEndDate ?? product.serviceStartDate;
    if (serviceDate != null) {
      events.add(_ReminderEvent(ReminderType.service, serviceDate));
    }
    return events;
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

  String _eventKey(
    Product product,
    _ReminderEvent event,
    int leadDays, {
    bool isExpired = false,
  }) =>
      '${product.id}|${event.type.name}|${event.date.toIso8601String().substring(0, 10)}|${isExpired ? "EXPIRED" : leadDays}';

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
    required ProductCareLocalizations language,
  }) async {
    await _plugin.show(
      id: id,
      title: _title(product, event, daysUntil, language),
      body: _body(product, event, daysUntil, language),
      notificationDetails: _notificationDetails(language),
      payload: product.id,
    );
  }

  String _title(
    Product product,
    _ReminderEvent event,
    int days,
    ProductCareLocalizations language,
  ) {
    final source = switch (event.type) {
      ReminderType.expiry => 'Expiry Reminder: {name}',
      ReminderType.service => 'Service Reminder: {name}',
    };
    final baseTitle = language.translate(source, {'name': product.name});
    if (days < 0) {
      return event.type == ReminderType.service
          ? language.translate('Service Expired: {name}', {'name': product.name})
          : language.translate('Product Expired: {name}', {'name': product.name});
    }
    if (days == 0) {
      return language.translate('Due today: {title}', {'title': baseTitle});
    }
    return baseTitle;
  }

  String _body(
    Product product,
    _ReminderEvent event,
    int days,
    ProductCareLocalizations language,
  ) {
    if (days < 0) {
      final source = switch (event.type) {
        ReminderType.expiry => 'This product has expired. Review your stock.',
        ReminderType.service => 'This product service has expired and is overdue.',
      };
      return language.translate(source, {'name': product.name});
    }
    if (days == 0) {
      final source = switch (event.type) {
        ReminderType.expiry => 'This product expires today. Review your stock.',
        ReminderType.service => 'This product is due for service today.',
      };
      return language.translate(source, {'name': product.name});
    }
    final source = switch (event.type) {
      ReminderType.expiry => 'This product expires in {days} days. Review your stock.',
      ReminderType.service => 'This product requires service in {days} days.',
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
            'Expiry and service reminders',
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

enum ReminderType { expiry, service }

class _ReminderEvent {
  const _ReminderEvent(this.type, this.date);

  final ReminderType type;
  final DateTime date;
}
