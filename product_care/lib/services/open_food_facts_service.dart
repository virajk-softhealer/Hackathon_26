import 'dart:convert';
import 'dart:io';

class OpenFoodFactsResult {
  const OpenFoodFactsResult({
    required this.barcode,
    required this.found,
    this.name,
    this.brand,
    this.category,
    this.quantityText,
    this.imageUrl,
    this.storageInstructions,
    this.additionalDetails = const {},
  });

  final String barcode;
  final bool found;
  final String? name;
  final String? brand;
  final String? category;
  final String? quantityText;
  final String? imageUrl;
  final String? storageInstructions;
  final Map<String, String> additionalDetails;
}

class OpenFoodFactsService {
  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 6);

  static Future<OpenFoodFactsResult> lookupBarcode(String barcode) async {
    final cleanCode = barcode.trim();
    if (cleanCode.isEmpty) {
      return OpenFoodFactsResult(barcode: barcode, found: false);
    }

    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$cleanCode.json',
      );
      final request = await _client.getUrl(uri);
      request.headers.set('User-Agent', 'ProductCareApp/1.0 (flutter-offline-first)');
      request.headers.set('Accept', 'application/json');

      final response = await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return OpenFoodFactsResult(barcode: cleanCode, found: false);
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = jsonDecode(responseBody) as Map<String, dynamic>;

      final status = data['status'];
      if (status != 1 && status != '1') {
        return OpenFoodFactsResult(barcode: cleanCode, found: false);
      }

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) {
        return OpenFoodFactsResult(barcode: cleanCode, found: false);
      }

      final name = (product['product_name'] ??
              product['product_name_en'] ??
              product['generic_name'])
          ?.toString()
          .trim();

      final brand = (product['brands'] ?? product['brand_owner'])
          ?.toString()
          .trim()
          .split(',')
          .first
          .trim();

      var category = 'Food & Drinks';
      final rawCategories = product['categories']?.toString();
      if (rawCategories != null && rawCategories.isNotEmpty) {
        final firstCategory = rawCategories.split(',').first.trim();
        if (firstCategory.isNotEmpty) {
          category = firstCategory;
        }
      }

      final quantity = product['quantity']?.toString().trim();
      final imageUrl = (product['image_front_small_url'] ??
              product['image_url'] ??
              product['image_front_url'])
          ?.toString();

      final storage = product['conservation_conditions']?.toString().trim();

      final details = <String, String>{};
      final nutriScore = product['nutriscore_grade']?.toString().toUpperCase();
      if (nutriScore != null && nutriScore.isNotEmpty && nutriScore != 'UNKNOWN') {
        details['Nutri-Score'] = 'Grade $nutriScore';
      }

      final allergens = (product['allergens_from_ingredients'] ?? product['allergens'])
          ?.toString()
          .trim();
      if (allergens != null && allergens.isNotEmpty) {
        details['Allergens'] = allergens;
      }

      final ingredients = product['ingredients_text']?.toString().trim();
      if (ingredients != null && ingredients.isNotEmpty) {
        details['Ingredients'] = ingredients;
      }

      final packaging = (product['packaging_text'] ?? product['packaging'])?.toString().trim();
      if (packaging != null && packaging.isNotEmpty) {
        details['Packaging'] = packaging;
      }

      final origin = (product['origins'] ?? product['countries'])?.toString().trim();
      if (origin != null && origin.isNotEmpty) {
        details['Origin'] = origin;
      }

      return OpenFoodFactsResult(
        barcode: cleanCode,
        found: name != null && name.isNotEmpty,
        name: name,
        brand: brand,
        category: category,
        quantityText: quantity,
        imageUrl: imageUrl,
        storageInstructions: storage != null && storage.isNotEmpty ? storage : null,
        additionalDetails: details,
      );
    } catch (_) {
      // Offline or network error - gracefully return not found
      return OpenFoodFactsResult(barcode: cleanCode, found: false);
    }
  }
}
