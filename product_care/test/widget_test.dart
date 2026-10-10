// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:product_care/app/app_localizations.dart';
import 'package:product_care/app/product_care_app.dart';
import 'package:product_care/models/product.dart';
import 'package:product_care/pages/multi_barcode_scanner_page.dart';
import 'package:product_care/services/ai_ocr_service.dart';
import 'package:product_care/services/open_food_facts_service.dart';
import 'package:product_care/services/product_store.dart';

void main() {
  testWidgets('ProductCareApp loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProductCareApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('Service product has serviceStartDate and serviceEndDate', () {
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2026, 12, 31);
    final p = Product(
      name: 'AC Maintenance',
      brand: 'Voltas',
      category: 'Home Appliances',
      quantity: 1,
      unit: 'unit',
      kind: ProductKind.service,
      service: start,
      serviceEnd: end,
    );

    expect(p.serviceStartDate, equals(start));
    expect(p.serviceEndDate, equals(end));

    final json = p.toJson();
    expect(json['service'], equals(start.toIso8601String()));
    expect(json['service_end'], equals(end.toIso8601String()));
    expect(json.containsKey('warranty'), isFalse);

    // Verify backward compatibility reading legacy json with warranty
    final legacyJson = {
      'id': 'test-1',
      'name': 'AC Maintenance',
      'kind': 'service',
      'service': start.toIso8601String(),
      'warranty': end.toIso8601String(),
    };
    final fromLegacy = Product.fromJson(legacyJson);
    expect(fromLegacy.serviceStartDate, equals(start));
    expect(fromLegacy.serviceEndDate, equals(end));
  });

  test('Localizations support Service Start, Service End and date labels', () {
    final hi = ProductCareLocalizations(const Locale('hi'));
    expect(hi.translate('Service start'), equals('सर्विस प्रारंभ'));
    expect(hi.translate('Service end'), equals('सर्विस समाप्ति'));
    expect(hi.translate('Choose service start date'), equals('सर्विस प्रारंभ तिथि चुनें'));
    expect(hi.translate('Choose service end date'), equals('सर्विस समाप्ति तिथि चुनें'));
    expect(hi.translate('Expiry date'), equals('समाप्ति तिथि'));

    final gu = ProductCareLocalizations(const Locale('gu'));
    expect(gu.translate('Service start'), equals('સર્વિસ શરૂઆત'));
    expect(gu.translate('Service end'), equals('સર્વિસ સમાપ્તિ'));
    expect(gu.translate('Choose service start date'), equals('સર્વિસ શરૂઆતની તારીખ પસંદ કરો'));
    expect(gu.translate('Choose service end date'), equals('સર્વિસ સમાપ્તિની તારીખ પસંદ કરો'));
    expect(gu.translate('Expiry date'), equals('સમાપ્તિ તારીખ'));
    expect(gu.translate('Batches'), equals('બેચ'));
    expect(gu.translate('A product with this name already exists.'), equals('આ નામનું ઉત્પાદન પહેલેથી અસ્તિત્વમાં છે.'));
  });

  test('Batch generation formats sequences from 00001 up', () {
    expect(generateNextBatchNumber('Milk', []), equals('MILK-00001'));

    final batch1 = ProductBatch(batchNumber: 'MILK-00001', quantity: 5);
    expect(generateNextBatchNumber('Milk', [batch1]), equals('MILK-00002'));

    final batch99999 = ProductBatch(batchNumber: 'MILK-99999', quantity: 5);
    expect(generateNextBatchNumber('Milk', [batch99999]), equals('MILK-100000'));
  });

  test('Storable product with multiple batches calculates total stock and earliest expiry', () {
    final exp1 = DateTime.now().add(const Duration(days: 3));
    final exp2 = DateTime.now().add(const Duration(days: 7));

    final milk = Product(
      name: 'Milk',
      brand: 'Amul',
      category: 'Dairy',
      quantity: 8,
      unit: 'L',
      kind: ProductKind.storable,
      batches: [
        ProductBatch(batchNumber: 'MILK-00001', quantity: 5, expiry: exp1),
        ProductBatch(batchNumber: 'MILK-00002', quantity: 3, expiry: exp2),
      ],
    );

    // Total quantity is 5 + 3 = 8
    expect(milk.quantity, equals(8));

    // Earliest expiring active batch is MILK-00001 (3 days)
    expect(milk.earliestExpiringBatch?.batchNumber, equals('MILK-00001'));
    expect(milk.expiry, equals(exp1));
    expect(milk.daysToExpiry, equals(3));

    // When first batch is consumed to 0, earliest active batch shifts to MILK-00002
    milk.batches.first.quantity = 0;
    expect(milk.quantity, equals(3));
    expect(milk.earliestExpiringBatch?.batchNumber, equals('MILK-00002'));
    expect(milk.expiry, equals(exp2));
    expect(milk.daysToExpiry, equals(7));
  });

  test('MultiBarcode scanner item tracking aggregates and maps items correctly', () {
    final item1 = ScannedBarcodeItem(code: 'BARCODE-001', quantity: 2);
    final item2 = ScannedBarcodeItem(code: 'BARCODE-002', quantity: 3);
    final scanned = [item1, item2];

    final totalCount = scanned.fold<int>(0, (sum, i) => sum + i.quantity);
    expect(totalCount, equals(5));

    final hi = ProductCareLocalizations(const Locale('hi'));
    expect(hi.translate('Multi-Barcode Scanner'), equals('मल्टी-बारकोड स्कैनर'));
    final gu = ProductCareLocalizations(const Locale('gu'));
    expect(gu.translate('Multi-Barcode Scanner'), equals('મલ્ટી-બારકોડ સ્કેનર'));
  });

  test('Draft products are excluded from store counts until confirmed', () {
    final exp = DateTime.now().add(const Duration(days: 2));

    final draftProduct = Product(
      name: 'Unverified Milk',
      brand: 'Dairy',
      category: 'Pantry',
      quantity: 4,
      unit: 'L',
      kind: ProductKind.storable,
      expiry: exp,
      status: ProductStatus.draft,
    );

    final confirmedProduct = Product(
      name: 'Verified Bread',
      brand: 'Bakery',
      category: 'Pantry',
      quantity: 1,
      unit: 'pack',
      kind: ProductKind.storable,
      expiry: exp,
      status: ProductStatus.confirmed,
    );

    expect(draftProduct.isDraft, isTrue);
    expect(draftProduct.isConfirmed, isFalse);
    expect(confirmedProduct.isConfirmed, isTrue);

    final store = ProductStore();
    store.products
      ..clear()
      ..addAll([draftProduct, confirmedProduct]);

    // expiringSoon only counts confirmed products
    expect(store.expiringSoon, equals(1));

    // lowStock only counts confirmed products
    expect(store.lowStock, equals(1));

    // totalUnits only counts confirmed products (1 unit from bread, 0 from milk)
    expect(store.totalUnits, equals(1));

    // draftCount is 1
    expect(store.draftCount, equals(1));

    // Confirm draft product
    final success = store.confirmProduct(draftProduct);
    expect(success, isTrue);

    // Now both products are confirmed
    expect(store.draftCount, equals(0));
    expect(store.expiringSoon, equals(2));
    expect(store.totalUnits, equals(5)); // 4 + 1
  });

  test('Draft verification localizations translate correctly in Hindi and Gujarati', () {
    final hi = ProductCareLocalizations(const Locale('hi'));
    expect(hi.translate('Draft'), equals('ड्राफ्ट'));
    expect(hi.translate('Verify & Confirm'), equals('सत्यापित और पुष्ट करें'));

    final gu = ProductCareLocalizations(const Locale('gu'));
    expect(gu.translate('Draft'), equals('ડ્રાફ્ટ'));
    expect(gu.translate('Verify & Confirm'), equals('ચકાસો અને પુષ્ટ કરો'));
  });

  test('Batch expiration date can be updated and updates product earliest expiry', () {
    final batchDate1 = DateTime(2026, 10, 15);
    final batchDate2 = DateTime(2026, 10, 20);

    final product = Product(
      name: 'Milk',
      brand: 'Amul',
      category: 'Dairy',
      quantity: 5,
      unit: 'L',
      kind: ProductKind.storable,
      barcode: '8901262010014',
      storageInstructions: 'Keep refrigerated below 4C',
      additionalDetails: {'Nutri-Score': 'Grade B', 'Allergens': 'Milk'},
      batches: [
        ProductBatch(batchNumber: 'MILK-00001', quantity: 2, expiry: batchDate1),
        ProductBatch(batchNumber: 'MILK-00002', quantity: 3, expiry: batchDate2),
      ],
    );

    // Initial earliest expiry is batch 1
    expect(product.expiry, equals(batchDate1));
    expect(product.barcode, equals('8901262010014'));
    expect(product.storageInstructions, equals('Keep refrigerated below 4C'));
    expect(product.additionalDetails['Nutri-Score'], equals('Grade B'));

    // Update batch 1 expiry date to later than batch 2
    final newDate1 = DateTime(2026, 10, 25);
    final updated = product.updateBatchExpiry('MILK-00001', newDate1);
    expect(updated, isTrue);

    // Now earliest active expiry shifts to batch 2!
    expect(product.expiry, equals(batchDate2));

    // Serialization preserves all new fields and batch dates
    final json = product.toJson();
    final restored = Product.fromJson(json);
    expect(restored.barcode, equals('8901262010014'));
    expect(restored.storageInstructions, equals('Keep refrigerated below 4C'));
    expect(restored.additionalDetails['Allergens'], equals('Milk'));
    expect(restored.batches.first.expiry, equals(newDate1));
  });

  test('ProductStore.addProduct inserts at index 0 so latest product appears on top', () {
    final store = ProductStore();
    store.products.clear();

    final product1 = Product(name: 'Product 1', brand: '', category: 'Pantry', quantity: 1, unit: 'units', kind: ProductKind.general);
    final product2 = Product(name: 'Product 2', brand: '', category: 'Pantry', quantity: 2, unit: 'units', kind: ProductKind.general);

    store.addProduct(product1);
    expect(store.products.first.name, equals('Product 1'));

    // When product2 is added, it must appear on top (index 0)
    store.addProduct(product2);
    expect(store.products.first.name, equals('Product 2'));
    expect(store.products[1].name, equals('Product 1'));
  });

  test('Dropdown item set prevents DropdownButton crashes on custom categories', () {
    const customCategory = 'Snacks & Beverages';
    final categories = <String>{
      'Pantry',
      'Dairy',
      'Health',
      'Household',
      'Appliances',
      'Other',
      if (customCategory.isNotEmpty) customCategory,
    };

    expect(categories.contains('Snacks & Beverages'), isTrue);
    expect(categories.where((c) => c == customCategory).length, equals(1));

    // When category is standard (e.g. 'Dairy'), set deduplicates so length is still 1
    const standardCategory = 'Dairy';
    final deduplicated = <String>{
      'Pantry',
      'Dairy',
      'Health',
      'Household',
      'Appliances',
      'Other',
      if (standardCategory.isNotEmpty) standardCategory,
    };
    expect(deduplicated.where((c) => c == 'Dairy').length, equals(1));
  });

  test('OpenFoodFactsService parses quantity and UOM properly', () {
    // "48 g" -> 48, 'g'
    final (qty1, unit1) = OpenFoodFactsService.parseQuantityAndUnit('48 g');
    expect(qty1, equals(48));
    expect(unit1, equals('g'));

    // "48g" -> 48, 'g'
    final (qty1b, unit1b) = OpenFoodFactsService.parseQuantityAndUnit('48g');
    expect(qty1b, equals(48));
    expect(unit1b, equals('g'));

    // "500 ml" -> 500, 'mL'
    final (qty2, unit2) = OpenFoodFactsService.parseQuantityAndUnit('500 ml');
    expect(qty2, equals(500));
    expect(unit2, equals('mL'));

    // "1.5 kg" -> 1500, 'g'
    final (qty3, unit3) = OpenFoodFactsService.parseQuantityAndUnit('1.5 kg');
    expect(qty3, equals(1500));
    expect(unit3, equals('g'));

    // Multipack "6 x 330 ml" -> 1980, 'mL'
    final (qty4, unit4) = OpenFoodFactsService.parseQuantityAndUnit('6 x 330 ml');
    expect(qty4, equals(1980));
    expect(unit4, equals('mL'));

    // Null or empty -> 1, 'units'
    final (qty5, unit5) = OpenFoodFactsService.parseQuantityAndUnit(null);
    expect(qty5, equals(1));
    expect(unit5, equals('units'));
  });

  test('No internet scanner alert strings translate correctly in Hindi and Gujarati', () {
    final hi = ProductCareLocalizations(const Locale('hi'));
    expect(hi.translate('No Internet Connection'), equals('कोई इंटरनेट कनेक्शन नहीं'));
    expect(hi.translate('Scan Offline'), equals('ऑफ़लाइन स्कैन करें'));
    expect(hi.translate('Try Again'), equals('पुनः प्रयास करें'));

    final gu = ProductCareLocalizations(const Locale('gu'));
    expect(gu.translate('No Internet Connection'), equals('ઇન્ટરનેટ કનેક્શન નથી'));
    expect(gu.translate('Scan Offline'), equals('ઑફલાઇન સ્કેન કરો'));
    expect(gu.translate('Try Again'), equals('ફરી પ્રયાસ કરો'));
  });

  test('AiOcrService extracts expiry, weight, batch, and cost from raw OCR text', () {
    const ocrSample = '''
    CADBURY DAIRY MILK
    CHOCOLATE
    NET WT: 48g
    BATCH NO: B20491
    MFD: 01/26
    EXP: 25/12/2026
    MRP: ₹ 45.00
    INCL. OF ALL TAXES
    ''';

    final expiry = AiOcrService.extractExpiry(ocrSample);
    expect(expiry, isNotNull);
    expect(expiry!.year, equals(2026));
    expect(expiry.month, equals(12));
    expect(expiry.day, equals(25));

    final (qty, unit) = AiOcrService.extractWeightAndUnit(ocrSample);
    expect(qty, equals(48));
    expect(unit, equals('g'));

    final batch = AiOcrService.extractBatchNumber(ocrSample);
    expect(batch, equals('B20491'));

    final cost = AiOcrService.extractCost(ocrSample);
    expect(cost, equals(45.0));

    final (name, brand) = AiOcrService.extractNameAndBrand([
      'CADBURY',
      'DAIRY MILK',
      'CHOCOLATE',
    ]);
    expect(name, contains('DAIRY MILK'));
    expect(brand, equals('CADBURY'));

    // Test text with month name: "BEST BEFORE 15 OCT 2026"
    final expNamed = AiOcrService.extractExpiry('BEST BEFORE 15 OCT 2026');
    expect(expNamed, isNotNull);
    expect(expNamed!.year, equals(2026));
    expect(expNamed.month, equals(10));
    expect(expNamed.day, equals(15));

    // Test multi-line date where EXP is on line 0 and date is on line 1:
    final expMultiLine = AiOcrService.extractExpiry('EXP DATE\n15/10/2026', ['EXP DATE', '15/10/2026']);
    expect(expMultiLine, isNotNull);
    expect(expMultiLine!.year, equals(2026));
    expect(expMultiLine.month, equals(10));
    expect(expMultiLine.day, equals(15));

    // Test month/year format: "EXP: 10/26"
    final expMonthYear = AiOcrService.extractExpiry('EXP: 10/26');
    expect(expMonthYear, isNotNull);
    expect(expMonthYear!.year, equals(2026));
    expect(expMonthYear.month, equals(10));

    // Test MRP with Rs. and slash: "MRP RS. 45/-"
    final cost2 = AiOcrService.extractCost('MRP RS. 45/-');
    expect(cost2, equals(45.0));
  });

  test('Smart Scan bottom bar translations match in Hindi and Gujarati', () {
    final hi = ProductCareLocalizations(const Locale('hi'));
    expect(hi.translate('Smart Scan'), equals('स्मार्ट स्कैन'));
    expect(hi.translate('Currently no product scanned. Use the + icon to scan your product.'),
        equals('वर्तमान में कोई उत्पाद स्कैन नहीं हुआ है। अपने उत्पाद को स्कैन करने के लिए + आइकन का उपयोग करें।'));

    final gu = ProductCareLocalizations(const Locale('gu'));
    expect(gu.translate('Smart Scan'), equals('સ્માર્ટ સ્કેન'));
    expect(gu.translate('Currently no product scanned. Use the + icon to scan your product.'),
        equals('હાલમાં કોઈ ઉત્પાદન સ્કેન કરેલ નથી. તમારા ઉત્પાદનને સ્કેન કરવા માટે + આયકનનો ઉપયોગ કરો.'));
  });

  test('AiOcrService correctly extracts Expiry Date, MRP, Batch, Weight from columnar packaging sample', () {
    const packagingSample = '''
    NET WEIGHT:
    PKD.:
    EXPIRY DATE:
    SERVING PER
    PACKAGE*/B. NO.:
    UNIT SALE PRICE :
    MRP:
    (INCL OF ALL TAXES)
    10.00
    48g
    18:21
    21SEP26
    20JAN27
    2/U1D27B
    0.21 PER g
    ''';

    final lines = packagingSample
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. Expiry Date must be 20JAN27 (20 Jan 2027), NOT 21SEP26 (Packed date)
    final expiry = AiOcrService.extractExpiry(packagingSample, lines);
    expect(expiry, isNotNull);
    expect(expiry!.year, equals(2027));
    expect(expiry.month, equals(1));
    expect(expiry.day, equals(20));

    // 2. Weight must be 48 g
    final (qty, unit) = AiOcrService.extractWeightAndUnit(packagingSample);
    expect(qty, equals(48));
    expect(unit, equals('g'));

    // 3. MRP must be 10.00
    final cost = AiOcrService.extractCost(packagingSample, lines);
    expect(cost, equals(10.0));

    // 4. Batch must be 2/U1D27B
    final batch = AiOcrService.extractBatchNumber(packagingSample, lines);
    expect(batch, equals('2/U1D27B'));
  });

  test('Scanned purchases are treated as separate draft product variants', () {
    final store = ProductStore();
    store.products.clear();
    final existing = Product(
      name: 'Amul Milk',
      brand: 'Amul',
      category: 'Dairy',
      quantity: 1,
      unit: 'L',
      kind: ProductKind.storable,
      status: ProductStatus.confirmed,
      expiry: DateTime(2026, 10, 15),
      batches: [
        ProductBatch(
          batchNumber: 'AMULMILK-00001',
          quantity: 1,
          expiry: DateTime(2026, 10, 15),
        ),
      ],
    );
    store.addProduct(existing);

    // When another purchase is scanned after 15 days, it should NOT mutate existing stock
    // but should be created as a separate draft variant
    final newVariantBatch =
        generateNextBatchNumber(existing.name, existing.batches);
    final variant = Product(
      name: existing.name,
      brand: existing.brand,
      category: existing.category,
      quantity: 1,
      unit: existing.unit,
      kind: existing.kind,
      status: ProductStatus.draft, // Created as separate draft product variant
      expiry: DateTime(2026, 11, 1),
      batches: [
        ProductBatch(
          batchNumber: newVariantBatch,
          quantity: 1,
          expiry: DateTime(2026, 11, 1),
        ),
      ],
    );
    store.addProduct(variant);

    expect(store.products.length, equals(2));
    expect(store.products.first.isDraft, isTrue);
    expect(store.products.first.batches.first.batchNumber,
        equals('AMULMILK-00002'));
    // Confirmed count should still be 1 because draft requires verification
    expect(store.products.where((p) => p.isConfirmed).length, equals(1));
  });

  test('Stock decrease messages and unit measurements are localized language-wise', () {
    final hi = ProductCareLocalizations(const Locale('hi'));
    final gu = ProductCareLocalizations(const Locale('gu'));

    // 1. Stock loss message properly localizes units in Hindi & Gujarati
    final hiMsg = hi.translate(
      '{quantity} {unit} recorded as loss. Remaining stock: {remaining}.',
      {'quantity': 2, 'unit': 'packets', 'remaining': 8},
    );
    expect(hiMsg, equals('2 पैकेट की हानि दर्ज। शेष स्टॉक: 8।'));

    final guMsg = gu.translate(
      '{quantity} {unit} recorded as loss. Remaining stock: {remaining}.',
      {'quantity': 1, 'unit': 'pieces', 'remaining': 4},
    );
    expect(guMsg, equals('1 ટુકડાનું નુકસાન નોંધાયું. બાકી જથ્થો: 4.'));

    // Singular and plural units are mapped correctly
    final hiUnitMsg = hi.translate(
      'Available: {quantity} {unit}',
      {'quantity': 5, 'unit': 'units'},
    );
    expect(hiUnitMsg, equals('उपलब्ध: 5 इकाइयां'));

    final guUnitMsg = gu.translate(
      'Available: {quantity} {unit}',
      {'quantity': 1, 'unit': 'unit'},
    );
    expect(guUnitMsg, equals('ઉપલબ્ધ: 1 એકમ'));
  });

  test('AI Scan offline internet connection prompt strings translate accurately', () {
    final hi = ProductCareLocalizations(const Locale('hi'));
    final gu = ProductCareLocalizations(const Locale('gu'));

    expect(
      hi.translate('No Internet Connection, Use Manual Offline'),
      equals('कोई इंटरनेट कनेक्शन नहीं, ऑफ़लाइन मैन्युअल उपयोग करें'),
    );
    expect(
      gu.translate('No Internet Connection, Use Manual Offline'),
      equals('ઇન્ટરનેટ કનેક્શન નથી, ઑફલાઇન મેન્યુઅલ વાપરો'),
    );
    expect(
      hi.translate('Use Manual Offline'),
      equals('ऑफ़लाइन मैन्युअल उपयोग करें'),
    );
    expect(
      gu.translate('Use Manual Offline'),
      equals('ઑફલાઇન મેન્યુઅલ વાપરો'),
    );
  });
}
