import 'package:flutter/material.dart';

import '../themes/app_button_styles.dart';

/// Botão secundário (contorno) — mesmo padrão que o tema [outlinedButtonTheme].
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = AppButtonStyles.secondaryOutlined(cs, cs.primary);

    final Widget btn = icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 20),
            label: Text(label),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: style,
            child: Text(label),
          );

    if (!fullWidth) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }
}
