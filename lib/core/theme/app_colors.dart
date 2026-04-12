import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Paleta canônica (SaaS) — em UI preferir Theme.of(context).colorScheme.
// O vermelho [accent] está em ColorScheme.tertiary (+ extensão [accentColor]).
// ---------------------------------------------------------------------------

/// Valores hex do design system (light / dark / acento).
abstract final class AppPalette {
  static const Color accent = Color(0xFFE11D48);
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Light
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF9FAFB);
  static const Color lightPrimary = Color(0xFF111827);
  static const Color lightSecondary = Color(0xFF6B7280);
  static const Color lightOutline = Color(0xFFE5E7EB);

  /// Dark (slate — sem preto puro)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkPrimary = Color(0xFFF9FAFB);
  static const Color darkSecondary = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0xFF334155);

  static const Color darkSurfaceContainerHigh = Color(0xFF273549);
  static const Color darkSurfaceContainerHighest = Color(0xFF334155);
  static const Color darkSurfaceContainerLow = Color(0xFF162032);

  static const Color lightSurfaceContainerHigh = Color(0xFFF3F4F6);
  static const Color lightSurfaceContainerHighest = Color(0xFFE5E7EB);
}

/// Tokens estáticos (faixas, erros, defaults de API). Evite em layout de tela.
abstract final class AppColors {
  static const Color background = AppPalette.lightBackground;
  static const Color card = AppPalette.lightSurface;
  static const Color textPrimary = AppPalette.lightPrimary;
  static const Color textSecondary = AppPalette.lightSecondary;
  static const Color accent = AppPalette.accent;
  /// Ênfase monocromática (alinhada ao texto primário claro).
  static const Color primary = AppPalette.lightPrimary;

  static const Color success = Color(0xFF059669);
  static const Color error = Color(0xFFDC2626);

  static const Color beltWhite = Color(0xFFE5E7EB);
  static const Color beltBlue = Color(0xFF3B82F6);
  static const Color beltPurple = Color(0xFF8B5CF6);
  static const Color beltBrown = Color(0xFF92400E);
  static const Color beltBlack = Color(0xFF111827);
  static const Color beltRed = Color(0xFFDC2626);

  static const Color outlineMuted = AppPalette.lightOutline;
}

/// Acesso semântico ao acento no [ColorScheme] (Material 3: [tertiary]).
extension AppColorSchemeX on ColorScheme {
  Color get accentColor => tertiary;
}
