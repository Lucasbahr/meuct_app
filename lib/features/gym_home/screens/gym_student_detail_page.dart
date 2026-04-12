import 'package:flutter/material.dart';

import '../../../core/graduacao/bjj_graduacao.dart';
import '../../../core/graduacao/graduation_palette.dart';
import '../../../shared/formatting/human_datetime.dart';
import '../../../shared/themes/app_button_styles.dart';
import '../../../shared/themes/app_tokens.dart';
import '../../admin/screens/admin_edit_student_page.dart';
import '../../admin/services/admin_service.dart';
import '../../admin/widgets/register_student_attendance.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../more/finance_module_page.dart';

class GymStudentDetailPage extends StatefulWidget {
  const GymStudentDetailPage({
    super.key,
    required this.student,
    this.canManageStudent = true,
  });

  final Map<String, dynamic> student;

  /// Presença em nome do aluno + edição cadastral (rotas de admin).
  final bool canManageStudent;

  @override
  State<GymStudentDetailPage> createState() => _GymStudentDetailPageState();
}

class _GymStudentDetailPageState extends State<GymStudentDetailPage> {
  final _admin = AdminService();
  final _dash = DashboardService();

  bool _loadingExtras = true;
  String? _extrasError;
  List<Map<String, dynamic>> _subscriptionRows = [];
  List<Map<String, dynamic>> _checkinAudit = [];

  int? get _studentId {
    final id = widget.student['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return null;
  }

  String get _nomeNorm =>
      (widget.student['nome'] ?? '').toString().trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    setState(() {
      _loadingExtras = true;
      _extrasError = null;
    });
    try {
      final alerts = await _dash.studentsSubscriptionAlerts();
      final academy = await _dash.dashboardAcademy(auditLimit: 64, loginsLimit: 4);
      if (!mounted) return;

      final dueSoon = _listFrom(alerts['due_soon']);
      final overdue = _listFrom(alerts['overdue']);
      final subs = <Map<String, dynamic>>[
        ...overdue.map((m) => {...m, '_overdue': true}),
        ...dueSoon.map((m) => {...m, '_overdue': false}),
      ];
      _subscriptionRows = subs.where(_rowMatchesStudent).toList();

      final auditRaw = academy['auditoria'];
      final audit = <Map<String, dynamic>>[];
      if (auditRaw is List) {
        for (final raw in auditRaw) {
          if (raw is Map) audit.add(Map<String, dynamic>.from(raw));
        }
      }
      _checkinAudit = audit.where(_auditMatchesStudent).where(_auditIsCheckin).toList();
    } catch (e) {
      if (mounted) {
        setState(() {
          _extrasError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loadingExtras = false);
    }
  }

  List<Map<String, dynamic>> _listFrom(dynamic v) {
    if (v is! List) return [];
    return v
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  bool _rowMatchesStudent(Map<String, dynamic> row) {
    final sid = _studentId;
    final rid = row['student_id'] ?? row['aluno_id'];
    if (sid != null && rid is num && rid.toInt() == sid) return true;
    final n =
        (row['student_name'] ?? row['nome'] ?? '').toString().trim().toLowerCase();
    return n.isNotEmpty && n == _nomeNorm;
  }

  static String _auditPersonName(Map<String, dynamic> e) {
    for (final k in [
      'student_name',
      'user_name',
      'actor_name',
      'nome',
      'name',
    ]) {
      final v = e[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return friendlyNameFromEmail(e['actor_email']?.toString());
  }

  bool _auditMatchesStudent(Map<String, dynamic> e) {
    final sid = _studentId;
    final rid = e['student_id'] ?? e['target_id'] ?? e['aluno_id'];
    if (sid != null && rid is num && rid.toInt() == sid) return true;
    final n = _auditPersonName(e).trim().toLowerCase();
    return n.isNotEmpty && n == _nomeNorm;
  }

  bool _auditIsCheckin(Map<String, dynamic> e) {
    final action = '${e['action'] ?? ''}'.toLowerCase();
    final target = '${e['target_type'] ?? ''}'.toLowerCase();
    final blob = '$action $target';
    return blob.contains('check') ||
        blob.contains('presen') ||
        blob.contains('attendance');
  }

  static String _auditActivityLine(Map<String, dynamic> e) {
    final action = '${e['action'] ?? ''}'.toLowerCase();
    final target = '${e['target_type'] ?? ''}'.toLowerCase();
    final blob = '$action $target';
    if (blob.contains('check') ||
        blob.contains('presen') ||
        blob.contains('attendance')) {
      return 'Check-in registrado';
    }
    final a = '${e['action'] ?? ''}'.trim();
    final t = '${e['target_type'] ?? ''}'.trim();
    if (a.isEmpty && t.isEmpty) return 'Atividade';
    return [a, t].where((s) => s.isNotEmpty).join(' · ');
  }

  String? _planFromStudentMap() {
    for (final k in [
      'plan_name',
      'nome_plano',
      'plano',
      'plan',
      'subscription_plan',
      'assinatura',
    ]) {
      final v = widget.student[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return null;
  }

  String _financialSituationLabel() {
    final overdue = _subscriptionRows.where((r) => r['_overdue'] == true).toList();
    if (overdue.isNotEmpty) return 'Mensalidade em atraso';
    final soon = _subscriptionRows.where((r) => r['_overdue'] == false).toList();
    if (soon.isNotEmpty) return 'Vencimento próximo';
    final st = (widget.student['status'] ?? '').toString().toLowerCase();
    if (st.contains('ativ')) return 'Em dia (cadastro ativo)';
    if (st.contains('inativ')) return 'Cadastro inativo';
    return (widget.student['status'] ?? '—').toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nome = (widget.student['nome'] ?? 'Aluno').toString().trim();
    final gradRaw = widget.student['graduacao']?.toString() ?? '';
    final grad = graduationLabelFromStudent(widget.student);
    final modality = modalityLabelFromStudent(widget.student);
    final status = (widget.student['status'] ?? '—').toString();
    final belt = graduationAccentColor(gradRaw.isNotEmpty ? gradRaw : grad);

    final planLabel = _planFromStudentMap() ??
        (_subscriptionRows.isNotEmpty
            ? (_subscriptionRows.first['plan_name'] ?? '').toString()
            : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aluno'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _profileHeader(
            context,
            nome: nome,
            grad: grad,
            modality: modality,
            status: status,
            belt: belt,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Ações',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (widget.canManageStudent) ...[
            FilledButton.icon(
              onPressed: () => registerStudentAttendance(
                context: context,
                service: _admin,
                student: widget.student,
                onSuccess: _loadExtras,
              ),
              icon: const Icon(Icons.how_to_reg_rounded),
              label: const Text('Registrar presença'),
              style: AppButtonStyles.tertiaryAccentFilled(cs).merge(
                const ButtonStyle(
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => AdminEditStudentPage(
                      service: _admin,
                      student: widget.student,
                    ),
                  ),
                );
                if (ok == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar dados'),
            ),
          ] else ...[
            Text(
              'Registro de presença em nome do aluno e edição do cadastro estão '
              'disponíveis para administradores. Use o botão "Registrar presença" na Home.',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                height: 1.4,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Financeiro',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _financeCard(
            context,
            planLabel: planLabel?.isNotEmpty == true ? planLabel! : '—',
            situation: _financialSituationLabel(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Histórico de pagamentos',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _paymentSection(context),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Histórico de check-ins',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_loadingExtras)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_extrasError != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Text(
                _extrasError!,
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
              ),
            )
          else if (_checkinAudit.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
              ),
              child: Text(
                'Nenhum check-in recente encontrado na auditoria da academia para este aluno.',
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
              ),
            )
          else
            ..._checkinAudit.map((e) => _checkinTile(context, e)),
          const SizedBox(height: AppSpacing.md),
          _line(context, Icons.email_outlined, 'E-mail',
              (widget.student['email'] ?? '—').toString()),
          _line(context, Icons.phone_outlined, 'Telefone',
              (widget.student['telefone'] ?? '—').toString()),
        ],
      ),
    );
  }

  Widget _profileHeader(
    BuildContext context, {
    required String nome,
    required String grad,
    required String modality,
    required String status,
    required Color belt,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.card + 4),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: belt.withValues(alpha: 0.2),
                child: Text(
                  _initials(nome),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: belt.computeLuminance() > 0.55
                        ? cs.onSurface
                        : cs.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome.isEmpty ? 'Aluno' : nome,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: belt.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: belt.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        grad,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: belt.computeLuminance() > 0.6
                              ? cs.onSurface
                              : belt,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _line(context, Icons.sports_martial_arts_rounded, 'Modalidade', modality),
          _line(context, Icons.verified_rounded, 'Status', status),
        ],
      ),
    );
  }

  Widget _financeCard(
    BuildContext context, {
    required String planLabel,
    required String situation,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plano atual',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            planLabel,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Situação',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            situation,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_subscriptionRows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Extrato e registros manuais de pagamento ficam no módulo financeiro.',
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const FinanceModulePage(),
                  ),
                );
              },
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
              label: const Text('Abrir financeiro'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _subscriptionRows.map((row) {
        final plan = (row['plan_name'] ?? '').toString();
        final due = row['due_date']?.toString() ?? '—';
        final amount = row['amount']?.toString();
        final overdue = row['_overdue'] == true;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: overdue
                    ? cs.error.withValues(alpha: 0.45)
                    : cs.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.isNotEmpty)
                  Text(
                    plan,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Venc.: $due',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                if (amount != null)
                  Text(
                    'R\$ $amount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _checkinTile(BuildContext context, Map<String, dynamic> e) {
    final cs = Theme.of(context).colorScheme;
    final when = formatBrazilDateTime(tryParseIso(e['created_at']));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.how_to_reg_rounded, color: cs.tertiary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _auditActivityLine(e),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: cs.onSurface,
                    ),
                  ),
                  if (when.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      when,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  static Widget _line(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
