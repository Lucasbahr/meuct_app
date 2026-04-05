import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: const Color(0xFFD32F2F),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFD32F2F),
      secondary: Color(0xFFD32F2F),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black.withValues(alpha: 0.45),
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
