import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/product.dart';

class ProductIcon extends StatelessWidget {
  const ProductIcon(this.product, {super.key, this.size = 48});

  final Product product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isService = product.service != null;
    final tint = isService ? const Color(0xFFE7ECFA) : const Color(0xFFE5F0E9);
    final icon = isService
        ? Icons.devices_other_rounded
        : switch (product.category) {
            'Dairy' => Icons.egg_alt_outlined,
            'Health' => Icons.medication_outlined,
            'Appliances' => Icons.ac_unit_rounded,
            _ => Icons.local_grocery_store_outlined,
          };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(size * .31),
      ),
      child: Icon(
        icon,
        color: isService ? const Color(0xFF5469AA) : brandGreen,
        size: size * .5,
      ),
    );
  }
}
