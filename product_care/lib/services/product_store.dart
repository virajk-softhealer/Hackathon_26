import '../data/sample_products.dart';
import '../models/product.dart';
import '../utils/date_formatters.dart';

/// Session-only product actions. Replace this with a database repository
/// when local persistence is added.
class ProductStore {
  ProductStore() : products = createSampleProducts();

  final List<Product> products;
  final List<String> losses = [];

  int get expiringSoon => products
      .where(
        (product) =>
            product.daysToExpiry != null &&
            product.daysToExpiry! >= 0 &&
            product.daysToExpiry! <= 7 &&
            product.quantity > 0,
      )
      .length;

  int get lowStock => products.where((product) => product.quantity <= 1).length;

  int get totalUnits =>
      products.fold(0, (total, product) => total + product.quantity);

  void addProduct(Product product) => products.add(product);

  bool recordLoss(Product product, int quantity) {
    if (quantity < 1 || quantity > product.quantity) return false;
    product.quantity -= quantity;
    losses.add(
      '${product.name} · $quantity ${product.unit} · ${formatShortDate(DateTime.now())}',
    );
    return true;
  }
}
