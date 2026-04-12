/// Design system do app — **importe só este arquivo** para paleta, espaçamentos, botões e tema.
///
/// ```dart
/// import 'package:genesis_mma/shared/themes/app_design_system.dart';
/// ```
///
/// **Botões:** preferir [PrimaryButton] / [SecondaryButton]; em diálogos, [FilledButton] e
/// [OutlinedButton] **sem** `styleFrom` herdam o [buildAppTheme]. Para override pontual:
/// [AppButtonStyles] ou [AppButtonContext] (`context.appFilledPrimaryStyle`).
///
/// - [AppColors], [AppSpacing], [AppRadii] — tokens visuais fixos
/// - [AppButtonStyles] + [AppButtonContext] — estilos de botão (fonte única)
/// - [PrimaryButton], [SecondaryButton] — CTAs reutilizáveis
/// - [buildAppTheme] — `ThemeData` Material 3 (primária do tenant via branding)
library;

export '../components/primary_button.dart';
export '../components/secondary_button.dart';
export 'app_tokens.dart';
export 'app_button_styles.dart';
export 'app_theme.dart'
    show buildAppTheme, buildAppLightTheme, buildAppDarkTheme, AppTheme;
