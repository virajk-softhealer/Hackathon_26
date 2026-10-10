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
          _processingStatus =
              'Analyzing photo ${i + 1} of ${pickedList.length}...';
        });
        final result = await AiOcrService.processImage(file);
        // Insert at index 0 so newest appears on top!
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
      _processingStatus = 'Scanning barcode, text & expiry date...';
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

  void _openEditDetailsSheet(AiOcrProductItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditProductDetailsModal(
        item: item,
        onSaved: () => setState(() {}),
      ),
    );
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
                    tr(context, 'Smart Scan'),
                    style: const TextStyle(
                      fontSize: 16,
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
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: tr(context, 'Select from gallery'),
            onPressed: _isProcessing ? null : _pickFromGallery,
          ),
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
          // Processing progress banner
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: aiColor.withValues(alpha: .08),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
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
                        fontSize: 12.5,
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: _scannedItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _scannedItems[index];
                      return _buildProductCard(context, item, index, aiColor);
                    },
                  ),
          ),
        ],
      ),
      // WhatsApp-style Bottom Action Bar with circular + button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: _scannedItems.isEmpty
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Material(
                      color: const Color(0xFF25D366), // WhatsApp vibrant green
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isProcessing ? null : _takePhoto,
                        child: Container(
                          width: 58,
                          height: 58,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // WhatsApp-style '+' Camera Button to snap more products
                    Material(
                      color: const Color(0xFF25D366), // WhatsApp vibrant green
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isProcessing ? null : _takePhoto,
                        child: Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confirm & Add Products Button
                    Expanded(
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
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    AiOcrProductItem item,
    int index,
    Color aiColor,
  ) =>
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: aiColor.withValues(alpha: .22),
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      item.imageFile,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Product Info & Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
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
                        if (item.brand != null && item.brand!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.brand!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${tr(context, item.category)} • ${item.quantity} ${localizedUnit(context, item.unit)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: .8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Chips for Expiry, Cost, Batch, Barcode
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Expiry Chip (tap to quick change date)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _editExpiryDate(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                            size: 13,
                            color: item.expiry != null
                                ? const Color(0xFFE28A37)
                                : Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.expiry != null
                                ? 'Exp: ${item.expiry!.year}-${item.expiry!.month.toString().padLeft(2, '0')}-${item.expiry!.day.toString().padLeft(2, '0')}'
                                : 'Set Expiry',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: item.expiry != null
                                  ? const Color(0xFFE28A37)
                                  : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.edit_outlined,
                            size: 11,
                            color: Color(0xFFE28A37),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // MRP / Price Chip
                  if (item.cost > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: aiColor.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'MRP: ₹${item.cost.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: aiColor,
                        ),
                      ),
                    ),

                  // Batch Chip
                  if (item.batchNumber != null &&
                      item.batchNumber!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF278765).withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Batch: ${item.batchNumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF278765),
                        ),
                      ),
                    ),

                  // Barcode Chip
                  if (item.barcode != null && item.barcode!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                            size: 12,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.barcode!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Full Edit Details Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: aiColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  onPressed: () => _openEditDetailsSheet(item),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: Text(
                    tr(context, 'Edit All Details'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context, Color aiColor) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      aiColor.withValues(alpha: .18),
                      brandGreen.withValues(alpha: .18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 44,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr(context, 'Smart Scan'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF242728)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: .5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: .15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo_rounded,
                        color: Color(0xFF25D366),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        tr(
                          context,
                          'Currently no product scanned. Use the + icon to scan your product.',
                        ),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _EditProductDetailsModal extends StatefulWidget {
  const _EditProductDetailsModal({
    required this.item,
    required this.onSaved,
  });

  final AiOcrProductItem item;
  final VoidCallback onSaved;

  @override
  State<_EditProductDetailsModal> createState() =>
      _EditProductDetailsModalState();
}

class _EditProductDetailsModalState extends State<_EditProductDetailsModal> {
  static const _predefinedUnits = [
    'units',
    'pieces',
    'g',
    'kg',
    'mL',
    'L',
    'packets',
    'bottles',
    'boxes',
    'bags',
    'other',
  ];

  static const _predefinedCategories = [
    'Pantry',
    'Dairy',
    'Health',
    'Household',
    'Snacks',
    'Beverages',
    'Bakery',
    'Appliances',
    'Other',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _quantityController;
  late final TextEditingController _costController;
  late final TextEditingController _batchController;
  late final TextEditingController _barcodeController;
  late String _category;
  late String _unit;
  DateTime? _expiry;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item.name);
    _brandController = TextEditingController(text: item.brand ?? '');
    _quantityController = TextEditingController(text: '${item.quantity}');
    _costController = TextEditingController(
      text: item.cost > 0 ? item.cost.toStringAsFixed(2) : '',
    );
    _batchController = TextEditingController(text: item.batchNumber ?? '');
    _barcodeController = TextEditingController(text: item.barcode ?? '');

    _category = _predefinedCategories.contains(item.category)
        ? item.category
        : 'Other';

    _unit = _predefinedUnits.contains(item.unit) ? item.unit : 'units';

    _expiry = item.expiry;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _batchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _save() {
    final item = widget.item;
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      item.name = name;
    }
    final brand = _brandController.text.trim();
    item.brand = brand.isNotEmpty ? brand : null;
    item.category = _category;
    item.quantity =
        int.tryParse(_quantityController.text.trim()) ?? item.quantity;
    item.unit = _unit;
    item.cost = double.tryParse(_costController.text.trim()) ?? item.cost;
    final batch = _batchController.text.trim();
    item.batchNumber = batch.isNotEmpty ? batch : null;
    final barcode = _barcodeController.text.trim();
    item.barcode = barcode.isNotEmpty ? barcode : null;
    item.expiry = _expiry;

    widget.onSaved();
    Navigator.pop(context);
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expiry = picked);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr(context, 'Edit Scanned Product'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Product Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: tr(context, 'Product Name'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Brand & Category Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: tr(context, 'Brand'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: tr(context, 'Category'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _predefinedCategories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(tr(context, c)),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _category = val ?? 'Other'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quantity & Unit Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr(context, 'Quantity'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: InputDecoration(
                        labelText: tr(context, 'Unit'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _predefinedUnits
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(localizedUnit(context, u)),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _unit = val ?? 'units'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Expiry Date Picker Tile
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.event_rounded, color: Color(0xFFE28A37)),
                  title: Text(
                    _expiry != null
                        ? '${tr(context, 'Expiry')}: ${_expiry!.year}-${_expiry!.month.toString().padLeft(2, '0')}-${_expiry!.day.toString().padLeft(2, '0')}'
                        : tr(context, 'Select Expiry Date'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.calendar_month_rounded),
                  onTap: _pickExpiry,
                ),
              ),
              const SizedBox(height: 12),

              // Price / MRP & Batch Number Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _costController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: tr(context, 'Price / MRP (₹)'),
                        prefixText: '₹ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _batchController,
                      decoration: InputDecoration(
                        labelText: tr(context, 'Batch Number'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Barcode Field
              TextField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: tr(context, 'Barcode'),
                  prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _save,
                  child: Text(
                    tr(context, 'Save Details'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
