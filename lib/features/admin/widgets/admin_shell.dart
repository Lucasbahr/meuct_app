import 'package:flutter/material.dart';

import '../../../shared/themes/app_button_styles.dart';

/// Visual e blocos reutilizáveis do painel admin (academia / plataforma).
/// Preferir sempre [Theme.of(context).colorScheme] nas telas.
abstract final class AdminPanelStyle {
  static BoxDecoration cardDecoration(BuildContext context, {Color? border}) {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: border ??
            cs.outline.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.35
                  : 0.2,
            ),
      ),
    );
  }

  static BoxDecoration heroGradientDecoration(
    BuildContext context, {
    Color? accentOverride,
  }) {
    final cs = Theme.of(context).colorScheme;
    final a = accentOverride ?? cs.primary;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: a.withValues(alpha: 0.2)),
      gradient: LinearGradient(
        colors: [
          a.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  /// [FilledButton] / [FilledButton.icon] — mesmo acento vermelho do app (ou [background] custom).
  static ButtonStyle filledPrimary(BuildContext context, {Color? background}) {
    final cs = Theme.of(context).colorScheme;
    if (background != null) {
      return AppButtonStyles.primaryFilled(cs, background);
    }
    return AppButtonStyles.tertiaryAccentFilled(cs);
  }

  /// [OutlinedButton] alinhado ao design system.
  static ButtonStyle outlinedAccent(BuildContext context, {Color? primary}) {
    final cs = Theme.of(context).colorScheme;
    final p = primary ?? cs.primary;
    return AppButtonStyles.secondaryOutlined(cs, p);
  }
}

/// Faixa de introdução no topo de uma aba (título + subtítulo + ícone).
class AdminHeroIntro extends StatelessWidget {
  const AdminHeroIntro({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AdminPanelStyle.heroGradientDecoration(
        context,
        accentOverride: cs.primary,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Estado vazio amigável (lista sem itens).
class AdminEmptyHint extends StatelessWidget {
  const AdminEmptyHint({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(
            icon,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Erro de rede / API com retry.
class AdminErrorPanel extends StatelessWidget {
  const AdminErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
    this.buttonColor,
  });

  final String message;
  final VoidCallback onRetry;
  /// Cor do botão de retry; padrão: [ColorScheme.primary] (monocromático).
  final Color? buttonColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fill = buttonColor ?? cs.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              message.replaceFirst("Exception: ", ""),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.75),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Tentar novamente"),
              style: AppButtonStyles.primaryFilled(cs, fill),
            ),
          ],
        ),
      ),
    );
  }
}

/// Acesso negado (ex.: não é admin).
class AdminAccessDeniedBody extends StatelessWidget {
  const AdminAccessDeniedBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_person_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 20),
            const Text(
              "Acesso restrito",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Esta área é só para administradores da academia ou da plataforma. "
              "Se precisar de permissão, fale com o responsável.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
