import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'user_theme_mode';

/// Preferência global de tema (claro / escuro / sistema). Persistida localmente.
class AppThemeController {
  AppThemeController._();
  static final AppThemeController instance = AppThemeController._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  static ThemeMode _parse(String? raw) {
    if (raw == null) return ThemeMode.system;
    for (final m in ThemeMode.values) {
      if (m.name == raw) return m;
    }
    return ThemeMode.system;
  }

  /// Carrega preferência salva. Em falha do canal nativo (ex.: hot restart no Android),
  /// mantém [ThemeMode.system] sem derrubar o app.
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      themeMode.value = _parse(p.getString(_kThemeModeKey));
    } catch (_) {
      themeMode.value = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kThemeModeKey, mode.name);
    } catch (_) {
      // Tema já mudou na UI; persistência só após cold start / canal ok.
    }
  }
}
