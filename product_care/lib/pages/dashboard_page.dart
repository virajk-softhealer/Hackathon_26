import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/product.dart';
import '../widgets/attention_card.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/section_heading.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.products,
    required this.expiringCount,
    required this.lowStockCount,
    required this.totalUnits,
    required this.onOpenProducts,
    required this.onOpenExpiring,
    required this.onOpenInStock,
    required this.onOpenLowStock,
    required this.onOpenCalendar,
    required this.onOpenAlerts,
    required this.onOpenProduct,
    required this.onAddProduct,
    required this.onScan,
    super.key,
  });

  final List<Product> products;
  final int expiringCount;
  final int lowStockCount;
  final int totalUnits;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenExpiring;
  final VoidCallback onOpenInStock;
  final VoidCallback onOpenLowStock;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenAlerts;
  final ValueChanged<Product> onOpenProduct;
  final VoidCallback onAddProduct;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final attention = products.where((product) {
      final expiryNeedsAttention =
          product.kind == ProductKind.storable &&
          product.quantity > 0 &&
          product.daysToExpiry != null &&
          product.daysToExpiry! <= 7;
      final serviceNeedsAttention =
          product.service != null &&
          product.service!.difference(DateTime.now()).inDays <= 14;
      return expiryNeedsAttention ||
          serviceNeedsAttention ||
          (product.kind != ProductKind.service && product.quantity == 0);
    }).toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          sliver: SliverList.list(
            children: [
              _topBar(context),
              const SizedBox(height: 22),
              _heroCard(),
              const SizedBox(height: 24),
              SectionHeading(
                'Your overview',
                actionLabel: 'View all',
                onAction: onOpenProducts,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricCard(
                        label: 'Products',
                        value: '${products.length}',
                        icon: Icons.inventory_2_outlined,
                        width: width,
                        onTap: onOpenProducts,
                      ),
                      _MetricCard(
                        label: 'Expiring soon',
                        value: '$expiringCount',
                        icon: Icons.hourglass_bottom_rounded,
                        width: width,
                        tint: const Color(0xFFFFEED8),
                        accent: const Color(0xFFB56818),
                        onTap: onOpenExpiring,
                      ),
                      _MetricCard(
                        label: 'Available stock',
                        value: '$totalUnits',
                        icon: Icons.widgets_outlined,
                        width: width,
                        tint: const Color(0xFFE7ECFA),
                        accent: const Color(0xFF5469AA),
                        subtitle: 'units in total',
                        onTap: onOpenInStock,
                      ),
                      _MetricCard(
                        label: 'Needs attention',
                        value: '$lowStockCount',
                        icon: Icons.priority_high_rounded,
                        width: width,
                        tint: const Color(0xFFF9E5E1),
                        accent: const Color(0xFFB74A3C),
                        subtitle: 'low or out of stock',
                        onTap: onOpenLowStock,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 25),
              const SectionHeading('Quick actions'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_box_outlined,
                      title: 'Add product',
                      subtitle: 'Enter details',
                      onTap: onAddProduct,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan item',
                      subtitle: 'Camera scan',
                      onTap: onScan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SectionHeading(
                'Coming up',
                actionLabel: 'Calendar',
                onAction: onOpenCalendar,
              ),
              const SizedBox(height: 12),
              if (attention.isEmpty)
                const EmptyStateCard(
                  title: 'All clear for now',
                  message: 'Your products and schedules are up to date.',
                  icon: Icons.check_circle_outline,
                )
              else
                ...attention
                    .take(3)
                    .map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AttentionCard(
                          product: product,
                          onTap: () => onOpenProduct(product),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Product Care',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: onOpenAlerts,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            if (expiringCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE27B46),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            'assets/branding/product_care_icon.png',
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _heroCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xFF286E54), Color(0xFF184B3B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A little care goes a long way',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expiringCount == 0
                        ? 'You’re all caught up.'
                        : '$expiringCount ${expiringCount == 1 ? 'item needs' : 'items need'} a little attention',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa_outlined, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: brandGreen,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          ),
          onPressed: onOpenProducts,
          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          label: const Text(
            'Review products',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.width,
    required this.onTap,
    this.subtitle,
    this.tint = const Color(0xFFE5F0E9),
    this.accent = brandGreen,
  });

  final String label;
  final String value;
  final IconData icon;
  final double width;
  final VoidCallback onTap;
  final String? subtitle;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: accent, size: 19),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F0E9),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: brandGreen),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
