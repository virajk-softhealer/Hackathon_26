import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../models/product.dart';
import '../services/restock_search_service.dart';
import 'platform_logo.dart';

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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        child: SingleChildScrollView(
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
                Text(
                  tr(context, 'Restock product'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
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
                  platform: ShoppingPlatform.google,
                  title: 'Google Search',
                  subtitle: 'Search the web',
                  onTap: () => onSelectPlatform(ShoppingPlatform.google),
                ),
                _PlatformOption(
                  platform: ShoppingPlatform.amazonIndia,
                  title: 'Amazon India',
                  subtitle: 'Search product listings',
                  onTap: () => onSelectPlatform(ShoppingPlatform.amazonIndia),
                ),
                _PlatformOption(
                  platform: ShoppingPlatform.flipkart,
                  title: 'Flipkart',
                  subtitle: 'Search product listings',
                  onTap: () => onSelectPlatform(ShoppingPlatform.flipkart),
                ),
                _PlatformOption(
                  platform: ShoppingPlatform.zepto,
                  title: 'Zepto',
                  subtitle: 'Search groceries',
                  onTap: () => onSelectPlatform(ShoppingPlatform.zepto),
                ),
                _PlatformOption(
                  platform: null,
                  title: 'Copy search terms',
                  subtitle: 'Use in another shopping app',
                  onTap: onCopy,
                ),
                const SizedBox(height: 4),
                Text(
                  tr(
                    context,
                    'Search results are provided by external services. Product availability is not verified in Product Care.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatformOption extends StatelessWidget {
  const _PlatformOption({
    required this.platform,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final ShoppingPlatform? platform;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: PlatformLogo(platform),
    title: Text(tr(context, title)),
    subtitle: Text(tr(context, subtitle)),
    trailing: Icon(
      platform == null ? Icons.copy_rounded : Icons.open_in_new_rounded,
      size: 18,
      color: platform == null ? const Color(0xFF246B52) : null,
    ),
    onTap: onTap,
  );
}
