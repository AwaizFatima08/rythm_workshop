import 'package:flutter/material.dart';

/// Accessible palette from the design (contrast checked against cream).
abstract final class Palette {
  static const cream = Color(0xFFFFF4E0);
  static const walnut = Color(0xFF4A3728);
  static const red = Color(0xFFC62828);
  static const blue = Color(0xFF1E5AA8);
  static const green = Color(0xFF2E7D32);
  static const yellow = Color(0xFFFFC107);
  static const amber = Color(0xFFF5A623); // decoration only, never meaning
  static const wood = Color(0xFFC98B4F);
  static const woodDark = Color(0xFFA0683A);
  static const woodLight = Color(0xFFE3B07A);
  static const faded = Color(0xFFC8B8A0);
}

/// Smallest touch target anywhere in the child-facing UI (dp).
const double kMinTouch = 64;

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Andika',
      scaffoldBackgroundColor: Palette.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.blue,
        surface: Palette.cream,
        primary: Palette.blue,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: Palette.walnut,
        displayColor: Palette.walnut,
      ),
    );

/// Calm mode: softens colours by pulling saturation down.
const ColorFilter calmFilter = ColorFilter.matrix(<double>[
  0.72, 0.21, 0.07, 0, 12, //
  0.07, 0.86, 0.07, 0, 12, //
  0.07, 0.21, 0.72, 0, 12, //
  0, 0, 0, 1, 0,
]);
