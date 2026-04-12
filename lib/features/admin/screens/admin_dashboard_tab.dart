import 'package:flutter/material.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../widgets/admin_shell.dart';

const _kAccent = AdminPanelStyle.accent;
const _kCard = Color(0xFF1A1A1A);

/// Visão geral para admin: resumo da academia, mensalidades (API) e métricas de alunos.
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final _dash = DashboardService();
  final _auth = AuthRepository();

  Map<String, dynamic>? _academy;
  Map<String, dynamic>? _alerts;
  Map<String, dynamic>? _studentsReport;
  String? _error;
  bool _loading = true;
  String? _alertsError;
  String? _reportError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _alertsError = null;
      _reportError = null;
    });

    try {
      final academy = await _dash.dashboardAcademy(
        auditLimit: 20,
        loginsLimit: 12,
      );

      Map<String, dynamic>? alerts;
      try {
        alerts = await _dash.studentsSubscriptionAlerts();
      } catch (e) {
        _alertsError = e.toString().replaceFirst("Exception: ", "");
      }

      Map<String, dynamic>? report;
      try {
        report = await _dash.reportsStudents();
      } catch (e) {
        _reportError = e.toString().replaceFirst("Exception: ", "");
      }

      if (!mounted) return;
      setState(() {
        _academy = academy;
        _alerts = alerts;
        _studentsReport = report;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (dioIsUnauthorized(e)) {
        await _auth.logout();
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

  List<Map<String, dynamic>> _listFrom(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Widget _metricCard(String label, String value, {IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, size: 20, color: _kAccent.withValues(alpha: 0.9)),
            if (icon != null) const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kAccent,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _alertTile(Map<String, dynamic> row, {required bool overdue}) {
    final name = (row["student_name"] ?? "Aluno").toString();
    final plan = (row["plan_name"] ?? "").toString();
    final due = row["due_date"]?.toString() ?? "—";
    final amount = row["amount"]?.toString();
    final reason = (row["reason"] ?? "").toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: overdue
              ? Colors.redAccent.withValues(alpha: 0.45)
              : Colors.amber.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            plan,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 14,
                color: overdue ? Colors.redAccent : Colors.amber,
              ),
              const SizedBox(width: 4),
              Text("Venc.: $due", style: const TextStyle(fontSize: 12)),
              if (amount != null) ...[
                const SizedBox(width: 12),
                Text(
                  "R\$ $amount",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
          if (reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }
    if (_error != null) {
      return AdminErrorPanel(
        message: _error!,
        onRetry: _load,
        accent: _kAccent,
      );
    }

    final resumo = _academy?["resumo"];
    final logins = _academy?["ultimos_logins"];
    final dueSoon = _listFrom(_alerts?["due_soon"]);
    final overdue = _listFrom(_alerts?["overdue"]);
    final rep = _studentsReport;

    return RefreshIndicator(
      color: _kAccent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
              gradient: LinearGradient(
                colors: [
                  _kAccent.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.insights_outlined, color: _kAccent, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dashboard",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Resumo operacional e mensalidades da sua academia.",
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (resumo is Map<String, dynamic>) ...[
            _sectionTitle("Atividade"),
            Row(
              children: [
                _metricCard(
                  "Alunos ativos",
                  "${resumo["alunos_ativos"] ?? 0}",
                  icon: Icons.groups_outlined,
                ),
                const SizedBox(width: 8),
                _metricCard(
                  "Check-in hoje",
                  "${resumo["checkins_hoje"] ?? 0}",
                  icon: Icons.today_outlined,
                ),
                const SizedBox(width: 8),
                _metricCard(
                  "Check-in 7 dias",
                  "${resumo["checkins_ultimos_7_dias"] ?? 0}",
                  icon: Icons.date_range_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          if (rep != null && rep.isNotEmpty) ...[
            _sectionTitle(
              "Assinaturas (relatório)",
              subtitle: _reportError,
            ),
            Row(
              children: [
                _metricCard(
                  "Total",
                  "${rep["total_students"] ?? "—"}",
                ),
                const SizedBox(width: 10),
                _metricCard(
                  "Ativos",
                  "${rep["active_students"] ?? "—"}",
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _metricCard(
                  "Inadimplentes",
                  "${rep["overdue_students"] ?? "—"}",
                ),
                const SizedBox(width: 10),
                _metricCard(
                  "Cancelados",
                  "${rep["canceled_students"] ?? "—"}",
                ),
              ],
            ),
            const SizedBox(height: 20),
          ] else if (_reportError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                "Relatório de alunos indisponível: $_reportError",
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          _sectionTitle(
            "Mensalidades",
            subtitle: "Vencimentos e atrasos (API /students/alerts)",
          ),
          if (_alertsError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _alertsError!,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
              ),
            ),
          if (dueSoon.isEmpty && overdue.isEmpty && _alertsError == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                "Nenhum alerta de mensalidade no momento.",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          if (dueSoon.isNotEmpty) ...[
            Text(
              "Vencendo (${dueSoon.length})",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 8),
            ...dueSoon.map((r) => _alertTile(r, overdue: false)),
            const SizedBox(height: 12),
          ],
          if (overdue.isNotEmpty) ...[
            Text(
              "Em atraso (${overdue.length})",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),
            ...overdue.map((r) => _alertTile(r, overdue: true)),
            const SizedBox(height: 16),
          ],
          _sectionTitle("Últimos acessos ao app"),
          if (logins is List && logins.isNotEmpty)
            ...logins.take(10).map((raw) {
              if (raw is! Map) return const SizedBox.shrink();
              final m = Map<String, dynamic>.from(raw);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.login_rounded, color: Colors.white38, size: 20),
                  title: Text(
                    m["email"]?.toString() ?? "—",
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    "${m["role"] ?? ""} · ${m["ultimo_login_em"] ?? "—"}",
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              );
            })
          else
            const Text(
              "Sem registros de login.",
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
