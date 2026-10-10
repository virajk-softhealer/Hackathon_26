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
    this.parsedQuantity,
    this.parsedUnit,
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
  final int? parsedQuantity;
  final String? parsedUnit;
  final String? imageUrl;
  final String? storageInstructions;
  final Map<String, String> additionalDetails;
}

class OpenFoodFactsService {
  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 6);

  static Future<bool> hasInternetConnection() async {
    try {
      final lookup = await InternetAddress.lookup('openfoodfacts.org')
          .timeout(const Duration(seconds: 3));
      if (lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      try {
        final lookup2 = await InternetAddress.lookup('dns.google')
            .timeout(const Duration(seconds: 2));
        return lookup2.isNotEmpty && lookup2.first.rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  static (int quantity, String unit) parseQuantityAndUnit(String? rawQuantity) {
    if (rawQuantity == null || rawQuantity.trim().isEmpty) {
      return (1, 'units');
    }
    final text = rawQuantity.trim();

    // Multipack format like "6 x 330 ml" or "2 x 100 g"
    final multiMatch =
        RegExp(r'^(\d+)\s*[xX*]\s*(\d+(?:\.\d+)?)\s*([a-zA-Z%]+)')
            .firstMatch(text);
    if (multiMatch != null) {
      final count = int.tryParse(multiMatch.group(1)!) ?? 1;
      final perItem = double.tryParse(multiMatch.group(2)!) ?? 1.0;
      final unitRaw = multiMatch.group(3)!.toLowerCase();
      final total = (count * perItem).round();
      final normalizedUnit = _normalizeUnit(unitRaw);
      return (total > 0 ? total : 1, normalizedUnit);
    }

    // Single item format like "48 g", "48g", "500 ml", "1.5 kg", "250gm"
    final singleMatch =
        RegExp(r'^(\d+(?:\.\d+)?)\s*([a-zA-Z%]+)?').firstMatch(text);
    if (singleMatch != null) {
      final amount = double.tryParse(singleMatch.group(1)!) ?? 1.0;
      final unitRaw = singleMatch.group(2)?.toLowerCase() ?? 'units';

      // Decimal kg or liters: e.g. 1.5 kg -> 1500 g
      if ((unitRaw == 'kg' || unitRaw == 'kilogram' || unitRaw == 'kilograms') &&
          amount < 10 &&
          amount != amount.roundToDouble()) {
        final grams = (amount * 1000).round();
        return (grams, 'g');
      } else if ((unitRaw == 'l' ||
              unitRaw == 'liter' ||
              unitRaw == 'liters') &&
          amount < 10 &&
          amount != amount.roundToDouble()) {
        final ml = (amount * 1000).round();
        return (ml, 'mL');
      }

      final qty = amount.round();
      return (qty > 0 ? qty : 1, _normalizeUnit(unitRaw));
    }

    return (1, 'units');
  }

  static String _normalizeUnit(String raw) {
    final lower = raw.trim().toLowerCase();
    switch (lower) {
      case 'g':
      case 'gm':
      case 'gms':
      case 'gram':
      case 'grams':
        return 'g';
      case 'kg':
      case 'kgs':
      case 'kilo':
      case 'kilogram':
      case 'kilograms':
        return 'kg';
      case 'ml':
      case 'milliliter':
      case 'milliliters':
        return 'mL';
      case 'l':
      case 'ltr':
      case 'liter':
      case 'liters':
        return 'L';
      case 'can':
      case 'cans':
        return 'cans';
      case 'box':
      case 'boxes':
        return 'boxes';
      case 'bottle':
      case 'bottles':
        return 'bottles';
      case 'pack':
      case 'packs':
      case 'packet':
      case 'packets':
        return 'packets';
      case 'piece':
      case 'pieces':
        return 'pieces';
      case 'pc':
      case 'pcs':
      case 'unit':
      case 'units':
        return 'units';
      default:
        return lower.isNotEmpty ? lower : 'units';
    }
  }

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

      final (parsedQty, parsedUnit) = parseQuantityAndUnit(quantity);

      return OpenFoodFactsResult(
        barcode: cleanCode,
        found: name != null && name.isNotEmpty,
        name: name,
        brand: brand,
        category: category,
        quantityText: quantity,
        parsedQuantity: parsedQty,
        parsedUnit: parsedUnit,
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
