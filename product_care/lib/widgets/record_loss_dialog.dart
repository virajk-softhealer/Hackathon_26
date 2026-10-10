import 'package:flutter/material.dart';

import '../models/product.dart';

Future<int?> showRecordLossDialog(BuildContext context, Product product) {
  final controller = TextEditingController(text: '1');
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Record stock loss'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available: ${product.quantity} ${product.unit}'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantity to mark as lost',
              suffixText: product.unit,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final quantity = int.tryParse(controller.text);
            if (quantity == null ||
                quantity < 1 ||
                quantity > product.quantity) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Enter a quantity from 1 to ${product.quantity}.',
                  ),
                ),
              );
              return;
            }
            Navigator.pop(dialogContext, quantity);
          },
          child: const Text('Confirm loss'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}
