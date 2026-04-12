import 'package:flutter/material.dart';

import '../../shared/themes/app_theme.dart';
import '../../features/tenant/services/tenant_service.dart';

/// Primária / secundária quando o tenant não envia cor (tela admin e tema).
const Color kDefaultBrandingPrimary = Color(0xFFD32F2F);
const Color kDefaultBrandingSecondary = Color(0xFFE53935);
const Color kDefaultBrandingBackgroundHint = Color(0xFF0D0D0D);

/// Cores e tema derivados do tenant (`GET /tenant/config`).
class BrandingSnapshot {
  final ThemeData theme;
  final Color scrimOverlay;

  const BrandingSnapshot({
    required this.theme,
    required this.scrimOverlay,
  });
}

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

ThemeData buildBrandedTheme({
  required Color primary,
  required Color secondary,
}) {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: primary,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: const Color(0xFF121212),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black.withValues(alpha: 0.45),
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    hintColor: Colors.white54,
  );
}

class AppBrandingController {
  AppBrandingController._();
  static final AppBrandingController instance = AppBrandingController._();

  final ValueNotifier<BrandingSnapshot> snapshot = ValueNotifier(
    BrandingSnapshot(
      theme: AppTheme.darkTheme,
      scrimOverlay: Colors.black.withValues(alpha: 0.70),
    ),
  );

  void resetToDefault() {
    snapshot.value = BrandingSnapshot(
      theme: AppTheme.darkTheme,
      scrimOverlay: Colors.black.withValues(alpha: 0.70),
    );
  }

  Future<void> refreshFromApi() async {
    try {
      final svc = TenantService();
      final data = await svc.getTenantConfig();
      final tenant = data["tenant"];
      if (tenant is! Map) {
        resetToDefault();
        return;
      }
      final t = Map<String, dynamic>.from(tenant);
      final primary =
          parseHexColor(t["cor_primaria"]?.toString()) ?? kDefaultBrandingPrimary;
      final secondary =
          parseHexColor(t["cor_secundaria"]?.toString()) ??
              kDefaultBrandingSecondary;
      final bg = parseHexColor(t["cor_background"]?.toString());
      final scrim = bg != null
          ? bg.withValues(alpha: 0.78)
          : Colors.black.withValues(alpha: 0.70);

      snapshot.value = BrandingSnapshot(
        theme: buildBrandedTheme(primary: primary, secondary: secondary),
        scrimOverlay: scrim,
      );
    } catch (_) {
      // Mantém último tema em caso de falha de rede.
    }
  }
}
