import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark({bool oled = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8A7CFF),
      brightness: Brightness.dark,
      surface: oled ? Colors.black : const Color(0xFF0B1020),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: oled ? Colors.black : const Color(0xFF070B17),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xCC11182B),
        indicatorColor: scheme.primary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: scheme.onSurface),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
    );
  }
}
