import 'package:flutter/material.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../tenant/services/tenant_service.dart';
import '../services/dashboard_service.dart';

const int _kStudentLoginPreview = 5;
const int _kEquipeLoginPreview = 4;
const int _kAuditPreview = 6;

class AcademyDashboardPage extends StatefulWidget {
  const AcademyDashboardPage({super.key});

  @override
  State<AcademyDashboardPage> createState() => _AcademyDashboardPageState();
}

class _AcademyDashboardPageState extends State<AcademyDashboardPage> {
  final _service = DashboardService();
  final _authRepository = AuthRepository();
  Map<String, dynamic>? _data;
  Map<String, dynamic> _alerts = const {};
  Map<String, dynamic> _report = const {};
  String? _academyDisplayName;
  String? _error;
  bool _loading = true;
  bool _studentLoginsExpanded = false;
  bool _equipeLoginsShowAll = false;
  bool _auditExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, dynamic>> _safe(Future<Map<String, dynamic>> future) async {
    try {
      return await future;
    } catch (_) {
      return {};
    }
  }

  Future<String?> _safeTenantDisplayName() async {
    try {
      final cfg = await TenantService().getTenantConfig();
      final tenant = cfg["tenant"];
      if (tenant is Map) {
        final t = Map<String, dynamic>.from(tenant);
        final n = t["nome"] ?? t["name"];
        if (n is String && n.trim().isNotEmpty) return n.trim();
      }
    } catch (_) {}
    return null;
  }

  String? _nameFromDashboard(Map<String, dynamic> data) {
    for (final key in [
      "gym_name",
      "nome",
      "name",
      "tenant_name",
      "academy_name",
    ]) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    final tenant = data["tenant"];
    if (tenant is Map) {
      final t = Map<String, dynamic>.from(tenant);
      final n = t["nome"] ?? t["name"];
      if (n is String && n.trim().isNotEmpty) return n.trim();
    }
    return null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dashFuture = _service.dashboardAcademy(auditLimit: 40, loginsLimit: 40);
      final tenantNameFuture = _safeTenantDisplayName();
      final dash = await dashFuture;
      String? displayName = await tenantNameFuture;
      displayName ??= _nameFromDashboard(dash);
      final alerts = await _safe(_service.studentsSubscriptionAlerts());
      final report = await _safe(_service.reportsStudents());
      if (!mounted) return;
      setState(() {
        _data = dash;
        _academyDisplayName = displayName;
        _alerts = alerts;
        _report = report;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (dioIsUnauthorized(e)) {
        await _authRepository.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel da academia"),
        actions: [
          IconButton(
            tooltip: "Atualizar",
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(_error!, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text("Tentar novamente")),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (_data != null) ..._build(context, _data!),
                    ],
                  ),
      ),
    );
  }

  List<Widget> _build(BuildContext context, Map<String, dynamic> data) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    final resumo = data["resumo"];
    final loginsAlunos = _asLoginList(data["ultimos_logins_alunos"]);
    final loginsEquipe = _asLoginList(data["ultimos_logins_equipe"]);
    final loginsLegacy = _asLoginList(data["ultimos_logins"]);
    final alunosLogins = loginsAlunos.isNotEmpty
        ? loginsAlunos
        : loginsLegacy.where((m) => _isAlunoRole(m["role"]?.toString())).toList();
    final equipeLogins = loginsEquipe.isNotEmpty
        ? loginsEquipe
        : loginsLegacy.where((m) => !_isAlunoRole(m["role"]?.toString())).toList();
    final audit = data["auditoria"];

    final dueSoon = _asMapList(_alerts["due_soon"]);
    final overdue = _asMapList(_alerts["overdue"]);
    final totalStudents = _asInt(_report["total_students"]);
    final overdueStudents = _asInt(_report["overdue_students"]);
    final canceledStudents = _asInt(_report["canceled_students"]);

    return [
      _headerCard(context, accent),
      const SizedBox(height: 16),
      if (resumo is Map<String, dynamic>) ...[
        _sectionTitle(context, Icons.insights_rounded, "Indicadores de hoje"),
        const SizedBox(height: 10),
        _heroCheckins(context, resumo, accent),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiMini(
                context,
                Icons.groups_rounded,
                "Alunos ativos",
                "${resumo["alunos_ativos"] ?? 0}",
                accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiMini(
                context,
                Icons.date_range_rounded,
                "Check-ins (7 dias)",
                "${resumo["checkins_ultimos_7_dias"] ?? 0}",
                accent,
              ),
            ),
          ],
        ),
        if (_report.isNotEmpty) ...[
          const SizedBox(height: 12),
          _subscriptionSnapshot(context, totalStudents, overdueStudents, canceledStudents, accent),
        ],
        const SizedBox(height: 20),
      ],
      if (dueSoon.isNotEmpty || overdue.isNotEmpty) ...[
        _sectionTitle(context, Icons.notifications_active_rounded, "Mensalidades"),
        const SizedBox(height: 8),
        _alertsCard(context, dueSoon, overdue, accent),
        const SizedBox(height: 20),
      ],
      _sectionTitle(context, Icons.school_rounded, "Alunos no app"),
      const SizedBox(height: 4),
      Text(
        "Quem entrou na conta recentemente (e-mail do cadastro).",
        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
      ),
      const SizedBox(height: 10),
      _loginSection(
        context: context,
        entries: alunosLogins,
        emptyLabel: "Nenhum aluno registrou login ainda — ou os dados ainda não chegaram.",
        accent: accent,
        previewCount: _kStudentLoginPreview,
        expanded: _studentLoginsExpanded,
        onToggleExpand: () => setState(() => _studentLoginsExpanded = !_studentLoginsExpanded),
        expandLabel: "Ver todos os alunos",
      ),
      const SizedBox(height: 8),
      Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Row(
            children: [
              Icon(Icons.badge_rounded, size: 22, color: accent.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Text(
                "Equipe (admin / professor)",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${equipeLogins.length}",
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
          initiallyExpanded: false,
          children: [
            _loginSection(
              context: context,
              entries: equipeLogins,
              emptyLabel: "Sem registros de login da equipe.",
              accent: accent,
              previewCount: _kEquipeLoginPreview,
              expanded: _equipeLoginsShowAll,
              onToggleExpand: () => setState(() => _equipeLoginsShowAll = !_equipeLoginsShowAll),
              expandLabel: "Ver toda a equipe",
              hideOuterCard: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _sectionTitle(context, Icons.history_rounded, "Auditoria recente"),
      const SizedBox(height: 8),
      _auditSection(context, audit, accent),
    ];
  }

  Widget _headerCard(BuildContext context, Color accent) {
    final cs = Theme.of(context).colorScheme;
    final name = (_academyDisplayName != null && _academyDisplayName!.trim().isNotEmpty)
        ? _academyDisplayName!.trim()
        : "Academia";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            cs.surfaceContainerHighest.withValues(alpha: 0.45),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Academia",
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 0.4,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Resumo operacional, acessos ao app e alertas de cobrança em um só lugar.",
            style: TextStyle(fontSize: 13, height: 1.35, color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary.withValues(alpha: 0.95)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }

  Widget _heroCheckins(BuildContext context, Map<String, dynamic> resumo, Color accent) {
    final cs = Theme.of(context).colorScheme;
    final n = resumo["checkins_hoje"] ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fitness_center_rounded, color: accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Check-ins hoje",
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  "$n",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiMini(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color accent,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent.withValues(alpha: 0.85)),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cs.onSurface.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subscriptionSnapshot(
    BuildContext context,
    int total,
    int overdue,
    int canceled,
    Color accent,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 18, color: accent.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Text(
                "Assinaturas (base)",
                style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.85)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _chipStat(context, "Total cadastrados", "$total", cs.onSurface.withValues(alpha: 0.8)),
              _chipStat(context, "Em atraso", "$overdue", overdue > 0 ? Colors.orangeAccent : null),
              _chipStat(context, "Cancelados", "$canceled", cs.onSurface.withValues(alpha: 0.55)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipStat(BuildContext context, String k, String v, Color? highlight) {
    final cs = Theme.of(context).colorScheme;
    final c = highlight ?? cs.onSurface.withValues(alpha: 0.75);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
          children: [
            TextSpan(text: "$k: "),
            TextSpan(
              text: v,
              style: TextStyle(fontWeight: FontWeight.w700, color: c, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertsCard(
    BuildContext context,
    List<Map<String, dynamic>> dueSoon,
    List<Map<String, dynamic>> overdue,
    Color accent,
  ) {
    final cs = Theme.of(context).colorScheme;
    final urgent = overdue.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: urgent ? Colors.redAccent.withValues(alpha: 0.55) : accent.withValues(alpha: 0.35),
          width: urgent ? 1.5 : 1,
        ),
        color: urgent ? Colors.redAccent.withValues(alpha: 0.08) : cs.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overdue.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.redAccent.shade200, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${overdue.length} em atraso",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent.shade100,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...overdue.take(3).map((m) => _alertLine(context, m, isOverdue: true)),
            if (overdue.length > 3)
              Text(
                "+ ${overdue.length - 3} outro(s)…",
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            if (dueSoon.isNotEmpty) const SizedBox(height: 12),
          ],
          if (dueSoon.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.schedule_rounded, color: Colors.amber.shade200, size: 20),
                const SizedBox(width: 8),
                Text(
                  "${dueSoon.length} vencendo em breve",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...dueSoon.take(2).map((m) => _alertLine(context, m, isOverdue: false)),
            if (dueSoon.length > 2)
              Text(
                "+ ${dueSoon.length - 2} outro(s)…",
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _alertLine(BuildContext context, Map<String, dynamic> m, {required bool isOverdue}) {
    final name = m["student_name"]?.toString().trim();
    final plan = m["plan_name"]?.toString() ?? "";
    final due = m["due_date"]?.toString() ?? "";
    final label = (name != null && name.isNotEmpty) ? name : "Aluno #${m["student_id"]}";
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label · $plan${due.isNotEmpty ? " · venc. $due" : ""}",
        style: TextStyle(
          fontSize: 13,
          height: 1.3,
          color: isOverdue ? Colors.redAccent.shade100 : cs.onSurface.withValues(alpha: 0.82),
        ),
      ),
    );
  }

  Widget _loginSection({
    required BuildContext context,
    required List<Map<String, dynamic>> entries,
    required String emptyLabel,
    required Color accent,
    required int previewCount,
    required bool expanded,
    required VoidCallback onToggleExpand,
    required String expandLabel,
    bool hideOuterCard = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(emptyLabel, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13)),
      );
    }

    final showAll = expanded || entries.length <= previewCount;
    final slice = showAll ? entries : entries.take(previewCount).toList();
    final hidden = entries.length - previewCount;

    final list = Column(
      children: [
        for (var i = 0; i < slice.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == slice.length - 1 ? 0 : 8),
            child: _loginTile(context, slice[i], accent),
          ),
        if (!showAll && hidden > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: onToggleExpand,
              icon: const Icon(Icons.expand_more_rounded),
              label: Text("$expandLabel ($hidden a mais)"),
            ),
          ),
        if (showAll && entries.length > previewCount)
          TextButton.icon(
            onPressed: onToggleExpand,
            icon: const Icon(Icons.expand_less_rounded),
            label: const Text("Mostrar menos"),
          ),
      ],
    );

    if (hideOuterCard) return list;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
      ),
      child: list,
    );
  }

  Widget _loginTile(BuildContext context, Map<String, dynamic> m, Color accent) {
    final cs = Theme.of(context).colorScheme;
    final email = m["email"]?.toString() ?? "—";
    final role = _roleLabel(m["role"]?.toString());
    final when = _formatRelativeLogin(m["ultimo_login_em"]?.toString());
    return Material(
      color: cs.surface.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.25),
          child: Text(
            email.isNotEmpty ? email[0].toUpperCase() : "?",
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          "$role · $when",
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
        ),
      ),
    );
  }

  Widget _auditSection(BuildContext context, dynamic audit, Color accent) {
    final cs = Theme.of(context).colorScheme;
    final rows = audit is List ? audit : const [];
    final list = <Map<String, dynamic>>[];
    for (final raw in rows) {
      if (raw is Map) list.add(Map<String, dynamic>.from(raw));
    }
    if (list.isEmpty) {
      return Text("—", style: TextStyle(color: cs.onSurface.withValues(alpha: 0.45)));
    }

    final showAll = _auditExpanded || list.length <= _kAuditPreview;
    final slice = showAll ? list : list.take(_kAuditPreview).toList();
    final more = list.length - _kAuditPreview;

    return Column(
      children: [
        for (var i = 0; i < slice.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.bolt_rounded, size: 20, color: accent.withValues(alpha: 0.75)),
                title: Text(
                  "${slice[i]["action"] ?? ""} · ${slice[i]["target_type"] ?? ""}",
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  "${slice[i]["actor_email"] ?? "—"} · ${slice[i]["created_at"] ?? ""}",
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
        if (!showAll && more > 0)
          TextButton.icon(
            onPressed: () => setState(() => _auditExpanded = true),
            icon: const Icon(Icons.unfold_more_rounded, size: 20),
            label: Text("Ver mais auditoria ($more)"),
          ),
        if (showAll && list.length > _kAuditPreview)
          TextButton.icon(
            onPressed: () => setState(() => _auditExpanded = false),
            icon: const Icon(Icons.unfold_less_rounded, size: 20),
            label: const Text("Mostrar menos"),
          ),
      ],
    );
  }

  static List<Map<String, dynamic>> _asLoginList(dynamic raw) {
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) out.add(Map<String, dynamic>.from(e));
    }
    return out;
  }

  static List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) out.add(Map<String, dynamic>.from(e));
    }
    return out;
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? "") ?? 0;
  }

  static bool _isAlunoRole(String? r) {
    final x = (r ?? "").toUpperCase().trim();
    return x == "ALUNO";
  }

  static String _roleLabel(String? role) {
    switch ((role ?? "").toUpperCase().trim()) {
      case "ALUNO":
        return "Aluno";
      case "PROFESSOR":
        return "Professor";
      case "ADMIN_ACADEMIA":
      case "ADMIN":
        return "Admin academia";
      case "ADMIN_SISTEMA":
        return "Admin sistema";
      default:
        return role ?? "—";
    }
  }

  static String _formatRelativeLogin(String? iso) {
    if (iso == null || iso.isEmpty) return "sem registro";
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.isNegative) return "agora";
    if (diff.inMinutes < 1) return "agora";
    if (diff.inMinutes < 60) return "há ${diff.inMinutes} min";
    if (diff.inHours < 24) return "há ${diff.inHours} h";
    if (diff.inDays < 7) return "há ${diff.inDays} d";
    final d = local.day.toString().padLeft(2, "0");
    final m = local.month.toString().padLeft(2, "0");
    return "$d/$m/${local.year}";
  }
}
