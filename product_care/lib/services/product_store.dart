import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/sample_products.dart';
import '../models/product.dart';
import '../utils/date_formatters.dart';

/// Local JSON-backed product repository for the current app version.
class ProductStore {
  ProductStore() : products = createSampleProducts();

  static const backupFormat = 'product_care_backup';
  static const schemaVersion = 1;

  final List<Product> products;
  final List<String> losses = [];
  Set<int> reminderDays = {1, 3};
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
            product.kind != ProductKind.service && product.quantity <= 1,
      )
      .length;

  int get totalUnits => products
      .where((product) => product.kind != ProductKind.service)
      .fold(0, (total, product) => total + product.quantity);

  void addProduct(Product product) => products.add(product);

  void setReminderDays(Set<int> days) => reminderDays = Set<int>.of(days);

  bool recordLoss(Product product, int quantity) {
    if (product.kind == ProductKind.service ||
        quantity < 1 ||
        quantity > product.quantity) {
      return false;
    }
    product.quantity -= quantity;
    losses.add(
      '${product.name} · $quantity ${product.unit} · ${formatShortDate(DateTime.now())}',
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
    'reminder_days': reminderDays.toList()..sort(),
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
    reminderDays = Set<int>.of(snapshot.reminderDays);
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
  });

  final List<Product> products;
  final List<String> losses;
  final Set<int> reminderDays;

  factory ProductCareSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['format'] != ProductStore.backupFormat ||
        json['version'] != ProductStore.schemaVersion) {
      throw const FormatException('This backup format is not supported.');
    }
    final rawProducts = json['products'];
    final rawLosses = json['losses'];
    final rawReminderDays = json['reminder_days'];
    if (rawProducts is! List ||
        rawLosses is! List ||
        rawReminderDays is! List) {
      throw const FormatException('The backup is missing required data.');
    }
    final products = rawProducts.map((record) {
      if (record is! Map<String, dynamic>) {
        throw const FormatException(
          'A product record in the backup is invalid.',
        );
      }
      return Product.fromJson(record);
    }).toList();
    if (rawLosses.any((entry) => entry is! String) ||
        rawReminderDays.any(
          (entry) => entry is! int || entry < 1 || entry > 365,
        )) {
      throw const FormatException(
        'The backup contains invalid settings or history.',
      );
    }
    return ProductCareSnapshot(
      products: products,
      losses: rawLosses.cast<String>(),
      reminderDays: rawReminderDays.cast<int>().toSet(),
    );
  }

  Map<String, Object?> toJson() => {
    'format': ProductStore.backupFormat,
    'version': ProductStore.schemaVersion,
    'products': products.map((product) => product.toJson()).toList(),
    'losses': losses,
    'reminder_days': reminderDays.toList()..sort(),
  };
}
