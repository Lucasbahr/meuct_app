import 'package:flutter/material.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../auth/repositories/auth_repository.dart';
import '../services/dashboard_service.dart';

class SalesDashboardPage extends StatefulWidget {
  const SalesDashboardPage({super.key});

  @override
  State<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends State<SalesDashboardPage> {
  final _service = DashboardService();
  final _authRepository = AuthRepository();
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  int _days = 30;

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
      final d = await _service.dashboardSales(days: _days, topProductsLimit: 8);
      if (!mounted) return;
      setState(() {
        _data = d;
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

  Future<void> _setDays(int d) async {
    if (d == _days) return;
    setState(() => _days = d);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Vendas (loja)")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text("7 dias")),
                ButtonSegment(value: 30, label: Text("30 dias")),
              ],
              selected: {_days},
              onSelectionChanged: (s) => _setDays(s.first),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: cs.tertiary,
              onRefresh: _load,
              child: _loading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: CircularProgressIndicator(color: cs.tertiary),
                        ),
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
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _load,
                              child: const Text("Tentar novamente"),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (_data != null) ..._build(context, _data!),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _build(BuildContext context, Map<String, dynamic> d) {
    final cs = Theme.of(context).colorScheme;
    final top = d["top_products"];
    final byDay = d["sales_by_day"];

    return [
      Text(
        "Período: ${d["period_start"] ?? ""} → ${d["period_end_exclusive"] ?? ""}",
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _chip(context, "Vendas", _money(d["total_sales"])),
          _chip(context, "Pedidos", "${d["total_orders"] ?? 0}"),
          _chip(context, "Ticket médio", _money(d["average_ticket"])),
          _chip(context, "Comissão", _money(d["total_commission"])),
        ],
      ),
      const SizedBox(height: 24),
      Text(
        "Produtos mais vendidos",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      if (top is List && top.isNotEmpty)
        ...top.map((raw) {
          if (raw is! Map) return const SizedBox.shrink();
          final m = Map<String, dynamic>.from(raw);
          return Card(
            color: cs.surfaceContainerHigh,
            child: ListTile(
              title: Text(
                m["name"]?.toString() ?? "",
                style: TextStyle(color: cs.onSurface),
              ),
              subtitle: Text(
                "${m["units_sold"] ?? 0} un. · ${_money(m["revenue"])}",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          );
        })
      else
        Text("Sem dados.", style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 20),
      Text(
        "Vendas por dia",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      if (byDay is List && byDay.isNotEmpty)
        ...byDay.take(14).map((raw) {
          if (raw is! Map) return const SizedBox.shrink();
          final m = Map<String, dynamic>.from(raw);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    m["date"]?.toString() ?? "—",
                    style: TextStyle(fontSize: 12, color: cs.onSurface),
                  ),
                ),
                Text(
                  "${m["orders"] ?? 0} ped.",
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Text(
                  _money(m["sales"]),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          );
        })
      else
        Text(
          "—",
          style: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.65),
          ),
        ),
    ];
  }

  Widget _chip(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _money(dynamic v) {
    if (v == null) return "R\$ 0,00";
    final n = v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    return "R\$ ${n.toStringAsFixed(2)}";
  }
}
