import 'package:flutter/material.dart';

import '../themes/app_button_styles.dart';
import '../themes/app_tokens.dart';

/// CTA principal do dashboard: alto, vermelho de destaque, sombra leve.
class DashboardCheckInButton extends StatelessWidget {
  const DashboardCheckInButton({
    super.key,
    required this.onPressed,
    this.label = 'Registrar presença',
  });

  final VoidCallback? onPressed;
  final String label;

  static const double _height = 58;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.tertiary;
    final base = AppButtonStyles.tertiaryAccentFilled(cs);
    final tall = AppButtonStyles.withMinHeight(base, _height);

    return Material(
      elevation: 0,
      shadowColor: accent.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: _height,
          child: FilledButton.icon(
            onPressed: onPressed,
            style: tall.merge(
              ButtonStyle(
                textStyle: WidgetStateProperty.all(
                  const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                elevation: WidgetStateProperty.all(0),
                shadowColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
            icon: const Icon(Icons.how_to_reg_rounded, size: 24),
            label: Text(label),
          ),
        ),
      ),
    );
  }
}
