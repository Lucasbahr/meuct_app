import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_controller.dart';
import '../../auth/change_password/change_password_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurações"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Aparência",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppThemeController.instance.themeMode,
            builder: (context, mode, _) {
              return SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text("Sistema"),
                    icon: Icon(Icons.brightness_auto_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text("Claro"),
                    icon: Icon(Icons.light_mode_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text("Escuro"),
                    icon: Icon(Icons.dark_mode_outlined, size: 18),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) {
                  AppThemeController.instance.setThemeMode(s.first);
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            "O app usa apenas tema claro ou escuro. Cores personalizadas da academia não são mais aplicadas.",
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: cs.onSurfaceVariant.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "Conta",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordPage(),
                  ),
                );
              },
              icon: const Icon(Icons.lock_outline),
              label: const Text("Alterar senha"),
            ),
          ),
        ],
      ),
    );
  }
}
