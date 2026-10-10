import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'open_food_facts_service.dart';

class AiOcrProductItem {
  AiOcrProductItem({
    required this.imageFile,
    required this.name,
    this.brand,
    this.category = 'Other',
    this.quantity = 1,
    this.unit = 'units',
    this.expiry,
    this.batchNumber,
    this.cost = 0.0,
    this.barcode,
    this.imageUrl,
    this.storageInstructions,
    this.rawText = '',
    this.additionalDetails = const {},
  });

  final File imageFile;
  String name;
  String? brand;
  String category;
  int quantity;
  String unit;
  DateTime? expiry;
  String? batchNumber;
  double cost;
  String? barcode;
  String? imageUrl;
  String? storageInstructions;
  String rawText;
  Map<String, String> additionalDetails;
}

class OcrLineInfo {
  OcrLineInfo({
    required this.text,
    required this.rect,
  });

  final String text;
  final Rect rect;

  double get centerY => rect.top + rect.height / 2;
  double get left => rect.left;
  double get right => rect.right;
  double get top => rect.top;
  double get bottom => rect.bottom;
}

class AiOcrService {
  static final Map<String, int> _monthNames = {
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };

  /// Single-step process: Scans the barcode and recognizes text from ONE photo.
  /// Merges Open Food Facts metadata (name, brand, image, UOM) with
  /// AI-extracted Expiration Date and Price (MRP).
  static Future<AiOcrProductItem> processImage(File imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);

    // 1. Detect barcode from the photo
    String? detectedBarcode;
    final barcodeScanner = BarcodeScanner();
    try {
      final barcodes = await barcodeScanner.processImage(inputImage);
      for (final b in barcodes) {
        final val = b.rawValue?.trim();
        if (val != null && val.isNotEmpty) {
          detectedBarcode = val;
          break;
        }
      }
    } catch (e) {
      debugPrint('Barcode detection from image error: $e');
    } finally {
      await barcodeScanner.close();
    }

    // 2. Perform OCR text recognition on the photo with bounding boxes
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    var fullText = '';
    final lines = <String>[];
    final lineInfos = <OcrLineInfo>[];
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      fullText = recognizedText.text;
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final t = line.text.trim();
          if (t.isNotEmpty) {
            lines.add(t);
            lineInfos.add(OcrLineInfo(text: t, rect: line.boundingBox));
          }
        }
      }
    } catch (e) {
      debugPrint('OCR error: $e');
    } finally {
      await textRecognizer.close();
    }

    // 3. Extract Expiration Date, Price (MRP), and Batch using Spatial + Multi-Date heuristics
    final expiry = extractExpiry(fullText, lines, lineInfos);
    final cost = extractCost(fullText, lines, lineInfos);
    final batch = extractBatchNumber(fullText, lines, lineInfos);
    final (ocrQty, ocrUnit) = extractWeightAndUnit(fullText);

    // 4. If Barcode detected, fetch online details from Open Food Facts API
    OpenFoodFactsResult? facts;
    if (detectedBarcode != null && detectedBarcode.isNotEmpty) {
      try {
        facts = await OpenFoodFactsService.lookupBarcode(detectedBarcode);
      } catch (e) {
        debugPrint('Open Food Facts API error: $e');
      }
    }

    final AiOcrProductItem finalProduct;

    // 5. Merge everything into one unified product draft
    if (facts != null && facts.found) {
      final (parsedQty, parsedUom) =
          OpenFoodFactsService.parseQuantityAndUnit(facts.quantityText);
      final finalQty = facts.parsedQuantity ?? parsedQty;
      final finalUnit = facts.parsedUnit ?? parsedUom;

      final mergedDetails = Map<String, String>.from(facts.additionalDetails);
      if (batch != null && batch.isNotEmpty) mergedDetails['Batch'] = batch;
      if (cost > 0) mergedDetails['MRP'] = '₹${cost.toStringAsFixed(2)}';

      finalProduct = AiOcrProductItem(
        imageFile: imageFile,
        name: (facts.name != null && facts.name!.isNotEmpty)
            ? facts.name!
            : (detectedBarcode ?? 'Product'),
        brand: facts.brand,
        category: facts.category?.isNotEmpty == true ? facts.category! : 'Other',
        quantity: finalQty > 0 ? finalQty : ocrQty,
        unit: finalUnit.isNotEmpty ? finalUnit : ocrUnit,
        expiry: expiry, // Expiry date from AI OCR!
        batchNumber: batch,
        cost: cost > 0 ? cost : 0.0, // Price from AI OCR!
        barcode: detectedBarcode,
        imageUrl: facts.imageUrl,
        storageInstructions: facts.storageInstructions,
        rawText: fullText,
        additionalDetails: mergedDetails,
      );
    } else {
      // Fallback: If no barcode was visible in the photo or API didn't find it,
      // use OCR text for product name and brand:
      final (name, brand) = extractNameAndBrand(lines);
      final category = detectCategory(fullText);

      final details = <String, String>{};
      if (batch != null && batch.isNotEmpty) details['Batch'] = batch;
      if (cost > 0) details['MRP'] = '₹${cost.toStringAsFixed(2)}';
      if (detectedBarcode != null) details['Barcode'] = detectedBarcode;

      finalProduct = AiOcrProductItem(
        imageFile: imageFile,
        name: name,
        brand: brand,
        category: category,
        quantity: ocrQty,
        unit: ocrUnit,
        expiry: expiry,
        batchNumber: batch,
        cost: cost,
        barcode: detectedBarcode,
        rawText: fullText,
        additionalDetails: details,
      );
    }

    // Print clean, structured log block with \n\n separators:
    _logOcrSummary(
      imageFile: imageFile,
      barcode: detectedBarcode,
      facts: facts,
      rawText: fullText,
      expiry: expiry,
      cost: cost,
      ocrWeight: (ocrQty, ocrUnit),
      batch: batch,
      finalItem: finalProduct,
    );

    return finalProduct;
  }

  /// Prints a dedicated, nicely formatted block logger with \n\n separators
  static void _logOcrSummary({
    required File imageFile,
    required String? barcode,
    required OpenFoodFactsResult? facts,
    required String rawText,
    required DateTime? expiry,
    required double cost,
    required (int qty, String unit) ocrWeight,
    required String? batch,
    required AiOcrProductItem finalItem,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('\n\n============================================================');
    buffer.writeln('🔍 [AI OCR & PRODUCT SCANNER LOG]');
    buffer.writeln('============================================================');
    buffer.writeln('📁 Photo File: ${imageFile.path.split('/').last}');
    buffer.writeln('------------------------------------------------------------');
    buffer.writeln('📦 1. BARCODE & ONLINE API:');
    if (barcode != null && barcode.isNotEmpty) {
      buffer.writeln('   ✓ Detected Barcode: $barcode');
      if (facts != null && facts.found) {
        buffer.writeln('   ✓ Open Food Facts:  FOUND');
        buffer.writeln('     • Name:           ${facts.name}');
        buffer.writeln('     • Brand:          ${facts.brand ?? "N/A"}');
        buffer.writeln('     • Category:       ${facts.category ?? "N/A"}');
        buffer.writeln('     • Raw Packaging:  ${facts.quantityText ?? "N/A"}');
        buffer.writeln('     • Image URL:      ${facts.imageUrl ?? "N/A"}');
      } else {
        buffer.writeln('   ✗ Open Food Facts:  No match found or offline');
      }
    } else {
      buffer.writeln('   ✗ Barcode in photo: Not detected (using pure OCR)');
    }

    buffer.writeln('------------------------------------------------------------');
    buffer.writeln('📝 2. AI OCR EXTRACTED DETAILS:');
    buffer.writeln(
      '   📅 Expiration Date: ${expiry != null ? "${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}" : "NOT FOUND (Will use 30d default)"}',
    );
    buffer.writeln(
      '   💰 Price / MRP:     ${cost > 0 ? "₹${cost.toStringAsFixed(2)}" : "NOT FOUND"}',
    );
    buffer.writeln('   🏷️ Batch Number:    ${batch ?? "NOT FOUND"}');
    buffer.writeln('   ⚖️ Detected Weight: ${ocrWeight.$1} ${ocrWeight.$2}');

    buffer.writeln('------------------------------------------------------------');
    buffer.writeln('📄 3. RAW DETECTED TEXT:');
    if (rawText.trim().isEmpty) {
      buffer.writeln('   (No text detected by OCR)');
    } else {
      for (final line in rawText.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          buffer.writeln('   | $trimmed');
        }
      }
    }

    buffer.writeln('------------------------------------------------------------');
    buffer.writeln('✨ 4. FINAL MERGED PRODUCT CREATED:');
    buffer.writeln('   • Name:             ${finalItem.name}');
    buffer.writeln('   • Brand:            ${finalItem.brand ?? "N/A"}');
    buffer.writeln('   • Category:         ${finalItem.category}');
    buffer.writeln('   • Quantity:         ${finalItem.quantity} ${finalItem.unit}');
    buffer.writeln(
      '   • Expiration Date:  ${finalItem.expiry != null ? "${finalItem.expiry!.year}-${finalItem.expiry!.month.toString().padLeft(2, '0')}-${finalItem.expiry!.day.toString().padLeft(2, '0')}" : "Default (30 days)"}',
    );
    buffer.writeln('   • Unit Cost:        ₹${finalItem.cost.toStringAsFixed(2)}');
    buffer.writeln('   • Barcode:          ${finalItem.barcode ?? "N/A"}');
    buffer.writeln('   • Batch:            ${finalItem.batchNumber ?? "Auto-generated"}');
    buffer.writeln('============================================================\n\n');

    debugPrint(buffer.toString());
  }

  /// High-accuracy Expiration Date extractor with 3-Layer matching:
  /// Layer 1: Spatial horizontal alignment (EXP label on left -> date on right)
  /// Layer 2: Multi-line adjacent check (EXP label on line i -> date on line i+1)
  /// Layer 3: Multi-date comparison (When PKD and EXP exist, Expiry is ALWAYS the later date!)
  static DateTime? extractExpiry(
    String text, [
    List<String>? lines,
    List<OcrLineInfo>? lineInfos,
  ]) {
    final clean = text.replaceAll('\r', '\n');

    // Layer 1: Spatial Y-Axis alignment between left-column EXP label and right-column value
    if (lineInfos != null && lineInfos.isNotEmpty) {
      for (final labelLine in lineInfos) {
        final t = labelLine.text.toLowerCase();
        final isExpLabel = t.contains('expiry') ||
            t.contains('use by') ||
            t.contains('best before') ||
            (t.contains('exp') && !t.contains('expect') && t.length <= 16);

        if (isExpLabel) {
          for (final valLine in lineInfos) {
            if (valLine == labelLine) continue;
            final isToRight = valLine.left >= labelLine.left + 15;
            final isSameY = (valLine.centerY - labelLine.centerY).abs() < 40;
            if (isToRight && isSameY) {
              final d = _parseAnyDateString(valLine.text);
              if (d != null) return d;
            }
          }
        }
      }
    }

    // Layer 2A: Same-line regex with compact date support (e.g. "EXP: 20JAN27", "EXP: 15/12/2026")
    final sameLinePattern = RegExp(
      r'(?:EXP(?:IRY)?|USE\s*BY|BEST\s*BEFORE|B\.?B\.?|EXP\s*DATE|B\/NO|E\.X\.P\.?)[:\s\.\-]*(\d{1,2})[\/\.\-\s]*([a-zA-Z]{3}|\d{1,2})[\/\.\-\s]*(\d{2,4})\b',
      caseSensitive: false,
    );
    final match1 = sameLinePattern.firstMatch(clean);
    if (match1 != null) {
      final mid = match1.group(2)!;
      if (RegExp(r'^[a-zA-Z]{3}$').hasMatch(mid)) {
        final res = _parseNamedMonth(match1.group(1), mid, match1.group(3));
        if (res != null) return res;
      } else {
        final res = _parseDateNumbers(match1.group(1), mid, match1.group(3));
        if (res != null) return res;
      }
    }

    // Layer 2B: Multi-line adjacent check (Label on line i, Date on line i+1 or i+2)
    if (lines != null && lines.isNotEmpty) {
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        final isExpMarker = RegExp(
          r'^(?:EXP|EXPIRY|USE\s*BY|BEST\s*BEFORE|B\.?B\.?|EXP\s*DATE|EXPIRY\s*DATE)[:\s\.\-]*$',
          caseSensitive: false,
        ).hasMatch(line) || (line.toLowerCase().contains('exp') && line.length <= 15);

        if (isExpMarker) {
          if (i + 1 < lines.length) {
            final nextRes = _parseAnyDateString(lines[i + 1].trim());
            if (nextRes != null) return nextRes;
          }
          if (i + 2 < lines.length) {
            final nextNextRes = _parseAnyDateString(lines[i + 2].trim());
            if (nextNextRes != null) return nextNextRes;
          }
        }
      }
    }

    // Layer 3: Multi-Date Comparison (Golden Rule)
    // When both PKD / MFD (Packed date) and EXPIRY exist in the packaging (e.g. 21SEP26 and 20JAN27):
    // The EXPIRY DATE is ALWAYS the LATER date chronologically!
    final allFoundDates = findAllDatesInText(clean);
    if (allFoundDates.isNotEmpty) {
      if (allFoundDates.length == 1) {
        return allFoundDates.first;
      }
      // Sort chronologically ascending
      allFoundDates.sort((a, b) => a.compareTo(b));
      // The latest date is the Expiry Date!
      return allFoundDates.last;
    }

    // Layer 4: "BEST BEFORE X MONTHS" combined with "MFD / PKD" date
    final monthsFromMfg = RegExp(
      r'BEST\s*BEFORE\s*(\d{1,2})\s*MONTHS?',
      caseSensitive: false,
    ).firstMatch(clean);
    if (monthsFromMfg != null) {
      final monthsAdd = int.tryParse(monthsFromMfg.group(1)!) ?? 6;
      final mfgMatch = RegExp(
        r'(?:MFD|MFG|PKD|PACKED)[:\s\.\-]*(\d{1,2})[\/\.\-](\d{2,4})\b',
        caseSensitive: false,
      ).firstMatch(clean);
      if (mfgMatch != null) {
        final mfgDate = _parseMonthYear(mfgMatch.group(1), mfgMatch.group(2));
        if (mfgDate != null) {
          return DateTime(mfgDate.year, mfgDate.month + monthsAdd, mfgDate.day);
        }
      }
    }

    return null;
  }

  /// Extracts ALL valid dates from any text/lines
  static List<DateTime> findAllDatesInText(String text) {
    final results = <DateTime>{};

    // 1. Compact format: 20JAN27, 21SEP26, 15OCT2026, 05NOV25
    final compactMatches = RegExp(
      r'\b(\d{1,2})([a-zA-Z]{3})(\d{2,4})\b',
      caseSensitive: false,
    ).allMatches(text);
    for (final cm in compactMatches) {
      final d = _parseNamedMonth(cm.group(1), cm.group(2), cm.group(3));
      if (d != null) results.add(d);
    }

    // 2. Standard with separators: 15/10/2026, 15-10-26, 15.10.2026
    final standardMatches = RegExp(
      r'\b(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{2,4})\b',
    ).allMatches(text);
    for (final sm in standardMatches) {
      final d = _parseDateNumbers(sm.group(1), sm.group(2), sm.group(3));
      if (d != null) results.add(d);
    }

    // 3. Named month with space/separator: 15 OCT 2026, 15-OCT-26
    final namedMatches = RegExp(
      r'\b(\d{1,2})[\s\.\-]+([a-zA-Z]{3,9})[\s\.\-]+(\d{2,4})\b',
      caseSensitive: false,
    ).allMatches(text);
    for (final nm in namedMatches) {
      final d = _parseNamedMonth(nm.group(1), nm.group(2), nm.group(3));
      if (d != null) results.add(d);
    }

    // 4. Standalone Month/Year: 10/26, 05/2027
    final myMatches = RegExp(
      r'\b(\d{1,2})[\/\.\-](202[5-9]|203[0-5]|2[5-9])\b',
    ).allMatches(text);
    for (final my in myMatches) {
      final d = _parseMonthYear(my.group(1), my.group(2));
      if (d != null) results.add(d);
    }

    return results.toList();
  }

  /// Parses any date string (compact, slash, named, or month-year)
  static DateTime? _parseAnyDateString(String text) {
    final clean = text.trim();

    // Compact format: 20JAN27 or 21SEP26
    final compact = RegExp(
      r'^(?:EXP(?:IRY)?)?[:\s\.\-]*(\d{1,2})([a-zA-Z]{3})(\d{2,4})$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (compact != null) {
      return _parseNamedMonth(compact.group(1), compact.group(2), compact.group(3));
    }

    // Full date: DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final full = RegExp(r'^(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{2,4})$').firstMatch(clean);
    if (full != null) {
      return _parseDateNumbers(full.group(1), full.group(2), full.group(3));
    }

    // Named month: 15 OCT 2026 or 15-OCT-26
    final named = RegExp(
      r'^(?:(\d{1,2})[\s\.\-]+)?([a-zA-Z]{3,9})[\s\.\-]+(\d{2,4})$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (named != null) {
      return _parseNamedMonth(named.group(1), named.group(2), named.group(3));
    }

    // Month/Year: 10/26 or 10/2026
    final my = RegExp(r'^(\d{1,2})[\/\.\-](\d{2,4})$').firstMatch(clean);
    if (my != null) {
      return _parseMonthYear(my.group(1), my.group(2));
    }

    return null;
  }

  static DateTime? _parseDateNumbers(String? dStr, String? mStr, String? yStr) {
    if (dStr == null || mStr == null || yStr == null) return null;
    final d = int.tryParse(dStr);
    final m = int.tryParse(mStr);
    var y = int.tryParse(yStr);
    if (y != null && y < 100) y += 2000;
    if (d != null && m != null && y != null) {
      if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      } else if (d >= 1 && d <= 12 && m >= 1 && m <= 31) {
        return DateTime(y, d, m);
      }
    }
    return null;
  }

  static DateTime? _parseNamedMonth(String? dStr, String? mStr, String? yStr) {
    if (mStr == null || yStr == null) return null;
    final month = _monthNames[mStr.toLowerCase()];
    var y = int.tryParse(yStr);
    if (y != null && y < 100) y += 2000;
    if (month != null && y != null) {
      final d = dStr != null ? (int.tryParse(dStr) ?? 1) : 1;
      return DateTime(y, month, d);
    }
    return null;
  }

  static DateTime? _parseMonthYear(String? mStr, String? yStr) {
    if (mStr == null || yStr == null) return null;
    final m = int.tryParse(mStr);
    var y = int.tryParse(yStr);
    if (y != null && y < 100) y += 2000;
    if (m != null && m >= 1 && m <= 12 && y != null && y >= 2020) {
      final nextMonth = m == 12 ? DateTime(y + 1, 1, 1) : DateTime(y, m + 1, 1);
      return nextMonth.subtract(const Duration(days: 1));
    }
    return null;
  }

  /// Extracts MRP or price with spatial alignment and multi-line support
  static double extractCost(
    String text, [
    List<String>? lines,
    List<OcrLineInfo>? lineInfos,
  ]) {
    // 1. Spatial alignment: Line with "MRP" on left -> numeric value on right
    if (lineInfos != null && lineInfos.isNotEmpty) {
      for (final labelLine in lineInfos) {
        final t = labelLine.text.toUpperCase();
        if (t.contains('MRP') || t.contains('PRICE') || t.contains('RS')) {
          for (final valLine in lineInfos) {
            if (valLine == labelLine) continue;
            final isToRight = valLine.left >= labelLine.left + 15;
            final isSameY = (valLine.centerY - labelLine.centerY).abs() < 35;
            if (isToRight && isSameY) {
              final numMatch = RegExp(r'\b([0-9]+(?:\.[0-9]{1,2})?)\b')
                  .firstMatch(valLine.text);
              if (numMatch != null) {
                final cost = double.tryParse(numMatch.group(1)!);
                if (cost != null && cost > 0 && cost < 100000) {
                  return cost;
                }
              }
            }
          }
        }
      }
    }

    // 2. Multi-line inspection: Line following "MRP" or "(INCL OF ALL TAXES)"
    if (lines != null) {
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i].toUpperCase();
        if (l.contains('MRP') ||
            l.contains('INCL OF ALL TAXES') ||
            l.contains('INCL. OF ALL TAXES')) {
          for (var j = 1; j <= 2; j++) {
            if (i + j < lines.length) {
              final candidate = lines[i + j].trim();
              final numMatch = RegExp(r'^([0-9]+(?:\.[0-9]{1,2})?)$')
                  .firstMatch(candidate);
              if (numMatch != null) {
                final cost = double.tryParse(numMatch.group(1)!);
                if (cost != null && cost > 0 && cost < 100000) {
                  return cost;
                }
              }
            }
          }
        }
      }
    }

    // 3. Regular regex "MRP: ₹ 45.00" or "MRP RS. 10.00"
    final mrpPattern = RegExp(
      r'(?:M\.?R\.?P\.?|PRICE|₹|RS\.?|INR)[:\s\.\-]*([0-9]+(?:\.[0-9]{1,2})?)(?:\s*\/-)?\b',
      caseSensitive: false,
    );
    final match = mrpPattern.firstMatch(text);
    if (match != null) {
      final val = double.tryParse(match.group(1)!);
      if (val != null && val > 0 && val < 100000) {
        return val;
      }
    }

    return 0.0;
  }

  /// Extracts weight and unit, e.g. "Net Wt: 48g" -> (48, 'g')
  static (int quantity, String unit) extractWeightAndUnit(String text) {
    final weightPattern = RegExp(
      r'(?:NET\s*(?:WT|WEIGHT|QTY)?|WEIGHT|QTY)?[:\s\.\-]*(\d+(?:\.\d+)?)\s*(g|gm|gms|gram|grams|kg|kgs|kilo|ml|milliliter|l|ltr|liter|liters|tablets|capsules|pcs|pieces)\b',
      caseSensitive: false,
    );

    final match = weightPattern.firstMatch(text);
    if (match != null) {
      final raw = '${match.group(1)} ${match.group(2)}';
      return OpenFoodFactsService.parseQuantityAndUnit(raw);
    }

    return (1, 'units');
  }

  /// Extracts batch or lot number with spatial alignment and keyword filtering
  static String? extractBatchNumber(
    String text, [
    List<String>? lines,
    List<OcrLineInfo>? lineInfos,
  ]) {
    // 1. Spatial alignment: Line with "B. NO" / "BATCH" / "LOT" on left -> value on right
    if (lineInfos != null && lineInfos.isNotEmpty) {
      for (final labelLine in lineInfos) {
        final t = labelLine.text.toUpperCase();
        if (t.contains('B. NO') ||
            t.contains('BATCH') ||
            t.contains('B.NO') ||
            t.contains('LOT')) {
          for (final valLine in lineInfos) {
            if (valLine == labelLine) continue;
            final isToRight = valLine.left >= labelLine.left + 15;
            final isSameY = (valLine.centerY - labelLine.centerY).abs() < 35;
            if (isToRight && isSameY) {
              final val = valLine.text.trim();
              if (_isValidBatchCode(val)) {
                return val;
              }
            }
          }
        }
      }
    }

    // 2. Look for stamped codes with slash and alphanumeric like "2/U1D27B"
    final stampedBatch = RegExp(r'\b([0-9]\/[A-Z0-9]{5,10})\b').firstMatch(text);
    if (stampedBatch != null) {
      return stampedBatch.group(1);
    }

    // 3. Regex matching: "BATCH NO: B20491"
    final batchPattern = RegExp(
      r'(?:BATCH(?:\s*NO\.?|\s*NUM(?:BER)?)?|LOT(?:\s*NO\.?)?|B\.?\s*NO\.?|BN)[:\s\.\-]*([A-Z0-9\-\/]{3,18})\b',
      caseSensitive: false,
    );
    final match = batchPattern.firstMatch(text);
    if (match != null) {
      final code = match.group(1)?.trim();
      if (code != null && _isValidBatchCode(code)) {
        return code;
      }
    }

    return null;
  }

  static bool _isValidBatchCode(String code) {
    if (code.length < 3 || code.length > 20) return false;
    final upper = code.toUpperCase();
    const invalidWords = {
      'UNIT',
      'SALE',
      'PRICE',
      'DATE',
      'EXPIRY',
      'PACKAGE',
      'SERVING',
      'NET',
      'WEIGHT',
      'OTHER',
      'EACH',
      'TOTAL',
    };
    if (invalidWords.contains(upper)) return false;
    // Must contain at least one digit or slash
    if (!RegExp(r'[0-9\/]').hasMatch(code)) return false;
    return true;
  }

  /// Extracts primary product name and brand from lines of text when barcode is not found.
  static (String name, String? brand) extractNameAndBrand(List<String> lines) {
    final ignoredWords = RegExp(
      r'^(NET|WT|BATCH|EXP|MFG|MRP|BEST|BEFORE|USE|BY|INGREDIENTS|NUTRITIONAL|CONTAINS|PACKED|MANUFACTURED|STORE|KEEP|CUSTOMER|CARE|EMAIL|PHONE|WEBSITE|WWW|HTTP)',
      caseSensitive: false,
    );

    final candidateLines = lines.where((line) {
      final clean = line.trim();
      if (clean.length < 3) return false;
      if (ignoredWords.hasMatch(clean)) return false;
      if (RegExp(r'^\d+$').hasMatch(clean)) return false;
      return true;
    }).toList();

    if (candidateLines.isEmpty) {
      return ('Product from Photo', null);
    }

    final primaryName = candidateLines.first;
    String? brand;
    if (candidateLines.length > 1 && candidateLines[1].length > 2) {
      if (primaryName.split(' ').length <= 2 && candidateLines[1].length > primaryName.length) {
        brand = primaryName;
        return (candidateLines[1], brand);
      }
    }

    return (primaryName, brand);
  }

  /// Detects category from text keywords.
  static String detectCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('milk') ||
        lower.contains('cheese') ||
        lower.contains('butter') ||
        lower.contains('curd') ||
        lower.contains('yogurt') ||
        lower.contains('paneer') ||
        lower.contains('dairy')) {
      return 'Dairy';
    }
    if (lower.contains('tablet') ||
        lower.contains('capsule') ||
        lower.contains('syrup') ||
        lower.contains('pharma') ||
        lower.contains('mg') ||
        lower.contains('vitamin') ||
        lower.contains('paracetamol')) {
      return 'Health';
    }
    if (lower.contains('soap') ||
        lower.contains('detergent') ||
        lower.contains('cleaner') ||
        lower.contains('shampoo') ||
        lower.contains('wash')) {
      return 'Household';
    }
    if (lower.contains('appliance') ||
        lower.contains('battery') ||
        lower.contains('watt') ||
        lower.contains('voltage')) {
      return 'Appliances';
    }
    return 'Pantry';
  }
}
