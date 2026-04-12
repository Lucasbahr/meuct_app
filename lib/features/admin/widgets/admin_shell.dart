import 'package:flutter/material.dart';

/// Visual e blocos reutilizáveis do painel admin (academia / plataforma).
abstract final class AdminPanelStyle {
  static const Color accent = Color(0xFFE53935);
  static const Color cardBg = Color(0xFF1A1A1A);
  static const Color cardBgElevated = Color(0xFF1E1E1E);

  static BoxDecoration cardDecoration({Color? border}) => BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border ?? Colors.white.withValues(alpha: 0.08),
        ),
      );

  static BoxDecoration heroGradientDecoration({Color? accentOverride}) {
    final a = accentOverride ?? accent;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      gradient: LinearGradient(
        colors: [
          a.withValues(alpha: 0.22),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
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
      decoration: AdminPanelStyle.heroGradientDecoration(accentOverride: cs.primary),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
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
          Icon(icon, size: 44, color: Colors.white.withValues(alpha: 0.22)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
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
    this.accent = AdminPanelStyle.accent,
  });

  final String message;
  final VoidCallback onRetry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              message.replaceFirst("Exception: ", ""),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Tentar novamente"),
              style: FilledButton.styleFrom(backgroundColor: accent),
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
                color: Colors.white.withValues(alpha: 0.6),
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
