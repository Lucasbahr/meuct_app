import 'package:flutter/material.dart';
import 'package:genesis_mma/shared/themes/app_button_styles.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Tema claro: fundo branco, superfícies cinza-claras, texto [primary] monocromático,
/// acento vermelho em [ColorScheme.tertiary] apenas onde fizer sentido (CTA, ativo).
ThemeData buildAppLightTheme() {
  const bg = AppPalette.lightBackground;
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.lightPrimary,
    onPrimary: AppPalette.onAccent,
    primaryContainer: AppPalette.lightSurface,
    onPrimaryContainer: AppPalette.lightPrimary,
    secondary: AppPalette.lightSecondary,
    onSecondary: AppPalette.onAccent,
    secondaryContainer: AppPalette.lightSurfaceContainerHigh,
    onSecondaryContainer: AppPalette.lightPrimary,
    tertiary: AppPalette.accent,
    onTertiary: AppPalette.onAccent,
    tertiaryContainer: const Color(0xFFFFE4EC),
    onTertiaryContainer: const Color(0xFF9F1239),
    error: AppColors.error,
    onError: AppPalette.onAccent,
    surface: AppPalette.lightSurface,
    onSurface: AppPalette.lightPrimary,
    onSurfaceVariant: AppPalette.lightSecondary,
    outline: AppPalette.lightOutline,
    outlineVariant: AppPalette.lightOutline,
    shadow: AppPalette.lightPrimary.withValues(alpha: 0.08),
    scrim: AppPalette.lightPrimary.withValues(alpha: 0.35),
    inverseSurface: AppPalette.lightPrimary,
    onInverseSurface: AppPalette.lightSurface,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: bg,
    surfaceContainerLow: AppPalette.lightSurface,
    surfaceContainer: AppPalette.lightSurface,
    surfaceContainerHigh: AppPalette.lightSurfaceContainerHigh,
    surfaceContainerHighest: AppPalette.lightSurfaceContainerHighest,
  );

  return _baseTheme(scheme, bg, isDark: false);
}

/// Tema escuro slate (#0F172A / #1E293B) — texto claro legível, sem preto puro.
ThemeData buildAppDarkTheme() {
  const bg = AppPalette.darkBackground;
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.darkPrimary,
    onPrimary: AppPalette.darkBackground,
    primaryContainer: AppPalette.darkSurfaceContainerHigh,
    onPrimaryContainer: AppPalette.darkPrimary,
    secondary: AppPalette.darkSecondary,
    onSecondary: AppPalette.darkBackground,
    secondaryContainer: AppPalette.darkSurfaceContainerHighest,
    onSecondaryContainer: AppPalette.darkPrimary,
    tertiary: AppPalette.accent,
    onTertiary: AppPalette.onAccent,
    tertiaryContainer: AppPalette.accent.withValues(alpha: 0.22),
    onTertiaryContainer: AppPalette.darkPrimary,
    error: const Color(0xFFF87171),
    onError: AppPalette.darkBackground,
    surface: AppPalette.darkSurface,
    onSurface: AppPalette.darkPrimary,
    onSurfaceVariant: AppPalette.darkSecondary,
    outline: AppPalette.darkOutline,
    outlineVariant: AppPalette.darkOutline.withValues(alpha: 0.65),
    shadow: Colors.black.withValues(alpha: 0.45),
    scrim: Colors.black.withValues(alpha: 0.55),
    inverseSurface: const Color(0xFFE2E8F0),
    onInverseSurface: AppPalette.darkBackground,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: bg,
    surfaceContainerLow: AppPalette.darkSurfaceContainerLow,
    surfaceContainer: AppPalette.darkSurface,
    surfaceContainerHigh: AppPalette.darkSurfaceContainerHigh,
    surfaceContainerHighest: AppPalette.darkSurfaceContainerHighest,
  );

  return _baseTheme(scheme, bg, isDark: true);
}

/// Compat: tema claro (cores do tenant não alteram mais o app global).
ThemeData buildAppTheme({Color? primarySeed}) => buildAppLightTheme();

ThemeData _baseTheme(
  ColorScheme scheme,
  Color scaffoldBg, {
  required bool isDark,
}) {
  final accent = scheme.tertiary;

  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: scaffoldBg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(
          color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.22),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outline.withValues(alpha: 0.35),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: scheme.onInverseSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: scheme.tertiary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        borderSide: BorderSide(color: accent, width: 2),
      ),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppButtonStyles.tertiaryAccentFilled(scheme),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: AppButtonStyles.tertiaryAccentFilled(scheme),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: AppButtonStyles.secondaryOutlined(scheme, scheme.primary),
    ),
    textButtonTheme: TextButtonThemeData(
      style: AppButtonStyles.textLink(scheme.primary),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: scaffoldBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      width: 300,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AppRadii.card + 8),
        ),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      horizontalTitleGap: 12,
      minLeadingWidth: 40,
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.tertiary,
      foregroundColor: scheme.onTertiary,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card + 4),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.tertiary),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scaffoldBg,
      selectedItemColor: scheme.tertiary,
      unselectedItemColor: scheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showUnselectedLabels: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scaffoldBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.tertiary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.tertiary,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final c = states.contains(WidgetState.selected)
            ? scheme.tertiary
            : scheme.onSurfaceVariant;
        return IconThemeData(color: c, size: 24);
      }),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: scheme.onSurface, fontSize: 16),
      bodyMedium: TextStyle(color: scheme.onSurface, fontSize: 14),
      bodySmall: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
      titleLarge: TextStyle(
        color: scheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: scheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Legado (transparente).
class AppTheme {
  static ThemeData darkTheme = buildAppDarkTheme();
}
