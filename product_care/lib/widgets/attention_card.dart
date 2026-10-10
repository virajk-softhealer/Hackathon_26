import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../models/product.dart';

class AttentionCard extends StatelessWidget {
  const AttentionCard({required this.product, required this.onTap, super.key});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final events = <(String, DateTime)>[
      if (product.expiry != null) ('Expiry', product.expiry!),
      if (product.service != null) ('Service', product.service!),
      if (product.warranty != null) ('Warranty', product.warranty!),
    ]..sort((left, right) => left.$2.compareTo(right.$2));

    if (events.isEmpty) {
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEED8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFFB56818),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tr(context, 'Out of stock · 0 {unit}', {
                          'unit': product.unit,
                        }),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  tr(context, 'Restock'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFFB56818),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final eventType = events.first.$1;
    final date = events.first.$2;
    final isService = eventType == 'Service';
    final isWarranty = eventType == 'Warranty';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final days = targetDay.difference(today).inDays;

    final accent = days < 0
        ? const Color(0xFFBA1A1A)
        : isService
            ? const Color(0xFF5469AA)
            : isWarranty
                ? const Color(0xFF278765)
                : const Color(0xFFB56818);

    final statusText = days < 0
        ? '${tr(context, eventType)} · ${tr(context, isService ? 'Service expired' : 'Expired')}'
        : days == 0
            ? '${tr(context, eventType)} · ${tr(context, 'Due today')}'
            : tr(context, '{type} · {days} days left', {
                'type': tr(context, eventType),
                'days': days,
              });

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: days < 0
                      ? const Color(0xFFFFDAD6)
                      : isService
                          ? const Color(0xFFE7ECFA)
                          : isWarranty
                              ? const Color(0xFFE5F0E9)
                              : const Color(0xFFFFEED8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isService
                      ? Icons.build_outlined
                      : isWarranty
                          ? Icons.verified_user_outlined
                          : Icons.schedule_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: days < 0
                            ? const Color(0xFFBA1A1A)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: days < 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                localizedShortDate(context, date),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: days < 0 ? const Color(0xFFBA1A1A) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
