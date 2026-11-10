import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Tema da app (usado no MaterialApp, em app.dart): botões, campos e barras.
class TemaApp {
  static final claro = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: CoresApp.fundo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CoresApp.dourado,
      primary: CoresApp.dourado,
      onPrimary: CoresApp.textoForte,
      surface: CoresApp.superficie,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: CoresApp.superficie,
      surfaceTintColor: CoresApp.superficie,
      foregroundColor: CoresApp.textoForte,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CoresApp.superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CoresApp.dourado,
        foregroundColor: CoresApp.textoForte,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        foregroundColor: CoresApp.textoForte,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
    ),
  );
}
