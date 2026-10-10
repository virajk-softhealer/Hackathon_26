import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../app/app_theme.dart';
import '../models/product.dart';
import '../utils/date_formatters.dart';
import '../widgets/attention_card.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/section_heading.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({
    required this.products,
    required this.onOpenProduct,
    super.key,
  });

  final List<Product> products;
  final ValueChanged<Product> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final events =
        products
            .where(
              (product) =>
                  product.expiry != null ||
                  product.serviceStartDate != null ||
                  product.serviceEndDate != null,
            )
            .toList()
          ..sort((a, b) {
            final dateA = _nextDate(a);
            final dateB = _nextDate(b);
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateA.compareTo(dateB);
          });
    final now = DateTime.now();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList.list(
            children: [
              Text(
                tr(context, 'Calendar'),
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                tr(context, 'Expiry dates and service reminders'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F0E9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tr(context, monthName(now)),
                              style: const TextStyle(
                                color: brandGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${now.day}',
                              style: const TextStyle(
                                color: brandGreen,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(context, 'This month'),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(tr(context, 'Keep an eye on upcoming dates')),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: brandGreen,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeading('Upcoming dates'),
              const SizedBox(height: 12),
              if (events.isEmpty)
                const EmptyStateCard(
                  title: 'Nothing scheduled',
                  message: 'Expiry and service dates will appear here.',
                  icon: Icons.event_available_outlined,
                )
              else
                ...events.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AttentionCard(
                      product: product,
                      onTap: () => onOpenProduct(product),
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  DateTime? _nextDate(Product product) {
    final dates = [
      product.expiry,
      product.serviceStartDate,
      product.serviceEndDate,
    ].whereType<DateTime>().toList()
      ..sort();
    return dates.isEmpty ? null : dates.first;
  }
}
