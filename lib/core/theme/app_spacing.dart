import 'package:flutter/material.dart';

/// Espaçamento do design system (grid 4/8).
abstract final class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

/// Raios de borda padronizados.
abstract final class AppRadii {
  static const double card = 12;
}

/// Padding consistente para seções / cards.
EdgeInsetsGeometry get appScreenPadding =>
    const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md);
