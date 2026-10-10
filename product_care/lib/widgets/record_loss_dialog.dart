import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../app/app_theme.dart';
import '../models/product.dart';

class AddStockResult {
  const AddStockResult({
    required this.quantity,
    required this.batchNumber,
    this.expiry,
    this.isNewBatch = false,
  });

  final int quantity;
  final String batchNumber;
  final DateTime? expiry;
  final bool isNewBatch;
}

class RecordLossResult {
  const RecordLossResult({
    required this.quantity,
    this.batchNumber,
  });

  final int quantity;
  final String? batchNumber;
}

Future<RecordLossResult?> showRecordLossDialog(
  BuildContext context,
  Product product,
) =>
    showDialog<RecordLossResult>(
      context: context,
      builder: (dialogContext) => _RecordLossDialog(product: product),
    );

class _RecordLossDialog extends StatefulWidget {
  const _RecordLossDialog({required this.product});

  final Product product;

  @override
  State<_RecordLossDialog> createState() => _RecordLossDialogState();
}

class _RecordLossDialogState extends State<_RecordLossDialog> {
  late final TextEditingController _controller;
  String? _selectedBatchNumber;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '1');
    final activeBatches =
        widget.product.batches.where((b) => b.quantity > 0).toList();
    if (activeBatches.isNotEmpty) {
      _selectedBatchNumber = activeBatches.first.batchNumber;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _maxAvailable {
    if (_selectedBatchNumber != null) {
      final b = widget.product.batches.where(
        (entry) => entry.batchNumber == _selectedBatchNumber,
      );
      if (b.isNotEmpty) return b.first.quantity;
    }
    return widget.product.quantity;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final activeBatches =
        product.batches.where((b) => b.quantity > 0).toList();

    return AlertDialog(
      title: Text(tr(context, 'Record stock loss')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, 'Available: {quantity} {unit}', {
                'quantity': product.quantity,
                'unit': product.unit,
              }),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (activeBatches.length > 1) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedBatchNumber,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr(context, 'Select batch'),
                  prefixIcon: const Icon(Icons.qr_code_2_rounded),
                ),
                items: activeBatches.map((b) {
                  final exp = b.expiry != null
                      ? ' · Exp: ${localizedFullDate(context, b.expiry!)}'
                      : '';
                  return DropdownMenuItem(
                    value: b.batchNumber,
                    child: Text(
                      '${b.batchNumber} (${b.quantity} ${tr(context, product.unit)}$exp)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBatchNumber = val);
                },
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: tr(context, 'Quantity to mark as lost'),
                suffixText: product.unit,
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: () {
            final quantity = int.tryParse(_controller.text);
            final max = _maxAvailable;
            if (quantity == null || quantity < 1 || quantity > max) {
              setState(() {
                _error = tr(context, 'Enter a quantity from 1 to {quantity}.', {
                  'quantity': max,
                });
              });
              return;
            }
            Navigator.pop(
              context,
              RecordLossResult(
                quantity: quantity,
                batchNumber: _selectedBatchNumber,
              ),
            );
          },
          child: Text(tr(context, 'Confirm loss')),
        ),
      ],
    );
  }
}

Future<AddStockResult?> showAddStockDialog(
  BuildContext context,
  Product product,
) =>
    showDialog<AddStockResult>(
      context: context,
      builder: (dialogContext) => _AddStockDialog(product: product),
    );

class _AddStockDialog extends StatefulWidget {
  const _AddStockDialog({required this.product});

  final Product product;

  @override
  State<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<_AddStockDialog> {
  late final TextEditingController _controller;
  late final String _newBatchNumber;
  late String _selectedBatchValue;
  DateTime? _newBatchExpiry;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '10');
    _newBatchNumber = generateNextBatchNumber(
      widget.product.name,
      widget.product.batches,
    );
    // If existing batches exist, default to the latest existing batch, or 'NEW'
    if (widget.product.batches.isNotEmpty) {
      _selectedBatchValue = widget.product.batches.last.batchNumber;
    } else {
      _selectedBatchValue = '__NEW__';
      _newBatchExpiry = widget.product.expiry;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isNewBatchSelected => _selectedBatchValue == '__NEW__';

  DateTime? get _effectiveExpiry {
    if (_isNewBatchSelected) return _newBatchExpiry;
    final b = widget.product.batches.where(
      (entry) => entry.batchNumber == _selectedBatchValue,
    );
    return b.isNotEmpty ? b.first.expiry : null;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isStorable = product.kind == ProductKind.storable;

    return AlertDialog(
      title: Text(tr(context, 'Add stock')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, 'Current stock: {quantity} {unit}', {
                'quantity': product.quantity,
                'unit': product.unit,
              }),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (isStorable) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedBatchValue,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr(context, 'Batch'),
                  prefixIcon: const Icon(Icons.inventory_rounded),
                ),
                items: [
                  ...product.batches.map((b) => DropdownMenuItem(
                        value: b.batchNumber,
                        child: Text(
                          '${b.batchNumber} (${b.quantity} ${tr(context, product.unit)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                  DropdownMenuItem(
                    value: '__NEW__',
                    child: Text(
                      '+ ${tr(context, 'New batch')}: $_newBatchNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: brandGreen,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedBatchValue = val;
                      if (val == '__NEW__') {
                        _newBatchExpiry = null;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              if (_isNewBatchSelected)
                _dateSelector(
                  title: tr(context, 'New batch expiry date'),
                  date: _newBatchExpiry,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _newBatchExpiry ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setState(() => _newBatchExpiry = picked);
                    }
                  },
                )
              else if (_effectiveExpiry != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_available_outlined,
                        size: 16,
                        color: brandGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${tr(context, 'Batch expiry')}: ${localizedFullDate(context, _effectiveExpiry!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: brandGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: tr(context, 'Quantity to add'),
                suffixText: product.unit,
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: () {
            final quantity = int.tryParse(_controller.text);
            if (quantity == null || quantity < 1) {
              setState(() {
                _error = tr(context, 'Enter a valid positive quantity.');
              });
              return;
            }

            final batchCode = _isNewBatchSelected
                ? _newBatchNumber
                : _selectedBatchValue;

            Navigator.pop(
              context,
              AddStockResult(
                quantity: quantity,
                batchNumber: batchCode,
                expiry: _effectiveExpiry,
                isNewBatch: _isNewBatchSelected,
              ),
            );
          },
          child: Text(tr(context, 'Add stock')),
        ),
      ],
    );
  }

  Widget _dateSelector({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.event_outlined),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  date == null
                      ? tr(context, 'Choose expiry date')
                      : localizedFullDate(context, date),
                ),
              ),
            ),
          ),
        ],
      );
}
