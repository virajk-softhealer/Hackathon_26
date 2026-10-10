import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../models/product.dart';

class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({
    this.product,
    this.existingNames = const [],
    super.key,
  });

  final Product? product;
  final List<String> existingNames;

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
    'other',
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
  DateTime? _serviceEnd;

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
    if (_predefinedUnits.contains(initialUnit) && initialUnit != 'other') {
      _selectedUnit = initialUnit;
      _customUnit = TextEditingController();
    } else {
      _selectedUnit = 'other';
      _customUnit = TextEditingController(
        text: initialUnit == 'other' ? '' : initialUnit,
      );
    }

    _expiry = product?.expiry;
    _service = product?.serviceStartDate;
    _serviceEnd = product?.serviceEndDate;
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
              _isEditing ? 'Edit product' : 'Add a product',
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
                          unit == 'other'
                              ? tr(context, 'Other')
                              : tr(context, unit),
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() {
                _selectedUnit = value ?? 'units';
              }),
            ),
            if (_selectedUnit == 'other') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customUnit,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: tr(context, 'Enter other UOM'),
                  hintText: 'e.g. cans, rolls, strips',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                ),
              ),
            ],
          ],
          if (_kind == 'Storable') ...[
            const SizedBox(height: 10),
            _dateButton(
              title: tr(context, 'Expiry date'),
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
              title: tr(context, 'Service start'),
              label: 'Choose service start date',
              date: _service,
              onTap: () => _pickDate(
                _service,
                (date) => _service = date,
              ),
            ),
            const SizedBox(height: 8),
            _dateButton(
              title: tr(context, 'Service end'),
              label: 'Choose service end date',
              date: _serviceEnd,
              onTap: () => _pickDate(
                _serviceEnd,
                (date) => _serviceEnd = date,
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
                      _isEditing ? 'Save changes' : 'Save product',
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
    required String title,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
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
                        ? tr(context, label)
                        : localizedFullDate(context, date),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),
          ],
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

    final trimmedName = _name.text.trim();
    if (trimmedName.isEmpty) {
      setState(() => _nameError = tr(context, 'Product name is required.'));
      hasError = true;
    } else {
      final lowerName = trimmedName.toLowerCase();
      final isDuplicate = widget.existingNames.any((existing) {
        if (widget.product != null &&
            widget.product!.name.trim().toLowerCase() == lowerName) {
          return false;
        }
        return existing.trim().toLowerCase() == lowerName;
      });
      if (isDuplicate) {
        setState(() => _nameError =
            tr(context, 'A product with this name already exists.'));
        hasError = true;
      }
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
    } else if (_selectedUnit == 'other') {
      final custom = _customUnit.text.trim();
      finalUnit = custom.isNotEmpty ? custom : 'units';
    } else {
      finalUnit = _selectedUnit;
    }

    final old = widget.product;
    final batches = <ProductBatch>[];
    if (kind == ProductKind.storable) {
      if (old != null && old.batches.isNotEmpty) {
        batches.addAll(old.batches);
      } else if ((quantity ?? 0) > 0 || _expiry != null) {
        batches.add(ProductBatch(
          batchNumber: generateNextBatchNumber(_name.text.trim(), []),
          quantity: quantity ?? 0,
          expiry: _expiry,
        ));
      }
    }

    Navigator.pop(
      context,
      Product(
        id: old?.id,
        name: _name.text.trim(),
        brand: _brand.text.trim(),
        category: _category,
        quantity: quantity ?? 0,
        unit: finalUnit,
        expiry: kind == ProductKind.storable ? _expiry : null,
        service: kind == ProductKind.service ? _service : null,
        serviceEnd: kind == ProductKind.service ? _serviceEnd : null,
        cost: cost,
        kind: kind,
        batches: batches,
      ),
    );
  }
}
