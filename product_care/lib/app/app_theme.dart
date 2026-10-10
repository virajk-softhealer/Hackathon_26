import 'package:flutter/material.dart';

const brandGreen = Color(0xFF246B52);
const brandInk = Color(0xFF17251F);
const brandCanvas = Color(0xFFF5F7F3);

ThemeData buildProductCareTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: brandGreen,
    brightness: brightness,
    surface: dark ? const Color(0xFF17211C) : Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF101713) : brandCanvas,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF101713) : brandCanvas,
      foregroundColor: dark ? Colors.white : brandInk,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF202B25) : const Color(0xFFF1F4F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
