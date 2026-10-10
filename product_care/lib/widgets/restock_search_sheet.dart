import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/restock_search_service.dart';

class RestockSearchSheet extends StatelessWidget {
  const RestockSearchSheet({
    required this.product,
    required this.onSelectPlatform,
    required this.onCopy,
    super.key,
  });

  final Product product;
  final ValueChanged<ShoppingPlatform> onSelectPlatform;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final search = const RestockSearchService();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
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
            const Text(
              'Restock product',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              search.buildQuery(product),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            _PlatformOption(
              icon: Icons.search,
              title: 'Google Search',
              subtitle: 'Search the web',
              onTap: () => onSelectPlatform(ShoppingPlatform.google),
            ),
            _PlatformOption(
              icon: Icons.shopping_bag_outlined,
              title: 'Amazon India',
              subtitle: 'Search product listings',
              onTap: () => onSelectPlatform(ShoppingPlatform.amazonIndia),
            ),
            _PlatformOption(
              icon: Icons.storefront_outlined,
              title: 'Flipkart',
              subtitle: 'Search product listings',
              onTap: () => onSelectPlatform(ShoppingPlatform.flipkart),
            ),
            _PlatformOption(
              icon: Icons.local_grocery_store_outlined,
              title: 'Zepto',
              subtitle: 'Search groceries',
              onTap: () => onSelectPlatform(ShoppingPlatform.zepto),
            ),
            _PlatformOption(
              icon: Icons.copy_all_outlined,
              title: 'Copy search terms',
              subtitle: 'Use in another shopping app',
              onTap: onCopy,
            ),
            const SizedBox(height: 4),
            Text(
              'Search results are provided by external services. Product availability is not verified in Product Care.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformOption extends StatelessWidget {
  const _PlatformOption({
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
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
    onTap: onTap,
  );
}
