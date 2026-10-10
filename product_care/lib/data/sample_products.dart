import '../models/product.dart';

List<Product> createSampleProducts() => [
  Product(
    name: 'Whole milk',
    brand: 'Amul',
    category: 'Dairy',
    quantity: 2,
    unit: 'packets',
    expiry: DateTime.now().add(const Duration(days: 2)),
    cost: 32,
  ),
  Product(
    name: 'Greek yogurt',
    brand: 'Epigamia',
    category: 'Dairy',
    quantity: 3,
    unit: 'cups',
    expiry: DateTime.now().add(const Duration(days: 5)),
    cost: 45,
  ),
  Product(
    name: 'Vitamin C tablets',
    brand: 'Limcee',
    category: 'Health',
    quantity: 1,
    unit: 'bottle',
    expiry: DateTime.now().add(const Duration(days: 18)),
    cost: 120,
  ),
  Product(
    name: 'Air conditioner',
    brand: 'Daikin',
    category: 'Appliances',
    quantity: 0,
    unit: 'unit',
    service: DateTime.now().add(const Duration(days: 7)),
    kind: ProductKind.service,
  ),
  Product(
    name: 'Olive oil',
    brand: 'Figaro',
    category: 'Pantry',
    quantity: 0,
    unit: 'bottle',
    expiry: DateTime.now().add(const Duration(days: 70)),
    cost: 480,
  ),
];
