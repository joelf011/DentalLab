import 'package:flutter/material.dart';

class AppTheme {
  static const gold = Color(0xFFC5A059);
  static const background = Color(0xFFFAF9F6);
  static const text = Color(0xFF202020);

  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: gold,
      primary: gold,
      onPrimary: text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: text,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
  );
}
