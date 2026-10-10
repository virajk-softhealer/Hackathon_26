import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../app/app_theme.dart';
import '../models/product.dart';
import 'product_icon.dart';

class ProductDetailsSheet extends StatelessWidget {
  const ProductDetailsSheet({
    required this.product,
    required this.onRecordLoss,
    required this.onAddStock,
    required this.onRemove,
    required this.onRestock,
    required this.onEdit,
    required this.onRenewWarranty,
    super.key,
  });

  final Product product;
  final VoidCallback onRecordLoss;
  final VoidCallback onAddStock;
  final VoidCallback onRemove;
  final VoidCallback onRestock;
  final VoidCallback onEdit;
  final VoidCallback onRenewWarranty;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 32),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
              tooltip: tr(context, 'Cancel'),
            ),
          ],
        ),
        const SizedBox(height: 6),
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
                    '${product.brand == 'Unbranded' ? tr(context, 'Unbranded') : product.brand} · ${tr(context, product.category)}',
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
        if (product.warranty != null)
          _DetailLine(
            icon: Icons.verified_user_outlined,
            label: tr(context, 'Warranty expires'),
            value: localizedFullDate(context, product.warranty!),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onEdit();
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(tr(context, 'Edit details')),
              ),
            ),
            if (product.kind != ProductKind.service) ...[
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(context);
                    onAddStock();
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(tr(context, 'Add stock')),
                ),
              ),
            ],
          ],
        ),
        if (product.kind == ProductKind.service) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onRenewWarranty();
              },
              icon: const Icon(Icons.autorenew_rounded),
              label: Text(tr(context, 'Renew warranty')),
            ),
          ),
        ],
        if (product.kind != ProductKind.service) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onRestock();
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(tr(context, 'Restock')),
                ),
              ),
              if (product.quantity > 0) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onRecordLoss();
                    },
                    icon: const Icon(Icons.remove_shopping_cart_outlined),
                    label: Text(tr(context, 'Record loss')),
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 6),
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
