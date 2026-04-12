import 'package:flutter/material.dart';

import '../../../core/graduacao/bjj_graduacao.dart';
import '../../admin/services/admin_service.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../gym_schedule/services/gym_schedule_service.dart';
import '../../student/services/checkin_service.dart';
import '../../../shared/components/dashboard_checkin_button.dart';
import '../../../shared/components/info_card.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/formatting/human_datetime.dart';
import '../../../shared/themes/app_tokens.dart';
import '../screens/gym_quick_presence_page.dart';
import '../screens/gym_student_detail_page.dart';

class GymDashboardTab extends StatefulWidget {
  const GymDashboardTab({
    super.key,
    required this.isStaff,
    required this.isAdmin,
    this.student,
    this.academyName,
  });

  final bool isStaff;
  final bool isAdmin;
  final Map<String, dynamic>? student;
  final String? academyName;

  @override
  State<GymDashboardTab> createState() => _GymDashboardTabState();
}

class _GymDashboardTabState extends State<GymDashboardTab> {
  final _dash = DashboardService();
  final _checkin = CheckinService();
  final _schedule = GymScheduleService();
  final _admin = AdminService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _academyDash;
  Map<String, dynamic>? _report;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _scheduleGrouped = [];
  Map<String, dynamic> _alerts = const {'due_soon': [], 'overdue': []};
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _ranking = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.isStaff) {
        final results = await Future.wait<Object>([
          _dash
              .dashboardAcademy(auditLimit: 0, loginsLimit: 0)
              .catchError((Object _) => <String, dynamic>{}),
          _dash.reportsStudents().catchError((Object _) => <String, dynamic>{}),
          _schedule
              .listScheduleGrouped()
              .catchError((Object _) => <Map<String, dynamic>>[]),
          _dash.studentsSubscriptionAlerts().catchError(
            (Object _) => <String, dynamic>{
              'due_soon': <dynamic>[],
              'overdue': <dynamic>[],
            },
          ),
          _admin.getStudents().catchError((Object _) => <Map<String, dynamic>>[]),
          _admin.getRanking().catchError((Object _) => <Map<String, dynamic>>[]),
        ]);

        if (!mounted) return;
        setState(() {
          _academyDash = results[0] as Map<String, dynamic>;
          _report = results[1] as Map<String, dynamic>;
          _scheduleGrouped =
              (results[2] as List).cast<Map<String, dynamic>>();
          _alerts = Map<String, dynamic>.from(results[3] as Map);
          _students =
              (results[4] as List).cast<Map<String, dynamic>>();
          _ranking =
              (results[5] as List).cast<Map<String, dynamic>>();
        });
      } else {
        final summary = await _checkin.getSummary();
        final history = await _checkin.getHistory();
        final grouped = await _schedule.listScheduleGrouped();
        if (!mounted) return;
        setState(() {
          _summary = summary;
          _history = history;
          _scheduleGrouped = grouped;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  void _openQuickPresence() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GymQuickPresencePage(isAdmin: widget.isAdmin),
      ),
    );
  }

  int _checkinsTodayFromHistory() {
    final now = DateTime.now();
    final key =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    for (final item in _history) {
      final raw = item['date']?.toString();
      if (raw == null) continue;
      if (raw.startsWith(key)) {
        return _int(item['total']);
      }
    }
    return 0;
  }

  /// API: 0 = segunda … 6 = domingo (igual ao backend).
  static int _apiWeekdayToday() => DateTime.now().weekday - 1;

  static DateTime? _parseBirth(Map<String, dynamic> s) {
    final raw = s['data_nascimento'] ?? s['nascimento'] ?? s['birth_date'];
    if (raw is! String || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static bool _isBirthdayToday(DateTime? birth, DateTime now) {
    if (birth == null) return false;
    return birth.month == now.month && birth.day == now.day;
  }

  List<Map<String, dynamic>> _birthdaysToday() {
    final now = DateTime.now();
    return _students.where((s) {
      final b = _parseBirth(s);
      return _isBirthdayToday(b, now);
    }).toList()
      ..sort((a, b) => (a['nome'] ?? '').toString().compareTo((b['nome'] ?? '').toString()));
  }

  List<Map<String, dynamic>> _slotsToday() {
    final wd = _apiWeekdayToday();
    for (final day in _scheduleGrouped) {
      if (_int(day['weekday']) != wd) continue;
      final slots = day['slots'];
      if (slots is! List) return [];
      final out = slots
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      out.sort((a, b) {
        final sa = '${a['start_time'] ?? ''}';
        final sb = '${b['start_time'] ?? ''}';
        return sa.compareTo(sb);
      });
      return out;
    }
    return [];
  }

  /// Ranking `GET /checkin/ranking` devolve `nome` + `total` (presenças no período agregado).
  /// Pegamos quem tem menos check-ins registrados como alerta operacional.
  List<Map<String, dynamic>> _lowFrequencyAlerts({int maxTotal = 2, int limit = 6}) {
    if (_ranking.isEmpty) return [];
    final copy = _ranking.map((e) => Map<String, dynamic>.from(e)).toList();
    copy.sort((a, b) => _int(a['total']).compareTo(_int(b['total'])));
    final low = <Map<String, dynamic>>[];
    for (final e in copy) {
      if (_int(e['total']) > maxTotal) continue;
      final nomeNorm =
          (e['nome'] ?? '').toString().trim().toLowerCase();
      int? sid;
      if (nomeNorm.isNotEmpty) {
        for (final s in _students) {
          if ((s['nome'] ?? '').toString().trim().toLowerCase() ==
              nomeNorm) {
            sid = _int(s['id']);
            break;
          }
        }
      }
      if (sid != null) e['student_id'] = sid;
      low.add(e);
      if (low.length >= limit) break;
    }
    return low;
  }

  List<Map<String, dynamic>> _alertList(String key) {
    final raw = _alerts[key];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic>? _studentById(int id) {
    for (final s in _students) {
      if (_int(s['id']) == id) return s;
    }
    return null;
  }

  void _openStudentById(int? id) {
    if (id == null) return;
    final s = _studentById(id);
    if (s == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GymStudentDetailPage(
          student: s,
          canManageStudent: widget.isAdmin,
        ),
      ),
    );
  }

  void _openStudentMap(Map<String, dynamic> s) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GymStudentDetailPage(
          student: s,
          canManageStudent: widget.isAdmin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.academyName?.trim().isNotEmpty == true
        ? widget.academyName!.trim()
        : 'Academia';
    final userName =
        (widget.student?['nome'] ?? '').toString().trim().isNotEmpty
            ? (widget.student!['nome'] as String).trim()
            : 'Aluno';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(label: 'Tentar de novo', onPressed: _load),
            ],
          ),
        ),
      );
    }

    final slotsToday = _slotsToday();
    final birthdays = widget.isStaff ? _birthdaysToday() : <Map<String, dynamic>>[];
    final overdue = widget.isStaff ? _alertList('overdue') : <Map<String, dynamic>>[];
    final dueSoon = widget.isStaff ? _alertList('due_soon') : <Map<String, dynamic>>[];
    final lowFreq = widget.isStaff ? _lowFrequencyAlerts() : <Map<String, dynamic>>[];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg + 16,
        ),
        children: [
          _AcademyHeroCard(
            title: name,
            subtitle: widget.isStaff ? 'Hoje · operação' : 'Olá, $userName',
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.isStaff)
            _CompactSummaryStrip(
              totalStudents: _int(_report?['total_students']),
              checkinsHoje: _academyDash?['resumo'] is Map<String, dynamic>
                  ? _int((_academyDash!['resumo'] as Map)['checkins_hoje'])
                  : 0,
            )
          else
            _StudentCompactStrip(
              mes: _int(_summary?['total_mes']),
              hoje: _checkinsTodayFromHistory(),
            ),
          const SizedBox(height: AppSpacing.lg),
          DashboardCheckInButton(onPressed: _openQuickPresence),
          const SizedBox(height: AppSpacing.lg),
          if (widget.isStaff) ...[
            _AlertsSection(
              overdue: overdue,
              dueSoon: dueSoon,
              lowFrequency: lowFreq,
              onStudentIdTap: _openStudentById,
              rankingName: (m) =>
                  (m['nome'] ?? m['aluno_nome'] ?? m['student_name'] ?? 'Aluno')
                      .toString(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _SectionHeader(
            icon: Icons.event_note_rounded,
            title: 'Aulas de hoje',
            subtitle: _weekdayLabelPt(),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TodayClassesList(slots: slotsToday),
          if (widget.isStaff) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              icon: Icons.cake_rounded,
              title: 'Aniversariantes de hoje',
              subtitle: birthdays.isEmpty ? 'Ninguém hoje' : '${birthdays.length} pessoa(s)',
            ),
            const SizedBox(height: AppSpacing.sm),
            _BirthdaysList(
              students: birthdays,
              onOpenProfile: _openStudentMap,
            ),
          ],
          if (!widget.isStaff) ...[
            const SizedBox(height: AppSpacing.lg),
            ..._studentKpis(context),
          ],
        ],
      ),
    );
  }

  String _weekdayLabelPt() {
    const labels = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    final i = _apiWeekdayToday();
    if (i >= 0 && i < labels.length) return labels[i];
    return 'Hoje';
  }

  List<Widget> _studentKpis(BuildContext context) {
    final dias = CheckinService.countDistinctTrainingDays(_history);

    return [
      InfoCard(
        icon: Icons.calendar_month_rounded,
        title: 'Dias com treino',
        value: '$dias',
      ),
      if (widget.student != null) ...[
        const SizedBox(height: AppSpacing.sm),
        InfoCard(
          icon: Icons.military_tech_rounded,
          title: 'Graduação',
          value: graduationLabelFromStudent(widget.student!),
          subtitle: modalityLabelFromStudent(widget.student!),
        ),
      ],
    ];
  }
}

// --- Layout helpers ---

class _CompactSummaryStrip extends StatelessWidget {
  const _CompactSummaryStrip({
    required this.totalStudents,
    required this.checkinsHoje,
  });

  final int totalStudents;
  final int checkinsHoje;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_outlined, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$totalStudents alunos · $checkinsHoje presenças hoje',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCompactStrip extends StatelessWidget {
  const _StudentCompactStrip({required this.mes, required this.hoje});

  final int mes;
  final int hoje;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$hoje check-in(s) hoje · $mes no mês',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.tertiary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: cs.tertiary, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      letterSpacing: -0.2,
                    ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayClassesList extends StatelessWidget {
  const _TodayClassesList({required this.slots});

  final List<Map<String, dynamic>> slots;

  static String _className(Map<String, dynamic> slot) {
    final ci = slot['class_info'];
    if (ci is Map) {
      return (ci['name'] ?? '').toString().trim().isNotEmpty
          ? ci['name'].toString()
          : 'Aula';
    }
    return 'Aula';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (slots.isEmpty) {
      return _SoftCard(
        child: Text(
          'Sem horários na grade para hoje.',
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
        ),
      );
    }
    return Column(
      children: slots.map((slot) {
        final start = '${slot['start_time'] ?? '—'}';
        final end = '${slot['end_time'] ?? ''}';
        final timeLine = end.isNotEmpty ? '$start – $end' : start;
        final room = (slot['room'] ?? '').toString().trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _SoftCard(
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    timeLine,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: cs.tertiary,
                      height: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _className(slot),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: cs.onSurface,
                        ),
                      ),
                      if (room.isNotEmpty)
                        Text(
                          room,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BirthdaysList extends StatelessWidget {
  const _BirthdaysList({
    required this.students,
    required this.onOpenProfile,
  });

  final List<Map<String, dynamic>> students;
  final void Function(Map<String, dynamic>) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (students.isEmpty) {
      return _SoftCard(
        child: Text(
          'Nenhum aniversariante nesta data.',
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
        ),
      );
    }
    return Column(
      children: students.map((s) {
        final nome = (s['nome'] ?? 'Aluno').toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _SoftCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.tertiary.withValues(alpha: 0.15),
                  child: Icon(Icons.cake_outlined, color: cs.tertiary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    nome,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onOpenProfile(s),
                  child: const Text('Ficha'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

enum _AlertTone { critical, attention }

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({
    required this.overdue,
    required this.dueSoon,
    required this.lowFrequency,
    required this.onStudentIdTap,
    required this.rankingName,
  });

  final List<Map<String, dynamic>> overdue;
  final List<Map<String, dynamic>> dueSoon;
  final List<Map<String, dynamic>> lowFrequency;
  final void Function(int?) onStudentIdTap;
  final String Function(Map<String, dynamic>) rankingName;

  static int? _sid(Map<String, dynamic> m) {
    for (final k in ['student_id', 'aluno_id', 'id']) {
      final v = m[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
    }
    return null;
  }

  static String _alertName(Map<String, dynamic> m) {
    final n = m['student_name'] ?? m['nome'] ?? m['aluno_nome'];
    if (n is String && n.trim().isNotEmpty) return n.trim();
    return 'Aluno';
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Texto curto para poucas presenças (dados agregados do ranking, não “mês”).
  static String _lowFrequencyHumanLine(Map<String, dynamic> e) {
    final t = _int(e['total']);
    if (t <= 0) return 'Sem treinos contabilizados no ranking.';
    if (t == 1) return 'Treinou apenas 1 vez.';
    if (t == 2) return 'Treinou só 2 vezes — vale acionar o aluno.';
    return 'Treinou pouco ($t presenças no histórico do ranking).';
  }

  static String _overdueDetail(Map<String, dynamic> e) {
    final motivo = (e['reason'] ?? 'Mensalidade').toString().trim();
    final data = formatBrazilDate(tryParseIso(e['due_date']));
    if (data.isEmpty) return motivo;
    return 'Vencia em $data · $motivo';
  }

  static String _dueSoonDetail(Map<String, dynamic> e) {
    final plano = (e['plan_name'] ?? 'Plano').toString().trim();
    final data = formatBrazilDate(tryParseIso(e['due_date']));
    if (data.isEmpty) return plano;
    return '$plano · vence $data';
  }

  void _openFullList(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> rows,
    required String Function(Map<String, dynamic>) nameOf,
    required String Function(Map<String, dynamic>) detailOf,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final maxH = MediaQuery.sizeOf(ctx).height * 0.62;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: maxH,
                  child: ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: cs.outline.withValues(alpha: 0.2),
                    ),
                    itemBuilder: (_, i) {
                      final e = rows[i];
                      final id = _sid(e);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          nameOf(e),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          detailOf(e),
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                        onTap: () {
                          Navigator.pop(ctx);
                          onStudentIdTap(id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final overdueIds = overdue.map(_sid).whereType<int>().toSet();
    final dueSoonFiltered = dueSoon
        .where((e) {
          final id = _sid(e);
          return id == null || !overdueIds.contains(id);
        })
        .toList();
    final lowFreqFiltered = lowFrequency.where((e) {
      final id = _sid(e);
      return id == null || !overdueIds.contains(id);
    }).toList();

    final hasAny = overdue.isNotEmpty ||
        dueSoonFiltered.isNotEmpty ||
        lowFreqFiltered.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.notifications_active_rounded,
          title: 'Alertas',
          subtitle: hasAny
              ? 'Prioridade para hoje: financeiro e frequência'
              : 'Tudo certo por aqui',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!hasAny)
          _SoftCard(
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Nenhum alerta ativo. Use Financeiro para mensalidades e '
                    'a aba Alunos para detalhes.',
                    style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (overdue.isNotEmpty) ...[
            _GroupedAlertCard(
              tone: _AlertTone.critical,
              icon: Icons.gpp_bad_rounded,
              title: 'Mensalidades em atraso',
              countHeadline:
                  '${overdue.length} ${overdue.length == 1 ? 'aluno' : 'alunos'} com cobrança atrasada',
              previewRows: overdue,
              nameOf: _alertName,
              idOf: _sid,
              previewDetail: _overdueDetail,
              footnote: 'Crítico · regularize antes de novos check-ins, se for política da academia.',
              onSeeAll: () => _openFullList(
                context,
                title: 'Mensalidades em atraso',
                rows: overdue,
                nameOf: _alertName,
                detailOf: _overdueDetail,
              ),
              onOpenStudent: onStudentIdTap,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (dueSoonFiltered.isNotEmpty) ...[
            _GroupedAlertCard(
              tone: _AlertTone.attention,
              icon: Icons.event_available_rounded,
              title: 'Vencendo em breve',
              countHeadline:
                  '${dueSoonFiltered.length} ${dueSoonFiltered.length == 1 ? 'aluno' : 'alunos'} com vencimento próximo',
              previewRows: dueSoonFiltered,
              nameOf: _alertName,
              idOf: _sid,
              previewDetail: _dueSoonDetail,
              footnote: 'Atenção · combine pagamento ou renovação com antecedência.',
              onSeeAll: () => _openFullList(
                context,
                title: 'Vencendo em breve',
                rows: dueSoonFiltered,
                nameOf: _alertName,
                detailOf: _dueSoonDetail,
              ),
              onOpenStudent: onStudentIdTap,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (lowFreqFiltered.isNotEmpty) ...[
            _GroupedAlertCard(
              tone: _AlertTone.attention,
              icon: Icons.sports_kabaddi_rounded,
              title: 'Frequência muito baixa',
              countHeadline:
                  '${lowFreqFiltered.length} ${lowFreqFiltered.length == 1 ? 'aluno' : 'alunos'} com pouquíssimos treinos',
              previewRows: lowFreqFiltered,
              nameOf: rankingName,
              idOf: _sid,
              previewDetail: _lowFrequencyHumanLine,
              footnote: 'Base: ranking de check-ins da academia.',
              onSeeAll: () => _openFullList(
                context,
                title: 'Baixa frequência',
                rows: lowFreqFiltered,
                nameOf: rankingName,
                detailOf: _lowFrequencyHumanLine,
              ),
              onOpenStudent: onStudentIdTap,
            ),
          ],
        ],
      ],
    );
  }
}

const int _kAlertPreviewNames = 3;

class _GroupedAlertCard extends StatelessWidget {
  const _GroupedAlertCard({
    required this.tone,
    required this.icon,
    required this.title,
    required this.countHeadline,
    required this.previewRows,
    required this.nameOf,
    required this.idOf,
    required this.previewDetail,
    required this.footnote,
    required this.onSeeAll,
    required this.onOpenStudent,
  });

  final _AlertTone tone;
  final IconData icon;
  final String title;
  final String countHeadline;
  final List<Map<String, dynamic>> previewRows;
  final String Function(Map<String, dynamic>) nameOf;
  final int? Function(Map<String, dynamic>) idOf;
  final String Function(Map<String, dynamic>) previewDetail;
  final String footnote;
  final VoidCallback onSeeAll;
  final void Function(int?) onOpenStudent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg;
    final Color border;
    final Color iconBg;
    final Color iconFg;
    final String badge;
    if (tone == _AlertTone.critical) {
      badge = 'Crítico';
      iconFg = const Color(0xFFB91C1C);
      bg = isDark
          ? const Color(0xFF3F1D1D).withValues(alpha: 0.85)
          : const Color(0xFFFFEBEE);
      border = isDark
          ? const Color(0xFF7F1D1D).withValues(alpha: 0.6)
          : const Color(0xFFFFCDD2);
      iconBg = isDark
          ? const Color(0xFF5C2020)
          : const Color(0xFFFFCDD2);
    } else {
      badge = 'Atenção';
      iconFg = const Color(0xFFB45309);
      bg = isDark
          ? const Color(0xFF3D3510).withValues(alpha: 0.88)
          : const Color(0xFFFFF8E1);
      border = isDark
          ? const Color(0xFF6B5A12).withValues(alpha: 0.55)
          : const Color(0xFFFFE082);
      iconBg = isDark
          ? const Color(0xFF5C4F12)
          : const Color(0xFFFFECB3);
    }

    final preview = previewRows.take(_kAlertPreviewNames).toList();
    final hidden = previewRows.length - preview.length;
    final showSeeAll = previewRows.length > _kAlertPreviewNames;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.card + 2),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: iconFg.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconFg, size: 30),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: iconFg.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: iconFg,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.3,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      countHeadline,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.88),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...preview.map((row) {
              final id = idOf(row);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 8, color: iconFg),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nameOf(row),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            previewDetail(row),
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (id != null)
                      TextButton(
                        onPressed: () => onOpenStudent(id),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Ver aluno'),
                      ),
                  ],
                ),
              );
            }),
            if (hidden > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '+$hidden ${hidden == 1 ? 'outro' : 'outros'}…',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
          ],
          if (showSeeAll)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: onSeeAll,
                style: FilledButton.styleFrom(
                  foregroundColor: iconFg,
                  backgroundColor: iconFg.withValues(alpha: 0.14),
                ),
                child: const Text('Ver lista completa'),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            footnote,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: cs.onSurfaceVariant.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: cs.outline.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}

class _AcademyHeroCard extends StatelessWidget {
  const _AcademyHeroCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.tertiary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: cs.tertiary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.4,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
