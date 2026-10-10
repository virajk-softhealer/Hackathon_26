import 'package:flutter/material.dart';

import '../models/product.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/product_card.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    required this.products,
    required this.onOpenProduct,
    this.initialFilter = 'All',
    super.key,
  });

  final List<Product> products;
  final ValueChanged<Product> onOpenProduct;
  final String initialFilter;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _filter = 'All';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Expiring', 'In stock', 'Low stock', 'Service'];
    final shown = widget.products.where((product) {
      final matchesQuery =
          '${product.name} ${product.brand} ${product.category}'
              .toLowerCase()
              .contains(_query.toLowerCase());
      final matchesFilter = switch (_filter) {
        'Expiring' =>
          product.kind == ProductKind.storable &&
              product.quantity > 0 &&
              product.daysToExpiry != null &&
              product.daysToExpiry! >= 0 &&
              product.daysToExpiry! <= 7,
        'Low stock' =>
          product.kind != ProductKind.service && product.quantity <= 1,
        'In stock' =>
          product.kind != ProductKind.service && product.quantity > 0,
        'Service' => product.service != null,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          sliver: SliverList.list(
            children: [
              Text(
                'Products',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                '${widget.products.length} items in your home',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search products',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories
                      .map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: _filter == category,
                            onSelected: (_) =>
                                setState(() => _filter = category),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (shown.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: EmptyStateCard(
                title: 'No matching products',
                message: 'Try another search or add a product.',
                icon: Icons.search_off_rounded,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList.separated(
              itemCount: shown.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => ProductCard(
                product: shown[index],
                onTap: () => widget.onOpenProduct(shown[index]),
              ),
            ),
          ),
      ],
    );
  }
}
