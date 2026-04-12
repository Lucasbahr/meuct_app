import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Estilos de botão padronizados — use com [FilledButton], [OutlinedButton], [TextButton]
/// ou [BuildContext.appFilledPrimaryStyle] / [PrimaryButton] / [SecondaryButton].
///
/// Regra: **evite** `*.styleFrom` solto nas telas; prefira estes métodos ou o tema em [buildAppTheme].
abstract final class AppButtonStyles {
  static EdgeInsetsGeometry get _padding => const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      );

  /// Ação principal (CTA).
  static ButtonStyle primaryFilled(ColorScheme scheme, Color primary) {
    return FilledButton.styleFrom(
      elevation: 0,
      backgroundColor: primary,
      foregroundColor: scheme.onPrimary,
      disabledBackgroundColor: primary.withValues(alpha: 0.38),
      disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.7),
      padding: _padding,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Botão preenchido padrão do app: acento vermelho [tertiary] (check-in, confirmar, CTA).
  static ButtonStyle tertiaryAccentFilled(ColorScheme scheme) {
    return FilledButton.styleFrom(
      elevation: 0,
      backgroundColor: scheme.tertiary,
      foregroundColor: scheme.onTertiary,
      disabledBackgroundColor: scheme.tertiary.withValues(alpha: 0.38),
      disabledForegroundColor: scheme.onTertiary.withValues(alpha: 0.7),
      padding: _padding,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Secundário sobre fundo claro (contorno da marca).
  static ButtonStyle secondaryOutlined(ColorScheme scheme, Color primary) {
    return OutlinedButton.styleFrom(
      foregroundColor: primary,
      disabledForegroundColor:
          scheme.onSurfaceVariant.withValues(alpha: 0.38),
      padding: _padding,
      minimumSize: const Size(0, 48),
      side: BorderSide(color: primary.withValues(alpha: 0.45)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );
  }

  /// Ghost / links em lista.
  static ButtonStyle textLink(Color primary) {
    return TextButton.styleFrom(
      foregroundColor: primary,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      minimumSize: const Size(0, 40),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  /// Destrutivo (sair, excluir).
  static ButtonStyle dangerText() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.error,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  /// Sucesso (menos comum; chips ou confirmações).
  static ButtonStyle successFilled() {
    return FilledButton.styleFrom(
      elevation: 0,
      backgroundColor: AppColors.success,
      foregroundColor: AppPalette.onAccent,
      padding: _padding,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    );
  }

  /// [FilledButton] tonal / secundário preenchido (menos ênfase que o primário).
  static ButtonStyle tonalFilled(ColorScheme scheme) {
    return FilledButton.styleFrom(
      elevation: 0,
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      disabledBackgroundColor:
          scheme.secondaryContainer.withValues(alpha: 0.5),
      disabledForegroundColor:
          scheme.onSecondaryContainer.withValues(alpha: 0.38),
      padding: _padding,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Contorno em superfície escura ou colorida (ex.: sheet de atleta).
  static ButtonStyle outlinedOnAccent({
    required Color foreground,
    required Color borderColor,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foreground,
      side: BorderSide(color: borderColor),
      padding: _padding,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );
  }

  /// Mescla altura mínima (ex.: CTA do dashboard).
  static ButtonStyle withMinHeight(ButtonStyle base, double height) {
    return base.merge(
      ButtonStyle(
        minimumSize: WidgetStateProperty.all(Size(0, height)),
      ),
    );
  }
}

/// Acesso rápido aos estilos do app a partir do [BuildContext] (alinhado ao [ColorScheme] atual).
extension AppButtonContext on BuildContext {
  ThemeData get _t => Theme.of(this);

  ColorScheme get _cs => _t.colorScheme;

  /// Alinhado ao [FilledButton] global (fundo vermelho / acento).
  ButtonStyle get appFilledPrimaryStyle =>
      AppButtonStyles.tertiaryAccentFilled(_cs);

  ButtonStyle get appOutlinedSecondaryStyle =>
      AppButtonStyles.secondaryOutlined(_cs, _cs.primary);

  ButtonStyle get appTextActionStyle => AppButtonStyles.textLink(_cs.primary);

  ButtonStyle get appDangerTextStyle => AppButtonStyles.dangerText();

  ButtonStyle get appTonalFilledStyle => AppButtonStyles.tonalFilled(_cs);
}
