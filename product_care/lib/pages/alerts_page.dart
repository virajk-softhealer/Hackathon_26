import 'package:flutter/material.dart';

import '../models/product.dart';
import '../widgets/empty_state_card.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({
    required this.products,
    required this.losses,
    required this.reminderDays,
    required this.onOpenProduct,
    super.key,
  });

  final List<Product> products;
  final List<String> losses;
  final Set<int> reminderDays;
  final ValueChanged<Product> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final alerts = products.where(_isReminderDue).toList();
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
              if (alerts.isEmpty && losses.isEmpty)
                const EmptyStateCard(
                  title: 'You’re up to date',
                  message: 'New reminders will show here when a product needs attention.',
                  icon: Icons.notifications_active_outlined,
                )
              else ...[
                ...alerts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReminderAlert(
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

  bool _isReminderDue(Product product) {
    final serviceDate = product.service;
    if (serviceDate != null) {
      final days = _daysFromToday(serviceDate);
      return days <= 0 || reminderDays.contains(days);
    }
    final days = product.daysToExpiry;
    if (product.kind != ProductKind.storable ||
        product.quantity <= 0 ||
        days == null) {
      return false;
    }
    return days <= 0 || reminderDays.contains(days);
  }

  int _daysFromToday(DateTime date) {
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ReminderAlert extends StatelessWidget {
  const _ReminderAlert({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isService = product.service != null;
    final days = isService
        ? _daysFromToday(product.service!)
        : product.daysToExpiry!;
    final title = isService
        ? 'Service reminder: ${product.name}'
        : 'Expiry reminder: ${product.name}';
    final message = isService
        ? '${product.name} ${days <= 0 ? 'is due for service' : 'requires servicing in $days days'}. Review the product details.'
        : '${product.name} ${days < 0
              ? 'is past its expiry date'
              : days == 0
              ? 'expires today'
              : 'expires in $days days'}. Review the product details.';
    final iconColor = isService
        ? const Color(0xFF5469AA)
        : const Color(0xFFB56818);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isService
                ? const Color(0xFFE7ECFA)
                : const Color(0xFFFFEED8),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            isService ? Icons.build_outlined : Icons.hourglass_bottom_rounded,
            color: iconColor,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(message),
        isThreeLine: true,
      ),
    );
  }
}

int _daysFromToday(DateTime date) {
  final now = DateTime.now();
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
}
