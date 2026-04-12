import 'package:flutter/material.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/components/student_card.dart';
import '../../../shared/themes/app_tokens.dart';
import '../../admin/services/admin_service.dart';
import '../../admin/widgets/register_student_attendance.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../gym_schedule/gym_schedule_utils.dart';
import '../../gym_schedule/services/gym_schedule_service.dart';
import '../../student/services/checkin_service.dart';

/// Fluxo rápido de presença: equipe escolhe aluno na lista; aluno confirma na aula do dia.
/// Aberto a partir do Home (CTA) — não ocupa aba no bottom nav.
class GymQuickPresencePage extends StatefulWidget {
  const GymQuickPresencePage({
    super.key,
    required this.isAdmin,
  });

  /// Lista de alunos + check-in em nome do aluno (API exige perfil admin).
  final bool isAdmin;

  @override
  State<GymQuickPresencePage> createState() => _GymQuickPresencePageState();
}

class _GymQuickPresencePageState extends State<GymQuickPresencePage> {
  final _admin = AdminService();
  final _checkin = CheckinService();
  final _schedule = GymScheduleService();
  final _auth = AuthRepository();

  final _search = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _slots = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.isAdmin) {
        _students = await _admin.getStudents();
      } else {
        final grouped = await _schedule.listScheduleGrouped(activeOnly: true);
        final now = DateTime.now();
        _slots = slotsForApiWeekday(grouped, apiScheduleWeekday(now));
      }
    } catch (e) {
      if (dioIsUnauthorized(e)) {
        await _auth.logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
        }
        return;
      }
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _students;
    return _students.where((s) {
      final n = (s['nome'] ?? '').toString().toLowerCase();
      return n.contains(q);
    }).toList();
  }

  Future<void> _slotCheckin(Map<String, dynamic> slot) async {
    final idRaw = slot['id'];
    final slotId = idRaw is int ? idRaw : int.tryParse('$idRaw');
    if (slotId == null) return;
    final ci = slot['class_info'];
    final name = ci is Map ? (ci['name'] ?? 'Aula').toString() : 'Aula';
    final start = (slot['start_time'] ?? '').toString();
    final end = (slot['end_time'] ?? '').toString();

    final go = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Material(
          borderRadius: BorderRadius.circular(AppRadii.card + 4),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Check-in', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$name\n$start – $end',
                  style: const TextStyle(height: 1.35),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Confirmar presença',
                  onPressed: () => Navigator.pop(ctx, true),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (go != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final data = await _checkin.doCheckin(scheduleSlotId: slotId);
      if (!mounted) return;
      final h = data['hours_credited'];
      final msg = h != null
          ? 'Presença registrada! +$h h creditadas.'
          : 'Presença registrada com sucesso!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar presença'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Algo deu errado',
            message: _error,
            actionLabel: 'Tentar de novo',
            onAction: _boot,
          ),
        ],
      );
    }

    if (widget.isAdmin) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Buscar aluno',
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _boot,
              child: _filteredStudents.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 40),
                        EmptyState(
                          icon: Icons.person_search_rounded,
                          title: 'Nenhum resultado',
                          message: 'Ajuste a busca ou atualize a lista.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.lg + 24,
                      ),
                      itemCount: _filteredStudents.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final s = _filteredStudents[i];
                        return StudentCard(
                          student: s,
                          onTap: () => registerStudentAttendance(
                            context: context,
                            service: _admin,
                            student: s,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      );
    }

    if (_slots.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: 24),
          EmptyState(
            icon: Icons.event_busy_rounded,
            title: 'Sem aulas na grade hoje',
            message:
                'Peça à equipe para cadastrar horários em Painel admin → Academia, '
                'ou abra o calendário completo no menu Mais.',
            actionLabel: 'Atualizar',
            onAction: _boot,
          ),
        ],
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _boot,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg + 24,
            ),
            children: [
              Text(
                'Aulas de hoje — toque para confirmar presença',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Confirme só se você estiver na aula. O crédito de horas segue a duração cadastrada.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ..._slots.map((slot) {
                final ci = slot['class_info'];
                final name =
                    ci is Map ? (ci['name'] ?? 'Aula').toString() : 'Aula';
                final start = (slot['start_time'] ?? '').toString();
                final end = (slot['end_time'] ?? '').toString();
                final room = (slot['room'] ?? '').toString();
                final cs = Theme.of(context).colorScheme;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Material(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      onTap: _submitting ? null : () => _slotCheckin(slot),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.sm),
                              ),
                              child: Icon(
                                Icons.play_circle_outline_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      '$start – $end',
                                      if (room.isNotEmpty) room,
                                    ].join(' · '),
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.touch_app_rounded,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        if (_submitting)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: Theme.of(context)
                    .colorScheme
                    .scrim
                    .withValues(alpha: 0.35),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
