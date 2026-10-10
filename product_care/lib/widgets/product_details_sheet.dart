import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../app/app_theme.dart';
import '../models/product.dart';
import 'product_icon.dart';

class ProductDetailsSheet extends StatelessWidget {
  const ProductDetailsSheet({
    required this.product,
    required this.onRecordLoss,
    required this.onRemove,
    required this.onRestock,
    super.key,
  });

  final Product product;
  final VoidCallback onRecordLoss;
  final VoidCallback onRemove;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            ProductIcon(product),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${product.brand} · ${tr(context, product.category)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (product.kind != ProductKind.service)
          _DetailLine(
            icon: Icons.inventory_2_outlined,
            label: tr(context, 'Available stock'),
            value: '${product.quantity} ${product.unit}',
          ),
        if (product.expiry != null)
          _DetailLine(
            icon: Icons.event_outlined,
            label: tr(context, 'Best before'),
            value: localizedFullDate(context, product.expiry!),
          ),
        if (product.service != null)
          _DetailLine(
            icon: Icons.build_outlined,
            label: tr(context, 'Next service'),
            value: localizedFullDate(context, product.service!),
          ),
        if (product.kind != ProductKind.service &&
            (product.quantity == 0 ||
                (product.daysToExpiry != null &&
                    product.daysToExpiry! < 0))) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onRestock();
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(tr(context, 'Restock product')),
            ),
          ),
        ],
        if (product.kind != ProductKind.service && product.quantity > 0) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onRecordLoss();
              },
              icon: const Icon(Icons.remove_shopping_cart_outlined),
              label: Text(tr(context, 'Record stock loss')),
            ),
          ),
        ],
        const SizedBox(height: 5),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            icon: const Icon(Icons.delete_outline),
            label: Text(tr(context, 'Remove product')),
          ),
        ),
      ],
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, size: 18, color: brandGreen),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
