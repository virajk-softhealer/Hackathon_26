import 'package:flutter/material.dart';

import '../pages/product_care_home.dart';
import 'app_theme.dart';

class ProductCareApp extends StatefulWidget {
  const ProductCareApp({super.key});

  @override
  State<ProductCareApp> createState() => _ProductCareAppState();
}

class _ProductCareAppState extends State<ProductCareApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Product Care',
    debugShowCheckedModeBanner: false,
    themeMode: _themeMode,
    theme: buildProductCareTheme(Brightness.light),
    darkTheme: buildProductCareTheme(Brightness.dark),
    home: ProductCareHome(
      themeMode: _themeMode,
      onThemeChanged: (mode) => setState(() => _themeMode = mode),
    ),
  );
}
