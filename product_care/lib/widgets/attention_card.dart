import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../models/product.dart';

class AttentionCard extends StatelessWidget {
  const AttentionCard({required this.product, required this.onTap, super.key});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = product.expiry ?? product.service!;
    final isService = product.service != null;
    final days = date.difference(DateTime.now()).inDays;
    final accent = isService
        ? const Color(0xFF5469AA)
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
                      : const Color(0xFFFFEED8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isService ? Icons.build_outlined : Icons.schedule_rounded,
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
                          ? '${tr(context, isService ? 'Service' : 'Expiry')} · ${tr(context, 'Today')}'
                          : tr(context, '{type} · {days} days left', {
                              'type': tr(
                                context,
                                isService ? 'Service' : 'Expiry',
                              ),
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
