import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:excel/excel.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_localizations.dart';
import '../models/product.dart';
import 'product_store.dart';

class DataExportService {
  const DataExportService();

  Future<ShareResult> exportAndShare(
    BuildContext context,
    ProductStore store,
    Rect origin,
  ) async {
    final workbook = Excel.createExcel();
    final productsName = tr(context, 'Products');
    workbook.rename('Sheet1', productsName);
    final productsSheet = workbook[productsName];
    productsSheet.appendRow([
      TextCellValue(tr(context, 'Product')),
      TextCellValue(tr(context, 'Brand')),
      TextCellValue(tr(context, 'Category')),
      TextCellValue(tr(context, 'Product type')),
      TextCellValue(tr(context, 'Quantity')),
      TextCellValue(tr(context, 'Unit')),
      TextCellValue(tr(context, 'Expiry date')),
      TextCellValue(tr(context, 'Next service')),
      TextCellValue(tr(context, 'Unit cost')),
    ]);
    for (final product in store.products) {
      productsSheet.appendRow(_productRow(context, product));
    }

    final lossesName = tr(context, 'Stock losses');
    final lossesSheet = workbook[lossesName];
    lossesSheet.appendRow([TextCellValue(tr(context, 'Stock loss history'))]);
    if (store.losses.isEmpty) {
      lossesSheet.appendRow([
        TextCellValue(tr(context, 'No stock losses recorded')),
      ]);
    } else {
      for (final loss in store.losses) {
        lossesSheet.appendRow([TextCellValue(loss)]);
      }
    }

    final settingsName = tr(context, 'Settings');
    final settingsSheet = workbook[settingsName];
    settingsSheet.appendRow([
      TextCellValue(tr(context, 'Setting')),
      TextCellValue(tr(context, 'Value')),
    ]);
    final reminderDays = (store.reminderDays.toList()..sort()).join(', ');
    settingsSheet.appendRow([
      TextCellValue(tr(context, 'Remind me before')),
      TextCellValue(reminderDays),
    ]);
    settingsSheet.appendRow([
      TextCellValue(tr(context, 'Language')),
      TextCellValue(
        tr(context, switch (store.languageCode) {
          'hi' => 'Hindi',
          'gu' => 'Gujarati',
          _ => 'English',
        }),
      ),
    ]);

    final encoded = workbook.encode();
    if (encoded == null || encoded.isEmpty) {
      throw StateError('Excel workbook could not be generated.');
    }
    final filename =
        'ProductCare-${DateTime.now().toIso8601String().substring(0, 10)}.xlsx';
    return SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(encoded),
            name: filename,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        title: 'Product Care Excel export',
        text: 'Product inventory and stock-loss data',
        sharePositionOrigin: origin,
      ),
    );
  }

  List<CellValue> _productRow(BuildContext context, Product product) => [
    TextCellValue(product.name),
    TextCellValue(product.brand),
    TextCellValue(tr(context, product.category)),
    TextCellValue(tr(context, _typeName(product.kind))),
    IntCellValue(product.quantity),
    TextCellValue(product.unit),
    TextCellValue(product.expiry?.toIso8601String() ?? ''),
    TextCellValue(product.service?.toIso8601String() ?? ''),
    DoubleCellValue(product.cost),
  ];

  String _typeName(ProductKind kind) => switch (kind) {
    ProductKind.storable => 'Storable',
    ProductKind.service => 'Service',
    ProductKind.general => 'General',
  };
}
