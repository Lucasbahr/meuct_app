import 'package:flutter/material.dart';

import '../../shared/themes/app_tokens.dart';

/// Primária / secundária padrão quando o tenant não envia cor (admin / API legada).
const Color kDefaultBrandingPrimary = AppColors.primary;
const Color kDefaultBrandingSecondary = Color(0xFF374151);
const Color kDefaultBrandingBackgroundHint = AppColors.background;

Color? parseHexColor(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final v = int.tryParse(s, radix: 16);
  if (v == null) return null;
  return Color(v);
}

/// Formato `#RRGGBB` (maiúsculas) para [patchTenantBranding].
String formatBrandingHexRgb(Color color) {
  final r = (color.r * 255.0).round().clamp(0, 255);
  final g = (color.g * 255.0).round().clamp(0, 255);
  final b = (color.b * 255.0).round().clamp(0, 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
}

/// Mantido para chamadas existentes. O app **não** aplica mais cores do tenant ao [ThemeData]
/// (tema claro/escuro vem da preferência do usuário em Configurações).
class AppBrandingController {
  AppBrandingController._();
  static final AppBrandingController instance = AppBrandingController._();

  Future<void> refreshFromApi() async {}

  void resetToDefault() {}
}
