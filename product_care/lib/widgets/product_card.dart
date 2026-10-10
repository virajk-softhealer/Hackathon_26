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
    final daysToService = product.daysToService;
    final daysToWarranty = product.daysToWarranty;
    final daysToExpiry = product.daysToExpiry;

    final isService = daysToService != null;
    final hasWarranty = daysToWarranty != null;

    final isOutOfStock = product.kind != ProductKind.service && product.quantity <= 0;

    final isExpiredOrOverdue = !isOutOfStock &&
        ((daysToService != null && daysToService < 0) ||
        (daysToWarranty != null && daysToWarranty < 0) ||
        (daysToExpiry != null && daysToExpiry < 0));

    final isDueSoon = !isOutOfStock &&
        ((daysToService != null && daysToService <= 7) ||
        (daysToWarranty != null && daysToWarranty <= 7) ||
        (daysToExpiry != null && daysToExpiry <= 7));

    final statusColor = isOutOfStock
        ? const Color(0xFFB56818)
        : isExpiredOrOverdue
            ? const Color(0xFFBA1A1A)
            : isDueSoon
                ? const Color(0xFFB56818)
                : isService
                    ? const Color(0xFF5866A8)
                    : brandGreen;

    final status = isOutOfStock
        ? tr(context, 'Out of stock')
        : isService
            ? (daysToService < 0
                ? tr(context, 'Service expired')
                : daysToService == 0
                    ? tr(context, 'Service due today')
                    : tr(context, 'Service in {days} days', {'days': daysToService}))
            : hasWarranty
                ? (daysToWarranty < 0
                    ? tr(context, 'Warranty expired')
                    : daysToWarranty == 0
                        ? tr(context, 'Warranty expires today')
                        : tr(context, 'Warranty expires in {days} days', {
                            'days': daysToWarranty,
                          }))
                : daysToExpiry == null
                    ? tr(context, 'No expiry date')
                    : daysToExpiry < 0
                        ? tr(context, 'Expired')
                        : daysToExpiry == 0
                            ? tr(context, 'Expires today')
                            : tr(context, 'Expires in {days} days', {
                                'days': daysToExpiry,
                              });

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
                          isOutOfStock
                              ? Icons.inventory_2_outlined
                              : isService || hasWarranty
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
                        if (!isService && !isOutOfStock)
                          Text(
                            '· ${product.quantity} ${tr(context, product.unit)}',
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
