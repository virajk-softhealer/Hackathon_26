import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../app/app_theme.dart';

class ProductCareNavigationBar extends StatelessWidget {
  const ProductCareNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
    this.onScan,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onScan;

  static const _items = [
    (Icons.grid_view_rounded, 'Home', Color(0xFF278765)),
    (Icons.inventory_2_rounded, 'Products', Color(0xFF3E7BDB)),
    (Icons.notifications_rounded, 'Alerts', Color(0xFFE28A37)),
    (Icons.tune_rounded, 'Settings', Color(0xFFDF6482)),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      padding: const EdgeInsets.fromLTRB(4, 7, 4, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant
              .withValues(alpha: .45),
        ),
        boxShadow: [
          BoxShadow(
            color: brandInk.withValues(alpha: .09),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _destination(context, 0)),
          Expanded(child: _destination(context, 1)),
          if (onScan != null) Expanded(child: _scanAction(context)),
          Expanded(child: _destination(context, 2)),
          Expanded(child: _destination(context, 3)),
        ],
      ),
    ),
  );

  Widget _scanAction(BuildContext context) => Semantics(
    button: true,
    label: tr(context, 'Scan item'),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onScan,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: brandGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: brandGreen.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tr(context, 'Scan'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: brandGreen,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _destination(BuildContext context, int index) {
    final item = _items[index];
    final selected = selectedIndex == index;
    return Semantics(
      button: true,
      selected: selected,
      label: tr(context, item.$2),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? 42 : 38,
                height: selected ? 42 : 38,
                decoration: BoxDecoration(
                  color: selected ? item.$3 : item.$3.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.$1,
                  size: 20,
                  color: selected ? Colors.white : item.$3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tr(context, item.$2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? item.$3
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
