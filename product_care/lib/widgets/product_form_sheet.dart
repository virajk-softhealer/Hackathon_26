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
  static const _predefinedUnits = [
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
    'custom',
  ];

  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _quantity;
  late final TextEditingController _cost;
  late final TextEditingController _customUnit;
  late String _category;
  late String _kind;
  late String _selectedUnit;
  DateTime? _expiry;
  DateTime? _service;
  DateTime? _warranty;

  String? _nameError;
  String? _quantityError;
  String? _costError;

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

    final initialUnit = product?.unit ?? 'units';
    if (_predefinedUnits.contains(initialUnit) && initialUnit != 'custom') {
      _selectedUnit = initialUnit;
      _customUnit = TextEditingController();
    } else {
      _selectedUnit = 'custom';
      _customUnit = TextEditingController(text: initialUnit);
    }

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
    _customUnit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                tooltip: tr(context, 'Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
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
                  decoration: InputDecoration(
                    labelText: tr(context, 'Category'),
                  ),
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
                  decoration: InputDecoration(
                    labelText: tr(context, 'Product type'),
                  ),
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
                      labelText: tr(context, 'Quantity *'),
                      prefixIcon: const Icon(Icons.numbers),
                      errorText: _quantityError,
                    ),
                    onChanged: (_) {
                      if (_quantityError != null) {
                        setState(() => _quantityError = null);
                      }
                    },
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
                      errorText: _costError,
                    ),
                    onChanged: (_) {
                      if (_costError != null) {
                        setState(() => _costError = null);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedUnit,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: tr(context, 'Unit of measure (UOM)'),
                prefixIcon: const Icon(Icons.straighten_rounded),
              ),
              items: _predefinedUnits
                  .map((unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(
                          unit == 'custom'
                              ? tr(context, 'Custom unit...')
                              : tr(context, unit),
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() {
                _selectedUnit = value ?? 'units';
              }),
            ),
            if (_selectedUnit == 'custom') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customUnit,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: tr(context, 'Enter custom UOM'),
                  hintText: 'e.g. cans, rolls, strips',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                ),
              ),
            ],
          ],
          if (_kind == 'Storable') ...[
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 8),
            _dateButton(
              label: 'Choose expiration / contract end date',
              date: _expiry,
              onTap: () => _pickDate(
                _expiry,
                (date) => _expiry = date,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: tr(context, 'Service / Contract cost (₹)'),
                prefixIcon: const Icon(Icons.currency_rupee),
                errorText: _costError,
              ),
              onChanged: (_) {
                if (_costError != null) setState(() => _costError = null);
              },
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr(context, 'Cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
              date == null
                  ? tr(context, label)
                  : localizedFullDate(context, date),
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
    var hasError = false;

    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = tr(context, 'Product name is required.'));
      hasError = true;
    }

    int? quantity;
    if (_kind != 'Service') {
      quantity = int.tryParse(_quantity.text.trim());
      if (quantity == null || quantity < 0) {
        setState(() {
          _quantityError = tr(context, 'Enter a valid non-negative quantity.');
        });
        hasError = true;
      }
    } else {
      quantity = 0;
    }

    double cost = 0;
    if (_cost.text.trim().isNotEmpty) {
      final parsedCost = double.tryParse(_cost.text.trim());
      if (parsedCost == null || parsedCost < 0) {
        setState(() => _costError = tr(context, 'Cost cannot be negative.'));
        hasError = true;
      } else {
        cost = parsedCost;
      }
    }

    if (hasError) return;

    final kind = switch (_kind) {
      'Service' => ProductKind.service,
      'General' => ProductKind.general,
      _ => ProductKind.storable,
    };

    String finalUnit;
    if (kind == ProductKind.service) {
      finalUnit = 'unit';
    } else if (_selectedUnit == 'custom') {
      final custom = _customUnit.text.trim();
      finalUnit = custom.isNotEmpty ? custom : 'units';
    } else {
      finalUnit = _selectedUnit;
    }

    final old = widget.product;
    Navigator.pop(
      context,
      Product(
        id: old?.id,
        name: _name.text.trim(),
        brand: _brand.text.trim().isEmpty ? 'Unbranded' : _brand.text.trim(),
        category: _category,
        quantity: quantity ?? 0,
        unit: finalUnit,
        expiry: _expiry,
        service: kind == ProductKind.service ? _service : null,
        warranty: kind == ProductKind.service ? _warranty : null,
        cost: cost,
        kind: kind,
      ),
    );
  }
}
