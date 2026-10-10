import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product.dart';

enum ShoppingPlatform { google, amazonIndia, flipkart, zepto }

class RestockSearchService {
  const RestockSearchService();

  String buildQuery(Product product) {
    final cleanBrand = product.brand.trim();
    final hasBrand = cleanBrand.isNotEmpty &&
        cleanBrand.toLowerCase() != 'unbranded';
    final parts = <String>[
      product.name,
      if (hasBrand) cleanBrand,
    ].where((part) => part.trim().isNotEmpty);
    final seen = <String>{};
    return parts
        .expand((part) => part.trim().split(RegExp(r'\s+')))
        .where((word) => seen.add(word.toLowerCase()))
        .join(' ');
  }

  Uri buildUri(ShoppingPlatform platform, Product product) {
    final query = buildQuery(product);
    if (query.isEmpty) throw ArgumentError('Product search terms are empty.');
    return switch (platform) {
      ShoppingPlatform.google => Uri.https('www.google.com', '/search', {
        'q': query,
      }),
      ShoppingPlatform.amazonIndia => Uri.https('www.amazon.in', '/s', {
        'k': query,
      }),
      ShoppingPlatform.flipkart => Uri.https('www.flipkart.com', '/search', {
        'q': query,
      }),
      ShoppingPlatform.zepto => Uri.https('www.zepto.com', '/search', {
        'm': '',
        'query': query,
      }),
    };
  }

  Future<bool> open(ShoppingPlatform platform, Product product) async {
    try {
      final uri = buildUri(platform, product);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }

  Future<void> copyQuery(Product product) async {
    await Clipboard.setData(ClipboardData(text: buildQuery(product)));
  }
}
