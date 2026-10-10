import 'package:flutter/material.dart';

import '../models/product.dart';
import '../widgets/empty_state_card.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({
    required this.products,
    required this.losses,
    required this.onOpenProduct,
    super.key,
  });

  final List<Product> products;
  final List<String> losses;
  final ValueChanged<Product> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final expiryAlerts = products
        .where(
          (product) =>
              product.daysToExpiry != null && product.daysToExpiry! <= 7,
        )
        .toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Alerts',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        _showMessage(context, 'All alerts marked as read'),
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Expiry and service updates for your products',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (expiryAlerts.isEmpty && losses.isEmpty)
                const EmptyStateCard(
                  title: 'You’re up to date',
                  message: 'New reminders will show here when a product needs attention.',
                  icon: Icons.notifications_active_outlined,
                )
              else ...[
                ...expiryAlerts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExpiryAlert(
                      product: product,
                      onTap: () => onOpenProduct(product),
                    ),
                  ),
                ),
                ...losses.reversed.map(
                  (loss) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF246B52),
                        ),
                        title: const Text('Stock loss recorded'),
                        subtitle: Text(loss),
                        trailing: const Icon(Icons.done_rounded),
                      ),
                    ),
                  ),
                ),
              ],
              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF246B52),
                  ),
                  title: Text('Reminder scheduling'),
                  subtitle: Text(
                    'Local notification delivery is not configured yet.',
                  ),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ExpiryAlert extends StatelessWidget {
  const _ExpiryAlert({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEED8),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(
          Icons.hourglass_bottom_rounded,
          color: Color(0xFFB56818),
        ),
      ),
      title: Text(
        'Expiry reminder: ${product.name}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        '${product.name} expires ${product.daysToExpiry == 0 ? 'today' : 'in ${product.daysToExpiry} days'}. Review the product details.',
      ),
      isThreeLine: true,
    ),
  );
}
