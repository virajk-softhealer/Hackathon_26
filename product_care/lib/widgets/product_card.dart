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
    final daysToExpiry = product.daysToExpiry;

    final isService = product.kind == ProductKind.service;
    final isOutOfStock = !isService && product.quantity <= 0;

    final isExpiredOrOverdue = !isOutOfStock &&
        ((daysToService != null && daysToService < 0) ||
            (daysToExpiry != null && daysToExpiry < 0));

    final isDueSoon = !isOutOfStock &&
        ((daysToService != null && daysToService <= 7) ||
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
            ? (daysToService == null
                ? tr(context, 'No service date')
                : daysToService < 0
                    ? tr(context, 'Service expired')
                    : daysToService == 0
                        ? tr(context, 'Service due today')
                        : tr(context, 'Service in {days} days', {
                            'days': daysToService,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (product.isDraft)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3D6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE5B842),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.pending_actions_rounded,
                                  size: 11,
                                  color: Color(0xFF946200),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  tr(context, 'Draft'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF7C5800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.brand.trim().isEmpty ||
                              product.brand.trim().toLowerCase() == 'unbranded'
                          ? tr(context, product.category)
                          : '${product.brand} · ${tr(context, product.category)}',
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
                              : isService
                                  ? Icons.build_outlined
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
                            product.batches.length > 1
                                ? '· ${product.quantity} ${tr(context, product.unit)} (${product.batches.where((b) => b.quantity > 0).length} ${tr(context, 'batches')})'
                                : product.batches.length == 1
                                    ? '· ${product.quantity} ${tr(context, product.unit)} (${product.batches.first.batchNumber})'
                                    : '· ${product.quantity} ${tr(context, product.unit)}',
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
