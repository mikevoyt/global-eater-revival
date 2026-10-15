import 'package:flutter/material.dart';

abstract final class GeColors {
  static const paper = Color(0xFFFFFDF4);
  static const ink = Color(0xFF292A24);
  static const yellow = Color(0xFFFFD43B);
  static const orange = Color(0xFFF58B1A);
  static const teal = Color(0xFF167C94);
  static const muted = Color(0xFF686B5D);
  static const line = Color(0xFFE6E3D3);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: GeColors.orange).copyWith(
    primary: GeColors.ink,
    onPrimary: Colors.white,
    primaryContainer: GeColors.yellow,
    onPrimaryContainer: GeColors.ink,
    secondary: GeColors.teal,
    surface: GeColors.paper,
    onSurface: GeColors.ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: GeColors.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: GeColors.paper,
      foregroundColor: GeColors.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
    ),
    dividerColor: GeColors.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: GeColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: GeColors.teal, width: 2),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: GeColors.paper,
      indicatorColor: GeColors.yellow,
      height: 76,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
