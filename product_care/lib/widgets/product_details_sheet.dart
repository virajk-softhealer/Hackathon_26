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
    this.onConfirm,
    this.onUpdateBatchExpiry,
    this.onUpdateProductExpiry,
    super.key,
  });

  final Product product;
  final VoidCallback onRecordLoss;
  final VoidCallback onAddStock;
  final VoidCallback onRemove;
  final VoidCallback onRestock;
  final VoidCallback onEdit;
  final VoidCallback? onConfirm;
  final void Function(ProductBatch batch, DateTime newExpiry)? onUpdateBatchExpiry;
  final void Function(DateTime newExpiry)? onUpdateProductExpiry;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
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
                  if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                    ProductIcon(product),
                      ),
                    )
                  else
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
                          product.brand.trim().isEmpty ||
                                  product.brand.trim().toLowerCase() == 'unbranded'
                              ? tr(context, product.category)
                              : '${product.brand} · ${tr(context, product.category)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (product.isDraft) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5B842)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.pending_actions_rounded,
                            color: Color(0xFF946200),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr(context, 'Draft Product · Verification Required'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF5E3F00),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr(
                          context,
                          'Scanned via barcode. Verify details, set expiry if needed, and confirm to activate reminders.',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C5800),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: brandGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            onConfirm?.call();
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(
                            tr(context, 'Verify & Confirm Product'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (product.kind != ProductKind.service)
                _DetailLine(
                  icon: Icons.inventory_2_outlined,
                  label: tr(context, 'Available stock'),
                  value: product.quantity <= 0
                      ? tr(context, 'Out of stock')
                      : '${product.quantity} ${tr(context, product.unit)}',
                ),
              if (product.kind != ProductKind.service &&
                  product.quantity > 0 &&
                  product.expiry != null)
                _DetailLine(
                  icon: Icons.event_outlined,
                  label: tr(context, 'Expiry date'),
                  value: localizedFullDate(context, product.expiry!),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.edit_calendar_rounded,
                      size: 18,
                      color: brandGreen,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: tr(context, 'Change expiry date'),
                    onPressed: () async {
                      final chosen = await showDatePicker(
                        context: context,
                        initialDate: product.expiry ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime(2000),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (chosen != null) {
                        onUpdateProductExpiry?.call(chosen);
                      }
                    },
                  ),
                  onTap: () async {
                    final chosen = await showDatePicker(
                      context: context,
                      initialDate: product.expiry ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (chosen != null) {
                      onUpdateProductExpiry?.call(chosen);
                    }
                  },
                ),
              if (product.barcode != null && product.barcode!.isNotEmpty)
                _DetailLine(
                  icon: Icons.qr_code_2_rounded,
                  label: tr(context, 'Barcode'),
                  value: product.barcode!,
                ),
              if (product.storageInstructions != null &&
                  product.storageInstructions!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5EF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBCE3CD)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.ac_unit_rounded,
                          size: 18, color: brandGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(context, 'Storage instructions'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.storageInstructions!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (product.kind == ProductKind.service &&
                  product.serviceStartDate != null)
                _DetailLine(
                  icon: Icons.calendar_today_outlined,
                  label: tr(context, 'Service start'),
                  value: localizedFullDate(context, product.serviceStartDate!),
                ),
              if (product.kind == ProductKind.service &&
                  product.serviceEndDate != null)
                _DetailLine(
                  icon: Icons.event_available_outlined,
                  label: tr(context, 'Service end'),
                  value: localizedFullDate(context, product.serviceEndDate!),
                ),
              if (product.kind == ProductKind.storable &&
                  product.batches.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      tr(context, 'Batches'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${tr(context, 'tap date to change')})',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...product.batches.map((batch) {
                  final days = batch.daysToExpiry;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: .5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: brandGreen.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            batch.batchNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: brandGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${batch.quantity} ${tr(context, product.unit)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final chosen = await showDatePicker(
                              context: context,
                              initialDate: batch.expiry ??
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 3650)),
                            );
                            if (chosen != null) {
                              onUpdateBatchExpiry?.call(batch, chosen);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (batch.expiry != null)
                                  Text(
                                    days != null && days < 0
                                        ? tr(context, 'Expired')
                                        : localizedFullDate(
                                            context,
                                            batch.expiry!,
                                          ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: days != null && days <= 3
                                          ? const Color(0xFFC04434)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  )
                                else
                                  Text(
                                    tr(context, 'Set expiry'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: brandGreen,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 15,
                                  color: brandGreen,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (product.additionalDetails.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: .4),
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      leading: const Icon(Icons.list_alt_rounded,
                          size: 20, color: brandGreen),
                      title: Text(
                        tr(
                          context,
                          'Additional details ({count})',
                          {'count': product.additionalDetails.length},
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      children: [
                        ...product.additionalDetails.entries.map(
                          (entry) => _DetailLine(
                            icon: Icons.check_circle_outline,
                            label: tr(context, entry.key),
                            value: entry.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
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
                      onEdit();
                    },
                    icon: const Icon(Icons.autorenew_rounded),
                    label: Text(tr(context, 'Renew service')),
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
        ),
      ),
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: brandGreen),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ),
    ),
  );
}
