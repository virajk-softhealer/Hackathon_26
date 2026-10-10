enum ProductKind { expiry, service, general }

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
    this.kind = ProductKind.expiry,
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
}
