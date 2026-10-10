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
    final eventType = events.first.$1;
    final date = events.first.$2;
    final isService = eventType == 'Service';
    final isWarranty = eventType == 'Warranty';
    final days = date.difference(DateTime.now()).inDays;
    final accent = isService
        ? const Color(0xFF5469AA)
        : isWarranty
            ? const Color(0xFF278765)
            : const Color(0xFFB56818);
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
                  color: isService
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
                      days <= 0
                          ? '${tr(context, eventType)} · ${tr(context, 'Today')}'
                          : tr(context, '{type} · {days} days left', {
                              'type': tr(context, eventType),
                              'days': days,
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
                localizedShortDate(context, date),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
