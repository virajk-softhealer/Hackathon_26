import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../models/product.dart';

Future<int?> showRecordLossDialog(BuildContext context, Product product) {
  final controller = TextEditingController(text: '1');
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
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
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: tr(context, 'Quantity to mark as lost'),
              suffixText: product.unit,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(tr(context, 'Cancel')),
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
                    tr(context, 'Enter a quantity from 1 to {quantity}.', {
                      'quantity': product.quantity,
                    }),
                  ),
                ),
              );
              return;
            }
            Navigator.pop(dialogContext, quantity);
          },
          child: Text(tr(context, 'Confirm loss')),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}
