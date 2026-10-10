enum ProductKind { storable, service, general }

class Product {
  Product({
    required this.name,
    required this.brand,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expiry,
    this.service,
    this.cost = 0,
    this.kind = ProductKind.storable,
  });

  final String name;
  final String brand;
  final String category;
  int quantity;
  final String unit;
  final DateTime? expiry;
  final DateTime? service;
  final double cost;
  final ProductKind kind;

  int? get daysToExpiry {
    if (expiry == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry!.year, expiry!.month, expiry!.day);
    return expiryDay.difference(today).inDays;
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'brand': brand,
    'category': category,
    'quantity': quantity,
    'unit': unit,
    'expiry': expiry?.toIso8601String(),
    'service': service?.toIso8601String(),
    'cost': cost,
    'kind': kind.name,
  };

  factory Product.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final brand = json['brand'];
    final category = json['category'];
    final unit = json['unit'];
    final rawQuantity = json['quantity'];
    final rawKind = json['kind'];
    if (name is! String ||
        name.trim().isEmpty ||
        brand is! String ||
        category is! String ||
        unit is! String ||
        rawQuantity is! int ||
        rawQuantity < 0 ||
        rawKind is! String) {
      throw const FormatException('A product record is missing valid fields.');
    }
    final kind = ProductKind.values.where((value) => value.name == rawKind);
    if (kind.isEmpty) throw const FormatException('Unknown product type.');

    DateTime? parseDate(Object? value) {
      if (value == null) return null;
      if (value is! String) {
        throw const FormatException('Invalid product date.');
      }
      final parsed = DateTime.tryParse(value);
      if (parsed == null) throw const FormatException('Invalid product date.');
      return parsed;
    }

    final rawCost = json['cost'];
    final cost = rawCost is num ? rawCost.toDouble() : 0.0;
    return Product(
      name: name.trim(),
      brand: brand,
      category: category,
      quantity: kind.first == ProductKind.service ? 0 : rawQuantity,
      unit: unit,
      expiry: parseDate(json['expiry']),
      service: parseDate(json['service']),
      cost: cost < 0 ? 0 : cost,
      kind: kind.first,
    );
  }
}
