import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../models/product.dart';

class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({
    this.product,
    this.renewWarranty = false,
    super.key,
  });

  final Product? product;
  final bool renewWarranty;

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  static const _units = [
    'units',
    'pieces',
    'kg',
    'g',
    'L',
    'mL',
    'packets',
    'bottles',
    'boxes',
    'bags',
    'dozen',
    'sets',
  ];

  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _quantity;
  late final TextEditingController _cost;
  late String _category;
  late String _kind;
  late String _unit;
  DateTime? _expiry;
  DateTime? _service;
  DateTime? _warranty;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _brand = TextEditingController(
      text: product == null || product.brand == 'Unbranded'
          ? ''
          : product.brand,
    );
    _quantity = TextEditingController(text: '${product?.quantity ?? 1}');
    _cost = TextEditingController(
      text: product == null || product.cost == 0 ? '' : '${product.cost}',
    );
    _category = product?.category ?? 'Pantry';
    _kind = switch (product?.kind) {
      ProductKind.service => 'Service',
      ProductKind.general => 'General',
      _ => 'Storable',
    };
    _unit = _units.contains(product?.unit) ? product!.unit : 'units';
    _expiry = product?.expiry;
    _service = product?.service;
    _warranty = product?.warranty;
  }

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
              Text(
                tr(
                  context,
                  widget.renewWarranty
                      ? 'Renew warranty for {name}'
                      : _isEditing
                          ? 'Edit product'
                          : 'Add a product',
                  {'name': widget.product?.name ?? ''},
                ),
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: tr(context, 'Product name *'),
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _brand,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: tr(context, 'Brand or manufacturer'),
                  prefixIcon: const Icon(Icons.sell_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: tr(context, 'Category')),
                      items: const [
                        'Pantry',
                        'Dairy',
                        'Health',
                        'Household',
                        'Appliances',
                        'Other',
                      ]
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(tr(context, value)),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _category = value ?? 'Other'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _kind,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: tr(context, 'Product type')),
                      items: const ['Storable', 'Service', 'General']
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(tr(context, value)),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _kind = value ?? 'Storable';
                      }),
                    ),
                  ),
                ],
              ),
              if (_kind != 'Service') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantity,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: tr(context, 'Quantity'),
                          prefixIcon: const Icon(Icons.numbers),
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
                        decoration: InputDecoration(
                          labelText: tr(context, 'Unit cost (₹)'),
                          prefixIcon: const Icon(Icons.currency_rupee),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _unit,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: tr(context, 'Unit of measure'),
                    prefixIcon: const Icon(Icons.straighten_rounded),
                  ),
                  items: _units
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(tr(context, unit)),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _unit = value ?? 'units'),
                ),
              ],
              if (_kind == 'Storable') ...[
                const SizedBox(height: 8),
                _dateButton(
                  label: 'Choose expiry date',
                  date: _expiry,
                  onTap: () => _pickDate(
                    _expiry,
                    (date) => _expiry = date,
                  ),
                ),
              ],
              if (_kind == 'Service') ...[
                const SizedBox(height: 8),
                _dateButton(
                  label: 'Choose next service date',
                  date: _service,
                  onTap: () => _pickDate(
                    _service,
                    (date) => _service = date,
                  ),
                ),
                const SizedBox(height: 8),
                _dateButton(
                  label: widget.renewWarranty
                      ? 'Choose new warranty expiry date'
                      : 'Choose warranty expiry date',
                  date: _warranty,
                  onTap: () => _pickDate(
                    _warranty,
                    (date) => _warranty = date,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(
                    tr(
                      context,
                      widget.renewWarranty
                          ? 'Save warranty'
                          : _isEditing
                              ? 'Save changes'
                              : 'Save product',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _dateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.event_outlined),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              date == null ? tr(context, label) : localizedFullDate(context, date),
              textAlign: TextAlign.left,
            ),
          ),
        ),
      );

  Future<void> _pickDate(
    DateTime? current,
    ValueChanged<DateTime> onSelected,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => onSelected(date));
  }

  void _save() {
    final quantity = int.tryParse(_quantity.text);
    if (_name.text.trim().isEmpty ||
        (_kind != 'Service' && (quantity == null || quantity < 0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'Add a name and a valid quantity.'))),
      );
      return;
    }
    final kind = switch (_kind) {
      'Service' => ProductKind.service,
      'General' => ProductKind.general,
      _ => ProductKind.storable,
    };
    final old = widget.product;
    Navigator.pop(
      context,
      Product(
        id: old?.id,
        name: _name.text.trim(),
        brand: _brand.text.trim().isEmpty ? 'Unbranded' : _brand.text.trim(),
        category: _category,
        quantity: kind == ProductKind.service ? 0 : quantity!,
        unit: kind == ProductKind.service ? 'unit' : _unit,
        expiry: kind == ProductKind.storable ? _expiry : null,
        service: kind == ProductKind.service ? _service : null,
        warranty: kind == ProductKind.service ? _warranty : null,
        cost: kind == ProductKind.service
            ? 0
            : double.tryParse(_cost.text) ?? 0,
        kind: kind,
      ),
    );
  }
}
