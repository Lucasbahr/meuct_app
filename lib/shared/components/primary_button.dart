import 'package:flutter/material.dart';

import '../themes/app_button_styles.dart';
import '../themes/app_tokens.dart';

/// Botão primário — fundo acento [ColorScheme.tertiary] (vermelho da marca).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? cs.tertiary;
    final fg = foregroundColor ?? cs.onTertiary;

    ButtonStyle style = AppButtonStyles.tertiaryAccentFilled(cs);
    if (backgroundColor != null) {
      style = AppButtonStyles.primaryFilled(cs, bg);
    }
    if (foregroundColor != null) {
      style = style.merge(
        ButtonStyle(foregroundColor: WidgetStateProperty.all(fg)),
      );
    }

    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: fg,
                ),
              ),
            ],
          );

    final btn = FilledButton(
      onPressed: loading ? null : onPressed,
      style: style,
      child: child,
    );

    if (!fullWidth) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }
}
