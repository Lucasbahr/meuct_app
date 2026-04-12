import 'package:flutter/material.dart';

import '../../core/graduacao/bjj_graduacao.dart';
import '../../core/graduacao/graduation_palette.dart';
import '../themes/app_tokens.dart';

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.student,
    this.onTap,
    this.onCheckIn,
  });

  final Map<String, dynamic> student;
  final VoidCallback? onTap;

  /// Presença rápida (equipe). Quando preenchido, exibe botão abaixo do cabeçalho do card.
  final VoidCallback? onCheckIn;

  static String _initials(String name) {
    final list =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (list.isEmpty) return '?';
    if (list.length == 1) {
      final p = list.first;
      if (p.length >= 2) return p.substring(0, 2).toUpperCase();
      return p.toUpperCase();
    }
    return ('${list.first[0]}${list.last[0]}').toUpperCase();
  }

  static Color _statusColor(BuildContext context, String status) {
    final s = status.toLowerCase();
    final cs = Theme.of(context).colorScheme;
    if (s.contains('ativ')) return AppColors.success;
    if (s.contains('inativ') || s.contains('cancel')) return cs.onSurfaceVariant;
    if (s.contains('atras') || s.contains('pend')) return cs.error;
    return cs.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nome = (student['nome'] ?? 'Aluno').toString().trim();
    final displayName = nome.isEmpty ? 'Aluno' : nome;
    final gradRaw = student['graduacao']?.toString() ?? '';
    final grad = graduationLabelFromStudent(student);
    final modality = modalityLabelFromStudent(student);
    final status = (student['status'] ?? '—').toString();
    final beltColor = graduationAccentColor(gradRaw.isNotEmpty ? gradRaw : grad);
    final statusColor = _statusColor(context, status);

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: beltColor.withValues(alpha: 0.2),
                      child: Text(
                        _initials(displayName),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: beltColor.computeLuminance() > 0.55
                              ? cs.onSurface
                              : cs.onPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: beltColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: beltColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    grad,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: beltColor.computeLuminance() > 0.6
                                          ? cs.onSurface
                                          : beltColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (modality != '-' && modality.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              modality,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (onCheckIn != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: FilledButton.icon(
                  onPressed: onCheckIn,
                  icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                  label: const Text('Check-in'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
