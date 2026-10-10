import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../models/product.dart';

Future<int?> showRecordLossDialog(BuildContext context, Product product) =>
    showDialog<int>(
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return AlertDialog(
      title: Text(tr(context, 'Record stock loss')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'Available: {quantity} {unit}', {
              'quantity': product.quantity,
              'unit': product.unit,
            }),
          ),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: () {
            final quantity = int.tryParse(_controller.text);
            if (quantity == null ||
                quantity < 1 ||
                quantity > product.quantity) {
              setState(() {
                _error = tr(context, 'Enter a quantity from 1 to {quantity}.', {
                  'quantity': product.quantity,
                });
              });
              return;
            }
            Navigator.pop(context, quantity);
          },
          child: Text(tr(context, 'Confirm loss')),
        ),
      ],
    );
  }
}

Future<int?> showAddStockDialog(BuildContext context, Product product) =>
    showDialog<int>(
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return AlertDialog(
      title: Text(tr(context, 'Add stock')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'Current stock: {quantity} {unit}', {
              'quantity': product.quantity,
              'unit': product.unit,
            }),
          ),
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
            Navigator.pop(context, quantity);
          },
          child: Text(tr(context, 'Add stock')),
        ),
      ],
    );
  }
}
