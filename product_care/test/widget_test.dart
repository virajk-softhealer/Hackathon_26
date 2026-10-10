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
}
