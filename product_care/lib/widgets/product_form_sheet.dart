import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/date_formatters.dart';

class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({super.key});

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _cost = TextEditingController();
  String _category = 'Pantry';
  String _kind = 'Expirable';
  DateTime? _date;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _quantity.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      14,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Add a product',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Product name *',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _brand,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Brand or manufacturer',
              prefixIcon: Icon(Icons.sell_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items:
                      const [
                            'Pantry',
                            'Dairy',
                            'Health',
                            'Household',
                            'Appliances',
                            'Other',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'Other'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: 'Product type'),
                  items: const ['Expirable', 'Service', 'General']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _kind = value ?? 'Expirable'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Unit cost (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
              ),
            ],
          ),
          if (_kind != 'General') ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _date == null
                    ? (_kind == 'Service'
                          ? 'Choose next service date'
                          : 'Choose expiry date')
                    : formatFullDate(_date!),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save product'),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => _date = date);
  }

  void _save() {
    final quantity = int.tryParse(_quantity.text);
    if (_name.text.trim().isEmpty || quantity == null || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a name and a valid quantity.')),
      );
      return;
    }
    final kind = switch (_kind) {
      'Service' => ProductKind.service,
      'General' => ProductKind.general,
      _ => ProductKind.expiry,
    };
    Navigator.pop(
      context,
      Product(
        name: _name.text.trim(),
        brand: _brand.text.trim().isEmpty ? 'Unbranded' : _brand.text.trim(),
        category: _category,
        quantity: quantity,
        unit: 'units',
        expiry: kind == ProductKind.expiry ? _date : null,
        service: kind == ProductKind.service ? _date : null,
        cost: double.tryParse(_cost.text) ?? 0,
        kind: kind,
      ),
    );
  }
}
