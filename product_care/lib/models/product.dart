enum ProductKind { storable, service, general }

enum ProductStatus { confirmed, draft }

class ProductBatch {
  ProductBatch({
    required this.batchNumber,
    required this.quantity,
    this.expiry,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String batchNumber;
  int quantity;
  DateTime? expiry;
  final DateTime createdAt;

  int? get daysToExpiry {
    if (expiry == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry!.year, expiry!.month, expiry!.day);
    return expiryDay.difference(today).inDays;
  }

  Map<String, Object?> toJson() => {
        'batch_number': batchNumber,
        'quantity': quantity,
        'expiry': expiry?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory ProductBatch.fromJson(Map<String, Object?> json) => ProductBatch(
        batchNumber: (json['batch_number'] ?? 'BATCH-00001').toString(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        expiry: json['expiry'] != null
            ? DateTime.tryParse(json['expiry'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
}

String generateNextBatchNumber(
  String productName,
  Iterable<ProductBatch> existingBatches,
) {
  var clean = productName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  if (clean.isEmpty) clean = 'BATCH';
  if (clean.length > 8) clean = clean.substring(0, 8);

  var maxSeq = 0;
  final pattern = RegExp('^${RegExp.escape(clean)}-(\\d+)\$');
  for (final b in existingBatches) {
    final match = pattern.firstMatch(b.batchNumber);
    if (match != null) {
      final seq = int.tryParse(match.group(1)!) ?? 0;
      if (seq > maxSeq) maxSeq = seq;
    }
  }
  final nextSeq = maxSeq + 1;
  final padWidth = nextSeq < 100000 ? 5 : nextSeq.toString().length;
  return '$clean-${nextSeq.toString().padLeft(padWidth, '0')}';
}

class Product {
  static int _nextGeneratedId = 0;

  Product({
    String? id,
    required this.name,
    required this.brand,
    required this.category,
    required int quantity,
    required this.unit,
    DateTime? expiry,
    this.service,
    this.serviceEnd,
    this.cost = 0,
    this.kind = ProductKind.storable,
    this.status = ProductStatus.confirmed,
    this.barcode,
    this.imageUrl,
    this.storageInstructions,
    Map<String, String>? additionalDetails,
    List<ProductBatch>? batches,
  })  : id = id ?? _newId(),
        _quantity = quantity < 0 ? 0 : quantity,
        _baseExpiry = expiry,
        additionalDetails = additionalDetails != null
            ? Map<String, String>.of(additionalDetails)
            : <String, String>{},
        batches = batches != null
            ? List<ProductBatch>.of(batches)
            : <ProductBatch>[];

  final String id;
  final String name;
  final String brand;
  final String category;
  int _quantity;
  final String unit;
  DateTime? _baseExpiry;
  final DateTime? service;
  final DateTime? serviceEnd;
  final double cost;
  final ProductKind kind;
  final ProductStatus status;
  final String? barcode;
  final String? imageUrl;
  final String? storageInstructions;
  final Map<String, String> additionalDetails;
  final List<ProductBatch> batches;

  bool get isDraft => status == ProductStatus.draft;
  bool get isConfirmed => status == ProductStatus.confirmed;

  int get quantity {
    if (kind == ProductKind.storable && batches.isNotEmpty) {
      return batches.fold(0, (total, b) => total + b.quantity);
    }
    return _quantity;
  }

  set quantity(int value) {
    final clamped = value < 0 ? 0 : value;
    _quantity = clamped;
    if (kind == ProductKind.storable && batches.isNotEmpty) {
      if (clamped == 0) {
        for (final b in batches) {
          b.quantity = 0;
        }
      } else if (batches.length == 1) {
        batches.first.quantity = clamped;
      }
    }
  }

  DateTime? get expiry {
    if (kind == ProductKind.storable && batches.isNotEmpty) {
      final withStock = batches
          .where((b) => b.quantity > 0 && b.expiry != null)
          .toList()
        ..sort((a, b) => a.expiry!.compareTo(b.expiry!));
      if (withStock.isNotEmpty) return withStock.first.expiry;

      final anyExpiry = batches
          .where((b) => b.expiry != null)
          .toList()
        ..sort((a, b) => a.expiry!.compareTo(b.expiry!));
      if (anyExpiry.isNotEmpty) return anyExpiry.first.expiry;
    }
    return _baseExpiry;
  }

  set expiry(DateTime? newExpiry) {
    _baseExpiry = newExpiry;
    if (kind == ProductKind.storable && batches.isNotEmpty) {
      if (batches.length == 1) {
        batches.first.expiry = newExpiry;
      } else {
        final withStock = batches.where((b) => b.quantity > 0).toList();
        if (withStock.isNotEmpty) {
          withStock.first.expiry = newExpiry;
        } else {
          batches.first.expiry = newExpiry;
        }
      }
    }
  }

  bool updateBatchExpiry(String batchNumber, DateTime? newExpiry) {
    for (final b in batches) {
      if (b.batchNumber == batchNumber) {
        b.expiry = newExpiry;
        _baseExpiry = expiry;
        return true;
      }
    }
    return false;
  }

  ProductBatch? get earliestExpiringBatch {
    if (kind != ProductKind.storable || batches.isEmpty) return null;
    final withStock = batches
        .where((b) => b.quantity > 0 && b.expiry != null)
        .toList()
      ..sort((a, b) => a.expiry!.compareTo(b.expiry!));
    if (withStock.isNotEmpty) return withStock.first;
    return null;
  }

  DateTime? get serviceStartDate => service;
  DateTime? get serviceEndDate =>
      serviceEnd ?? (kind == ProductKind.service ? _baseExpiry : null);

  int? get daysToExpiry {
    final exp = expiry;
    if (exp == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(exp.year, exp.month, exp.day);
    return expiryDay.difference(today).inDays;
  }

  int? get daysToService {
    final target = serviceEndDate ?? service;
    if (target == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final serviceDay = DateTime(target.year, target.month, target.day);
    return serviceDay.difference(today).inDays;
  }

  Product copyWith({
    String? name,
    String? brand,
    String? category,
    int? quantity,
    String? unit,
    DateTime? expiry,
    DateTime? service,
    DateTime? serviceEnd,
    double? cost,
    ProductKind? kind,
    ProductStatus? status,
    String? barcode,
    String? imageUrl,
    String? storageInstructions,
    Map<String, String>? additionalDetails,
    List<ProductBatch>? batches,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        expiry: expiry ?? _baseExpiry,
        service: service ?? this.service,
        serviceEnd: serviceEnd ?? this.serviceEnd,
        cost: cost ?? this.cost,
        kind: kind ?? this.kind,
        status: status ?? this.status,
        barcode: barcode ?? this.barcode,
        imageUrl: imageUrl ?? this.imageUrl,
        storageInstructions: storageInstructions ?? this.storageInstructions,
        additionalDetails: additionalDetails ?? this.additionalDetails,
        batches: batches ?? this.batches,
      );

  static String _newId() =>
      'product_${DateTime.now().microsecondsSinceEpoch}_${_nextGeneratedId++}';

  Map<String, Object?> toJson() => {
        'name': name,
        'id': id,
        'brand': brand,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'expiry': expiry?.toIso8601String(),
        'service': service?.toIso8601String(),
        'service_end': (serviceEnd ?? (kind == ProductKind.service ? expiry : null))
            ?.toIso8601String(),
        'cost': cost,
        'kind': kind.name,
        'status': status.name,
        'barcode': barcode,
        'image_url': imageUrl,
        'storage_instructions': storageInstructions,
        'additional_details': additionalDetails,
        'batches': batches.map((b) => b.toJson()).toList(),
      };

  factory Product.fromJson(Map<String, Object?> json) {
    final rawName = json['name'];
    if (rawName == null || rawName.toString().trim().isEmpty) {
      throw const FormatException('A product record is missing a valid name.');
    }
    final name = rawName.toString().trim();
    final rawId = json['id']?.toString();
    final rawBrand = json['brand'];
    final brand = rawBrand != null && rawBrand != 'Unbranded'
        ? rawBrand.toString().trim()
        : '';
    final category = (json['category'] ?? 'Other').toString();
    final unit = (json['unit'] ?? 'units').toString();
    final rawKind = (json['kind'] ?? 'storable').toString().toLowerCase();
    final kindMatch = ProductKind.values.where(
      (value) => value.name.toLowerCase() == rawKind,
    );
    final kind = kindMatch.isNotEmpty ? kindMatch.first : ProductKind.storable;

    final rawStatus = (json['status'] ?? 'confirmed').toString().toLowerCase();
    final status = rawStatus == 'draft' ? ProductStatus.draft : ProductStatus.confirmed;

    final barcode = json['barcode']?.toString();
    final imageUrl = json['image_url']?.toString();
    final storageInstructions = json['storage_instructions']?.toString();
    final rawDetails = json['additional_details'];
    final additionalDetails = <String, String>{};
    if (rawDetails is Map) {
      for (final entry in rawDetails.entries) {
        if (entry.key != null && entry.value != null) {
          additionalDetails[entry.key.toString()] = entry.value.toString();
        }
      }
    }

    final rawQuantity = json['quantity'];
    final quantity = rawQuantity is num
        ? rawQuantity.toInt()
        : (int.tryParse('$rawQuantity') ?? 1);

    DateTime? parseDate(Object? value) {
      if (value == null) return null;
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final rawCost = json['cost'];
    final cost = rawCost is num
        ? rawCost.toDouble()
        : (double.tryParse('$rawCost') ?? 0.0);

    final parsedExpiry = parseDate(json['expiry']);
    final parsedService = parseDate(json['service'] ?? json['service_start']);
    final parsedServiceEnd = parseDate(
      json['service_end'] ??
          (kind == ProductKind.service
              ? json['expiry'] ?? json['warranty']
              : null),
    );

    final rawBatches = json['batches'];
    final batches = <ProductBatch>[];
    if (rawBatches is List) {
      for (final item in rawBatches) {
        if (item is Map<String, Object?>) {
          batches.add(ProductBatch.fromJson(item));
        } else if (item is Map) {
          batches.add(ProductBatch.fromJson(Map<String, Object?>.from(item)));
        }
      }
    }

    final finalQuantity =
        kind == ProductKind.service ? 0 : (quantity < 0 ? 0 : quantity);

    // Backward compatibility: If storable product has quantity or expiry and no batches yet, auto-create initial batch!
    if (kind == ProductKind.storable &&
        batches.isEmpty &&
        (finalQuantity > 0 || parsedExpiry != null)) {
      batches.add(ProductBatch(
        batchNumber: generateNextBatchNumber(name, []),
        quantity: finalQuantity,
        expiry: parsedExpiry,
      ));
    }

    return Product(
      name: name,
      id: rawId,
      brand: brand,
      category: category,
      quantity: finalQuantity,
      unit: unit,
      expiry: parsedExpiry,
      service: parsedService,
      serviceEnd: parsedServiceEnd,
      cost: cost < 0 ? 0 : cost,
      kind: kind,
      status: status,
      barcode: barcode,
      imageUrl: imageUrl,
      storageInstructions: storageInstructions,
      additionalDetails: additionalDetails,
      batches: batches,
    );
  }
}
