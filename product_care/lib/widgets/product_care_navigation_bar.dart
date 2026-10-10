import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../app/app_theme.dart';

class ProductCareNavigationBar extends StatelessWidget {
  const ProductCareNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.grid_view_rounded, 'Home', Color(0xFF278765)),
    (Icons.inventory_2_rounded, 'Products', Color(0xFF3E7BDB)),
    (Icons.calendar_month_rounded, 'Calendar', Color(0xFF8B61CC)),
    (Icons.notifications_rounded, 'Alerts', Color(0xFFE28A37)),
    (Icons.tune_rounded, 'Settings', Color(0xFFDF6482)),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(14, 7, 14, 9),
      padding: const EdgeInsets.fromLTRB(5, 8, 5, 7),
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
          for (var index = 0; index < _items.length; index++)
            Expanded(child: _destination(context, index)),
        ],
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
