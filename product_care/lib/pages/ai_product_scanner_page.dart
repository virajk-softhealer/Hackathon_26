import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_localizations.dart';
import '../app/app_theme.dart';
import '../services/ai_ocr_service.dart';

class AiProductScannerPage extends StatefulWidget {
  const AiProductScannerPage({super.key});

  @override
  State<AiProductScannerPage> createState() => _AiProductScannerPageState();
}

class _AiProductScannerPageState extends State<AiProductScannerPage> {
  final ImagePicker _picker = ImagePicker();
  final List<AiOcrProductItem> _scannedItems = [];
  bool _isProcessing = false;
  String? _processingStatus;

  Future<void> _takePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
      );
      if (picked == null) return;

      await _processImageFile(File(picked.path));
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Camera error: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final pickedList = await _picker.pickMultiImage(imageQuality: 92);
      if (pickedList.isEmpty) return;

      setState(() {
        _isProcessing = true;
        _processingStatus = 'Processing ${pickedList.length} photo(s)...';
      });

      for (var i = 0; i < pickedList.length; i++) {
        final file = File(pickedList[i].path);
        setState(() {
          _processingStatus = 'Analyzing photo ${i + 1} of ${pickedList.length}...';
        });
        final result = await AiOcrService.processImage(file);
        // Insert at index 0 so newest appears at top!
        _scannedItems.insert(0, result);
        HapticFeedback.lightImpact();
      }

      setState(() {
        _isProcessing = false;
        _processingStatus = null;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processingStatus = null;
      });
      if (mounted) {
        _showErrorSnackBar('Gallery error: $e');
      }
    }
  }

  Future<void> _processImageFile(File file) async {
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Analyzing text and expiry date...';
    });

    final result = await AiOcrService.processImage(file);
    HapticFeedback.mediumImpact();

    setState(() {
      // Latest item appears on top!
      _scannedItems.insert(0, result);
      _isProcessing = false;
      _processingStatus = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _editExpiryDate(AiOcrProductItem item) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: item.expiry ?? now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => item.expiry = picked);
    }
  }

  void _editName(AiOcrProductItem item) async {
    final controller = TextEditingController(text: item.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Edit product name')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: tr(ctx, 'Product name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(ctx, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(ctx, 'Done')),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      setState(() => item.name = controller.text.trim());
    }
  }

  void _confirmAndReturn() {
    Navigator.pop(context, _scannedItems);
  }

  @override
  Widget build(BuildContext context) {
    const aiColor = Color(0xFF7C3AED);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: aiColor.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: aiColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'AI Product Scanner'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    tr(context, 'Auto-detect expiry, weight & batch'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_scannedItems.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _scannedItems.clear()),
              child: Text(
                tr(context, 'Clear all'),
                style: const TextStyle(color: Color(0xFFC04434), fontSize: 13),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Top Action Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: .4),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: aiColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isProcessing ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt_rounded, size: 20),
                    label: Text(
                      tr(context, 'Take Photo'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: aiColor,
                      side: const BorderSide(color: aiColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isProcessing ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library_rounded, size: 20),
                    label: Text(
                      tr(context, 'From Gallery'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Processing progress indicator
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: aiColor.withValues(alpha: .08),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(aiColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _processingStatus ?? tr(context, 'Processing...'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: aiColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Scanned Items List or Empty State
          Expanded(
            child: _scannedItems.isEmpty
                ? _buildEmptyState(context, aiColor)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: _scannedItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _scannedItems[index];
                      return _buildProductCard(context, item, index, aiColor);
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: _scannedItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _confirmAndReturn,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(
                      tr(
                        context,
                        'Confirm & Add ({count} products)',
                        {'count': _scannedItems.length},
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    AiOcrProductItem item,
    int index,
    Color aiColor,
  ) =>
      Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: aiColor.withValues(alpha: .2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  item.imageFile,
                  width: 74,
                  height: 74,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              // Product Info & Chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _editName(item),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.grey,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              setState(() => _scannedItems.removeAt(index)),
                        ),
                      ],
                    ),
                    if (item.brand != null && item.brand!.isNotEmpty)
                      Text(
                        item.brand!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 6),

                    // Detected metadata chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Expiry Chip
                        GestureDetector(
                          onTap: () => _editExpiryDate(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: item.expiry != null
                                  ? const Color(0xFFE28A37).withValues(alpha: .15)
                                  : Colors.grey.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event_rounded,
                                  size: 12,
                                  color: item.expiry != null
                                      ? const Color(0xFFE28A37)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.expiry != null
                                      ? 'Exp: ${item.expiry!.year}-${item.expiry!.month.toString().padLeft(2, '0')}-${item.expiry!.day.toString().padLeft(2, '0')}'
                                      : 'Set Expiry',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: item.expiry != null
                                        ? const Color(0xFFE28A37)
                                        : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Weight & Unit Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3E7BDB).withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.quantity} ${item.unit}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3E7BDB),
                            ),
                          ),
                        ),

                        // Batch Chip (if detected)
                        if (item.batchNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF278765).withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Batch: ${item.batchNumber}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF278765),
                              ),
                            ),
                          ),

                        // MRP Chip (if detected)
                        if (item.cost > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: aiColor.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'MRP: ₹${item.cost.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: aiColor,
                              ),
                            ),
                          ),

                        // Barcode Chip (if detected from photo)
                        if (item.barcode != null && item.barcode!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.qr_code_rounded,
                                  size: 11,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.barcode!,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context, Color aiColor) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      aiColor.withValues(alpha: .15),
                      brandGreen.withValues(alpha: .15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 44,
                  color: aiColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr(context, 'Smart Photo OCR Scanner'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  context,
                  'Take photos of product labels, expiry dates, and weights. AI extracts details on-device and lets you confirm multiple products at once.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: .45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _tipRow(
                        Icons.calendar_today_rounded,
                        tr(context, 'Auto-detects EXP, USE BY, and BB dates'),
                      ),
                      const SizedBox(height: 10),
                      _tipRow(
                        Icons.scale_rounded,
                        tr(context, 'Extracts Net Wt (e.g. 48 g, 500 mL)'),
                      ),
                      const SizedBox(height: 10),
                      _tipRow(
                        Icons.photo_library_outlined,
                        tr(context, 'Snap multiple photos and confirm together'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _tipRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );
}
