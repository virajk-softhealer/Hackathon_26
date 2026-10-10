import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
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
    final reminders = products.expand(_remindersFor).toList();
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
                      tr(context, 'Alerts'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showMessage(
                      context,
                      tr(context, 'All alerts marked as read'),
                    ),
                    child: Text(tr(context, 'Mark all read')),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                tr(context, 'Expiry and service updates for your products'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (reminders.isEmpty && losses.isEmpty)
                const EmptyStateCard(
                  title: 'You’re up to date',
                  message: 'New reminders will show here when a product needs attention.',
                  icon: Icons.notifications_active_outlined,
                )
              else ...[
                ...reminders.map(
                  (reminder) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReminderAlert(
                      reminder: reminder,
                      onTap: () => onOpenProduct(reminder.product),
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
                        title: Text(tr(context, 'Stock loss recorded')),
                        subtitle: Text(loss),
                        trailing: const Icon(Icons.done_rounded),
                      ),
                    ),
                  ),
                ),
              ],
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF246B52),
                  ),
                  title: Text(tr(context, 'Reminder scheduling')),
                  subtitle: Text(tr(context, 'Device reminders follow the shared day setting.')),
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

  List<_ReminderEntry> _remindersFor(Product product) {
    final entries = <_ReminderEntry>[];
    final maxThreshold = reminderDays.isEmpty
        ? 3
        : reminderDays.reduce((a, b) => a > b ? a : b);

    void add(String kind, DateTime? date) {
      if (date == null) return;
      final days = _daysFromToday(date);
      if (days <= maxThreshold) {
        entries.add(_ReminderEntry(product, kind, date, days));
      }
    }

    add('Service', product.service);
    add('Warranty', product.warranty);
    if (product.expiry != null &&
        (product.kind != ProductKind.storable || product.quantity > 0)) {
      add('Expiry', product.expiry);
    }
    return entries;
  }

  int _daysFromToday(DateTime date) {
    final now = DateTime.now();
    return DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ReminderEntry {
  const _ReminderEntry(this.product, this.kind, this.date, this.days);

  final Product product;
  final String kind;
  final DateTime date;
  final int days;
}

class _ReminderAlert extends StatelessWidget {
  const _ReminderAlert({required this.reminder, required this.onTap});

  final _ReminderEntry reminder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = reminder.product;
    final kind = reminder.kind;
    final isService = kind == 'Service';
    final isWarranty = kind == 'Warranty';
    final color = isService
        ? const Color(0xFF5469AA)
        : isWarranty
            ? const Color(0xFF278765)
            : const Color(0xFFB56818);
    final title = tr(context, '{type} reminder: {name}', {
      'type': tr(context, kind),
      'name': product.name,
    });
    final body = _message(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isService
                ? const Color(0xFFE7ECFA)
                : isWarranty
                    ? const Color(0xFFE5F0E9)
                    : const Color(0xFFFFEED8),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            isService
                ? Icons.build_outlined
                : isWarranty
                    ? Icons.verified_user_outlined
                    : Icons.hourglass_bottom_rounded,
            color: color,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(body),
        isThreeLine: true,
      ),
    );
  }

  String _message(BuildContext context) {
    final name = reminder.product.name;
    if (reminder.kind == 'Service') {
      return reminder.days <= 0
          ? tr(context, '{name} is due for service today.', {'name': name})
          : tr(context, '{name} needs service in {days} days.', {
              'name': name,
              'days': reminder.days,
            });
    }
    if (reminder.kind == 'Warranty') {
      return reminder.days < 0
          ? tr(context, 'Warranty for {name} has expired.', {'name': name})
          : reminder.days == 0
              ? tr(context, 'Warranty for {name} expires today.', {'name': name})
              : tr(context, 'Warranty for {name} expires in {days} days.', {
                  'name': name,
                  'days': reminder.days,
                });
    }
    return reminder.days < 0
        ? tr(context, '{name} is past its expiry date. Review the product details.', {'name': name})
        : reminder.days == 0
            ? tr(context, '{name} expires today. Review the product details.', {'name': name})
            : tr(context, '{name} expires in {days} days. Review the product details.', {
                'name': name,
                'days': reminder.days,
              });
  }
}
