import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/app_localizations.dart';
import '../models/product.dart';
import 'product_icon.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.onTap, super.key});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isService = product.service != null;
    final hasWarranty = product.warranty != null;
    final days = product.daysToExpiry;
    final daysToWarranty = product.warranty?.difference(DateTime.now()).inDays;
    final statusColor = isService
        ? const Color(0xFF5866A8)
        : (days != null && days <= 7) ||
              (daysToWarranty != null && daysToWarranty <= 7)
        ? const Color(0xFFB56818)
        : brandGreen;
    final status = isService
        ? tr(context, 'Service in {days} days', {
            'days': product.service!.difference(DateTime.now()).inDays,
        })
        : hasWarranty
        ? tr(context, 'Warranty expires in {days} days', {
            'days': daysToWarranty,
          })
        : days == null
        ? tr(context, 'No expiry date')
        : days < 0
        ? tr(context, 'Expired')
        : days == 0
        ? tr(context, 'Expires today')
        : tr(context, 'Expires in {days} days', {'days': days});

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ProductIcon(product),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${product.brand == 'Unbranded' ? tr(context, 'Unbranded') : product.brand} · ${tr(context, product.category)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          isService || hasWarranty
                              ? Icons.verified_user_outlined
                              : Icons.schedule,
                          size: 14,
                          color: statusColor,
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!isService)
                          Text(
                            '· ${product.quantity} ${product.unit}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.more_horiz_rounded),
                tooltip: tr(context, 'Product actions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
