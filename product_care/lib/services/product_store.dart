import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/sample_products.dart';
import '../models/product.dart';

/// Local JSON-backed product repository for the current app version.
class ProductStore {
  ProductStore() : products = createSampleProducts();

  static const backupFormat = 'product_care_backup';
  static const schemaVersion = 1;

  final List<Product> products;
  final List<String> losses = [];
  final Set<String> notificationKeys = {};
  Set<int> reminderDays = {3};
  String languageCode = 'en';
  File? _dataFile;
  String? loadError;
  Future<void> _writeQueue = Future<void>.value();

  static Future<ProductStore> open() async {
    final store = ProductStore();
    final directory = await getApplicationDocumentsDirectory();
    store._dataFile = File('${directory.path}/product_care_data.json');
    if (await store._dataFile!.exists()) {
      try {
        final decoded = jsonDecode(await store._dataFile!.readAsString());
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Saved Product Care data is invalid.');
        }
        store._applySnapshot(ProductCareSnapshot.fromJson(decoded));
        await store.persist();
      } on FormatException catch (error) {
        store.loadError = error.message;
      }
    } else {
      await store.persist();
    }
    return store;
  }

  int get expiringSoon => products
      .where(
        (product) =>
            product.isConfirmed &&
            product.kind == ProductKind.storable &&
            product.daysToExpiry != null &&
            product.daysToExpiry! >= 0 &&
            product.daysToExpiry! <= 7 &&
            product.quantity > 0,
      )
      .length;

  int get lowStock => products
      .where(
        (product) =>
            product.isConfirmed &&
            product.kind != ProductKind.service &&
            product.quantity <= 1,
      )
      .length;

  int get totalUnits => products
      .where(
        (product) =>
            product.isConfirmed && product.kind != ProductKind.service,
      )
      .fold(0, (total, product) => total + product.quantity);

  int get draftCount => products.where((product) => product.isDraft).length;

  void addProduct(Product product) => products.insert(0, product);

  bool updateProduct(Product product) {
    final index = products.indexWhere((entry) => entry.id == product.id);
    if (index < 0) return false;
    products[index] = product;
    return true;
  }

  bool confirmProduct(Product product) {
    final index = products.indexWhere((entry) => entry.id == product.id);
    if (index < 0) return false;
    products[index] = product.copyWith(status: ProductStatus.confirmed);
    return true;
  }

  void setReminderDays(Set<int> days) => reminderDays = Set<int>.of(days);

  void setLanguageCode(String code) => languageCode = code;

  bool recordLoss(Product product, int quantity, {String? batchNumber}) {
    if (product.kind == ProductKind.service ||
        quantity < 1 ||
        quantity > product.quantity) {
      return false;
    }
    if (batchNumber != null && product.batches.isNotEmpty) {
      final b =
          product.batches.where((entry) => entry.batchNumber == batchNumber);
      if (b.isNotEmpty && b.first.quantity >= quantity) {
        b.first.quantity -= quantity;
      } else {
        var remaining = quantity;
        for (final batch in product.batches) {
          if (batch.quantity <= 0) continue;
          final take =
              remaining < batch.quantity ? remaining : batch.quantity;
          batch.quantity -= take;
          remaining -= take;
          if (remaining <= 0) break;
        }
      }
    } else if (product.batches.isNotEmpty) {
      var remaining = quantity;
      for (final batch in product.batches) {
        if (batch.quantity <= 0) continue;
        final take = remaining < batch.quantity ? remaining : batch.quantity;
        batch.quantity -= take;
        remaining -= take;
        if (remaining <= 0) break;
      }
    } else {
      product.quantity -= quantity;
    }
    final batchInfo = batchNumber != null ? ' ($batchNumber)' : '';
    losses.add(
      '${product.name}$batchInfo · $quantity ${product.unit} · ${DateTime.now().toIso8601String().substring(0, 10)}',
    );
    return true;
  }

  Map<String, Object?> toJson({bool includeBackupMetadata = false}) => {
    'format': backupFormat,
    'version': schemaVersion,
    if (includeBackupMetadata)
      'created_at': DateTime.now().toUtc().toIso8601String(),
    'products': products.map((product) => product.toJson()).toList(),
    'losses': List<String>.of(losses),
    'notification_keys': notificationKeys.toList()..sort(),
    'reminder_days': reminderDays.toList()..sort(),
    'language_code': languageCode,
  };

  Future<void> persist() async {
    final file = _dataFile;
    if (file == null) return;
    if (loadError != null) {
      throw StateError('Saved Product Care data is invalid and needs restore.');
    }
    await _enqueueWrite(file, toJson());
  }

  Future<void> restore(ProductCareSnapshot snapshot) async {
    final file = _dataFile;
    if (file == null) throw StateError('Product Care storage is not ready.');
    await _enqueueWrite(file, snapshot.toJson());
    _applySnapshot(snapshot);
    loadError = null;
  }

  void _applySnapshot(ProductCareSnapshot snapshot) {
    products
      ..clear()
      ..addAll(snapshot.products);
    losses
      ..clear()
      ..addAll(snapshot.losses);
    notificationKeys
      ..clear()
      ..addAll(snapshot.notificationKeys);
    reminderDays = Set<int>.of(snapshot.reminderDays);
    languageCode = snapshot.languageCode;
  }

  Future<void> _enqueueWrite(
    File destination,
    Map<String, Object?> data,
  ) async {
    final json = jsonEncode(data);
    final nextWrite = _writeQueue.then((_) async {
      await destination.parent.create(recursive: true);
      final temporary = File(
        '${destination.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
      );
      await temporary.writeAsString(json, flush: true);
      await temporary.rename(destination.path);
    });
    _writeQueue = nextWrite.catchError((Object _) {});
    await nextWrite;
  }
}

class ProductCareSnapshot {
  const ProductCareSnapshot({
    required this.products,
    required this.losses,
    required this.reminderDays,
    required this.languageCode,
    required this.notificationKeys,
  });

  final List<Product> products;
  final List<String> losses;
  final Set<int> reminderDays;
  final String languageCode;
  final Set<String> notificationKeys;

  factory ProductCareSnapshot.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('format') &&
        json['format'] != ProductStore.backupFormat) {
      throw const FormatException('This backup format is not supported.');
    }
    final rawProducts = json['products'] ?? json['items'];
    if (rawProducts is! List) {
      throw const FormatException('The backup is missing required data.');
    }
    final rawLosses = json['losses'] is List ? json['losses'] as List : const [];
    final rawReminderDays = json['reminder_days'] is List
        ? json['reminder_days'] as List
        : const [3];
    final candidateLang = (json['language_code'] ?? 'en').toString();
    final rawLanguageCode = const {'en', 'hi', 'gu'}.contains(candidateLang)
        ? candidateLang
        : 'en';
    final rawNotificationKeys = json['notification_keys'] is List
        ? json['notification_keys'] as List
        : const [];

    final products = <Product>[];
    for (final record in rawProducts) {
      if (record is Map<String, dynamic>) {
        products.add(Product.fromJson(record));
      } else if (record is Map) {
        products.add(Product.fromJson(Map<String, Object?>.from(record)));
      }
    }

    final losses = <String>[];
    for (final entry in rawLosses) {
      if (entry != null) losses.add(entry.toString());
    }

    final notificationKeys = <String>{};
    for (final entry in rawNotificationKeys) {
      if (entry != null) notificationKeys.add(entry.toString());
    }

    final decodedReminderDays = <int>{};
    for (final entry in rawReminderDays) {
      if (entry is int && entry >= 1 && entry <= 365) {
        decodedReminderDays.add(entry);
      } else if (entry != null) {
        final parsed = int.tryParse(entry.toString());
        if (parsed != null && parsed >= 1 && parsed <= 365) {
          decodedReminderDays.add(parsed);
        }
      }
    }
    final normalizedReminderDays = decodedReminderDays.isEmpty
        ? {3}
        : decodedReminderDays.length == 1
        ? decodedReminderDays
        : {
            decodedReminderDays.contains(3)
                ? 3
                : decodedReminderDays.reduce((a, b) => a > b ? a : b),
          };

    return ProductCareSnapshot(
      products: products,
      losses: losses,
      reminderDays: normalizedReminderDays,
      languageCode: rawLanguageCode,
      notificationKeys: notificationKeys,
    );
  }

  Map<String, Object?> toJson() => {
    'format': ProductStore.backupFormat,
    'version': ProductStore.schemaVersion,
    'products': products.map((product) => product.toJson()).toList(),
    'losses': losses,
    'notification_keys': notificationKeys.toList()..sort(),
    'reminder_days': reminderDays.toList()..sort(),
    'language_code': languageCode,
  };
}
