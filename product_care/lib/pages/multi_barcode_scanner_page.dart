import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app/app_localizations.dart';
import '../app/app_theme.dart';
import '../models/product.dart';
import '../services/open_food_facts_service.dart';

class ScannedBarcodeItem {
  ScannedBarcodeItem({
    required this.code,
    this.quantity = 1,
    this.matchedProduct,
    this.foodFactsResult,
  });

  final String code;
  int quantity;
  final Product? matchedProduct;
  OpenFoodFactsResult? foodFactsResult;
}

class MultiBarcodeScannerPage extends StatefulWidget {
  const MultiBarcodeScannerPage({
    required this.existingProducts,
    super.key,
  });

  final List<Product> existingProducts;

  @override
  State<MultiBarcodeScannerPage> createState() =>
      _MultiBarcodeScannerPageState();
}

class _MultiBarcodeScannerPageState extends State<MultiBarcodeScannerPage> {
  late final MobileScannerController _controller;
  final Map<String, ScannedBarcodeItem> _scannedMap = {};
  bool _isTorchOn = false;
  bool _sheetExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    var addedAny = false;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code == null || code.isEmpty) continue;

      if (_scannedMap.containsKey(code)) {
        // Already detected, keep existing
      } else {
        Product? match;
        for (final p in widget.existingProducts) {
          if (p.name.trim().toLowerCase() == code.toLowerCase() ||
              p.batches.any((b) => b.batchNumber.toLowerCase() == code.toLowerCase())) {
            match = p;
            break;
          }
        }
        final newItem = ScannedBarcodeItem(
          code: code,
          quantity: 1,
          matchedProduct: match,
        );
        _scannedMap[code] = newItem;
        addedAny = true;

        if (match == null) {
          OpenFoodFactsService.lookupBarcode(code).then((result) {
            if (mounted && result.found) {
              newItem.foodFactsResult = result;
              setState(() {});
            }
          });
        }
      }
    }

    if (addedAny) {
      HapticFeedback.mediumImpact();
      setState(() {});
    }
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  void _switchCamera() async {
    await _controller.switchCamera();
  }

  void _confirmAndReturn() {
    Navigator.pop(context, _scannedMap.values.toList());
  }

  @override
  Widget build(BuildContext context) {
    final scannedList = _scannedMap.values.toList();
    final totalCount =
        scannedList.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: .7),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, 'Multi-Barcode Scanner'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              tr(context, 'Scan up to multiple barcodes at once'),
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? Colors.amber : Colors.white,
            ),
            tooltip: tr(context, 'Flashlight'),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            tooltip: tr(context, 'Flip camera'),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Center target frame
          Center(
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.85,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: brandGreen.withValues(alpha: .7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tr(context, 'Align barcodes inside frame'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top badge showing total detected barcodes
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: brandGreen,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr(
                        context,
                        '{count} barcodes detected',
                        {'count': _scannedMap.length},
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom drawer / preview sheet of scanned barcodes
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: _sheetExpanded
                    ? MediaQuery.sizeOf(context).height * 0.65
                    : 230,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .25),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _sheetExpanded = !_sheetExpanded),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: .8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        tr(context, 'Scanned items ({count})', {
                          'count': _scannedMap.length,
                        }),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (_scannedMap.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              setState(() => _scannedMap.clear()),
                          child: Text(
                            tr(context, 'Clear all'),
                            style: const TextStyle(
                              color: Color(0xFFC04434),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (scannedList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          tr(
                            context,
                            'Point camera at barcodes to detect them simultaneously.',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: scannedList.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 8, endIndent: 8),
                        itemBuilder: (context, index) {
                          final item = scannedList[index];
                          final matched = item.matchedProduct;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (matched != null
                                            ? brandGreen
                                            : const Color(0xFF3E7BDB))
                                        .withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    matched != null
                                        ? Icons.check_circle_outline
                                        : Icons.qr_code_2_rounded,
                                    size: 18,
                                    color: matched != null
                                        ? brandGreen
                                        : const Color(0xFF3E7BDB),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        matched?.name ??
                                            (item.foodFactsResult?.name?.isNotEmpty == true
                                                ? item.foodFactsResult!.name!
                                                : item.code),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (matched != null)
                                        Text(
                                          'Code: ${item.code} · In stock: ${matched.quantity} ${matched.unit}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        )
                                      else if (item.foodFactsResult?.found == true)
                                        Text(
                                          '${item.foodFactsResult!.brand?.isNotEmpty == true ? '${item.foodFactsResult!.brand} · ' : ''}Open Food Facts (${item.code})',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Code: ${item.code}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: () {
                                        if (item.quantity > 1) {
                                          setState(() => item.quantity--);
                                        } else {
                                          setState(() => _scannedMap.remove(item.code));
                                        }
                                      },
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      onPressed: () =>
                                          setState(() => item.quantity++),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => setState(
                                        () => _scannedMap.remove(item.code),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _scannedMap.isNotEmpty ? _confirmAndReturn : null,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        tr(
                          context,
                          'Confirm & Add ({count} items)',
                          {'count': totalCount},
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
