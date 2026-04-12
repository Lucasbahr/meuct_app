import 'package:flutter/material.dart';

import '../../shared/themes/app_tokens.dart';

/// Cor de destaque da graduação para chips e avatares.
Color graduationAccentColor(String? raw) {
  final t = (raw ?? '').toLowerCase();
  if (t.contains('preta') || t.contains('black')) return AppColors.beltBlack;
  if (t.contains('marrom') || t.contains('brown')) return AppColors.beltBrown;
  if (t.contains('roxa') || t.contains('roxo') || t.contains('purple')) {
    return AppColors.beltPurple;
  }
  if (t.contains('azul') || t.contains('blue')) return AppColors.beltBlue;
  if (t.contains('vermelh') || t.contains('red')) return AppColors.beltRed;
  if (t.contains('branc') || t.contains('white')) return AppColors.beltWhite;
  return AppColors.textSecondary;
}
