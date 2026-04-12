import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../admin/services/admin_service.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/dashboard_analytics_view_model.dart';
import '../services/dashboard_service.dart';
import '../utils/student_list_metrics.dart';
import '../widgets/monthly_bar_chart.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  final _service = DashboardService();
  final _admin = AdminService();
  final _authRepository = AuthRepository();

  DashboardAnalyticsViewModel? _vm;
  String? _error;
  bool _loading = true;
  int _months = 12;

  bool _rosterOk = false;
  int _rosterTotal = 0;
  int _rosterActive = 0;
  String? _headcountSyncHint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  static String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _syncHeadcountToBackend(int active, int total) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final day = _todayKey();
      final lastDay = prefs.getString('dash_headcount_day');
      final lastActive = prefs.getInt('dash_headcount_active');
      final lastTotal = prefs.getInt('dash_headcount_total');
      final newCalendarDay = lastDay != day;
      final countChanged = lastActive != active || lastTotal != total;
      if (!newCalendarDay && !countChanged) {
        if (mounted) {
          setState(() {
            _headcountSyncHint =
                'Contagem de hoje já registrada no servidor (sem mudanças).';
          });
        }
        return;
      }

      final sent = await _service.submitStudentHeadcountSnapshot(
        activeStudents: active,
        totalStudents: total,
      );

      if (!mounted) return;

      if (sent) {
        await prefs.setString('dash_headcount_day', day);
        await prefs.setInt('dash_headcount_active', active);
        await prefs.setInt('dash_headcount_total', total);
        setState(() {
          _headcountSyncHint =
              'Contagem enviada — o servidor pode montar a evolução dia a dia.';
        });
      } else {
        setState(() {
          _headcountSyncHint =
              'Histórico automático de alunos não está disponível no servidor.';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _headcountSyncHint = null);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _headcountSyncHint = null;
    });
    try {
      final raw = await _service.dashboardAnalytics(months: _months);

      var rosterOk = false;
      var total = 0;
      var active = 0;
      try {
        final list = await _admin.getStudents();
        rosterOk = true;
        total = list.length;
        active = StudentListMetrics.countActive(list);
      } catch (_) {
        rosterOk = false;
      }

      if (!mounted) return;
      setState(() {
        _vm = DashboardAnalyticsViewModel.fromPayload(raw);
        _rosterOk = rosterOk;
        _rosterTotal = total;
        _rosterActive = active;
        _loading = false;
      });

      if (rosterOk) {
        unawaited(_syncHeadcountToBackend(active, total));
      }
    } catch (e) {
      if (!mounted) return;
      if (dioIsUnauthorized(e)) {
        await _authRepository.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _setMonths(int m) async {
    if (m == _months) return;
    setState(() => _months = m);
    await _load();
  }

  String _brl(double v) {
    final neg = v.isNegative;
    final abs = neg ? -v : v;
    final cents = (abs * 100).round();
    final intPart = cents ~/ 100;
    final frac = (cents % 100).toString().padLeft(2, '0');
    final s = intPart.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'R\$ ${neg ? '-' : ''}$buf,$frac';
  }

  String _pct(double? p) {
    if (p == null) return '—';
    final sign = p > 0 ? '+' : '';
    return '$sign${p.toStringAsFixed(1)}% vs mês anterior';
  }

  Color _trendColor(BuildContext context, double? p) {
    if (p == null) return Theme.of(context).colorScheme.onSurfaceVariant;
    if (p > 0.5) return const Color(0xFF2E7D32);
    if (p < -0.5) return const Color(0xFFC62828);
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indicadores da academia'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 6, label: Text('6 meses')),
                  ButtonSegment(value: 12, label: Text('12 meses')),
                ],
                selected: {_months},
                onSelectionChanged: (s) => _setMonths(s.first),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
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
                            Text(
                              _error!,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Não foi possível carregar os indicadores. Verifique sua conexão ou tente mais tarde.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          children: [
                            if (_vm != null) ..._buildBody(context, _vm!),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, DashboardAnalyticsViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;

    return [
      _rosterHero(context, vm),
      const SizedBox(height: 20),
      Text(
        'Financeiro',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: cs.onSurface.withValues(alpha: 0.55),
        ),
      ),
      const SizedBox(height: 10),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _metricTile(
                context,
                icon: Icons.shopping_bag_rounded,
                title: 'Receita — produtos',
                value: vm.productRevenueTotal != null ? _brl(vm.productRevenueTotal!) : '—',
                trend: _pct(vm.revenueMomPct),
                trendColor: _trendColor(context, vm.revenueMomPct),
                accent: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile(
                context,
                icon: Icons.payments_rounded,
                title: 'Mensalidades',
                subtitle: 'Último mês da série',
                value: vm.subscriptionByMonth.isNotEmpty
                    ? _brl(vm.subscriptionByMonth.last.value)
                    : '—',
                trend: _pct(vm.subscriptionMomPct),
                trendColor: _trendColor(context, vm.subscriptionMomPct),
                accent: const Color(0xFF8D6E63),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      _chartSection(
        context,
        icon: Icons.show_chart_rounded,
        title: 'Receita da loja',
        subtitle: 'Valores por mês',
        child: MonthlyBarChart(
          points: vm.productRevenueByMonth,
          color: accent,
          valueLabel: _brl,
        ),
      ),
      const SizedBox(height: 16),
      _chartSection(
        context,
        icon: Icons.trending_up_rounded,
        title: 'Mensalidades',
        subtitle: 'Receita recorrente agregada',
        child: MonthlyBarChart(
          points: vm.subscriptionByMonth,
          color: const Color(0xFF8D6E63),
          valueLabel: _brl,
        ),
      ),
      const SizedBox(height: 16),
      _chartSection(
        context,
        icon: Icons.person_add_rounded,
        title: 'Alunos / matrículas',
        subtitle: 'A contagem em destaque vem da lista atual de alunos.',
        child: MonthlyBarChart(
          points: vm.studentsByMonth,
          color: cs.tertiary,
          valueLabel: (v) => v.round().toString(),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'A contagem de alunos ativos vem da lista cadastrada na academia. '
        'Quando muda ou em um novo dia, o app pode enviar o total ao servidor para histórico.',
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: cs.onSurfaceVariant.withValues(alpha: 0.88),
        ),
      ),
    ];
  }

  Widget _rosterHero(BuildContext context, DashboardAnalyticsViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    final onGrad = Colors.white.withValues(alpha: 0.94);
    final onGradMuted = Colors.white.withValues(alpha: 0.78);

    if (!_rosterOk) {
      return _surfaceCallout(
        context,
        icon: Icons.warning_amber_rounded,
        title: 'Lista de alunos indisponível',
        body:
            'Não foi possível carregar a lista de alunos. A contagem ficará indisponível.',
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.92),
            (Color.lerp(accent, cs.tertiary, 0.35) ?? accent).withValues(alpha: 0.88),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, color: onGrad, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Alunos na base (lista viva)',
                  style: TextStyle(
                    color: onGrad,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Contagem da lista da academia (exclui cancelados e inativos quando o status informa).',
            style: TextStyle(
              color: onGradMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$_rosterActive',
            style: TextStyle(
              color: onGrad,
              fontSize: 46,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ativos · $_rosterTotal cadastros no total',
            style: TextStyle(color: onGradMuted, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (vm.studentsMomPct != null) ...[
            const SizedBox(height: 8),
            Text(
              _pct(vm.studentsMomPct),
              style: TextStyle(
                color: _trendColor(context, vm.studentsMomPct).withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (vm.studentsThisMonth != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_outlined, size: 18, color: onGradMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Referência do servidor (mês): ${vm.studentsThisMonth}',
                      style: TextStyle(color: onGradMuted, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_headcountSyncHint != null) ...[
            const SizedBox(height: 12),
            Text(
              _headcountSyncHint!,
              style: TextStyle(
                color: onGradMuted,
                fontSize: 11.5,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _surfaceCallout(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.tertiary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required String value,
    required String trend,
    required Color trendColor,
    required Color accent,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: accent.withValues(alpha: 0.95)),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.72),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            trend,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: cs.primary.withValues(alpha: 0.92)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface.withValues(alpha: 0.92),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
