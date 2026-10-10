import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';
import '../pages/product_care_home.dart';
import 'app_theme.dart';

class ProductCareApp extends StatefulWidget {
  const ProductCareApp({super.key});

  @override
  State<ProductCareApp> createState() => _ProductCareAppState();
}

class _ProductCareAppState extends State<ProductCareApp> {
  ThemeMode _themeMode = ThemeMode.light;
  String _languageCode = 'en';

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Product Care',
    debugShowCheckedModeBanner: false,
    locale: Locale(_languageCode),
    supportedLocales: ProductCareLocalizations.supportedLocales,
    localizationsDelegates: const [
      ProductCareLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    themeMode: _themeMode,
    theme: buildProductCareTheme(Brightness.light),
    darkTheme: buildProductCareTheme(Brightness.dark),
    home: ProductCareHome(
      themeMode: _themeMode,
      onThemeChanged: (mode) => setState(() => _themeMode = mode),
      onLanguageChanged: (code) => setState(() => _languageCode = code),
    ),
  );
}
