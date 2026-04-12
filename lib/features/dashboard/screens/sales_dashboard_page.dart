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
                              style: const TextStyle(color: Colors.white70),
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
                            if (_data != null) ..._build(_data!),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _build(Map<String, dynamic> d) {
    final top = d["top_products"];
    final byDay = d["sales_by_day"];

    return [
      Text(
        "Período: ${d["period_start"] ?? ""} → ${d["period_end_exclusive"] ?? ""}",
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _chip("Vendas", _money(d["total_sales"])),
          _chip("Pedidos", "${d["total_orders"] ?? 0}"),
          _chip("Ticket médio", _money(d["average_ticket"])),
          _chip("Comissão", _money(d["total_commission"])),
        ],
      ),
      const SizedBox(height: 24),
      const Text(
        "Produtos mais vendidos",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      if (top is List && top.isNotEmpty)
        ...top.map((raw) {
          if (raw is! Map) return const SizedBox.shrink();
          final m = Map<String, dynamic>.from(raw);
          return Card(
            color: const Color(0xFF1E1E1E),
            child: ListTile(
              title: Text(m["name"]?.toString() ?? ""),
              subtitle: Text(
                "${m["units_sold"] ?? 0} un. · ${_money(m["revenue"])}",
              ),
            ),
          );
        })
      else
        const Text("Sem dados.", style: TextStyle(color: Colors.white54)),
      const SizedBox(height: 20),
      const Text(
        "Vendas por dia",
        style: TextStyle(fontWeight: FontWeight.w600),
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
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text("${m["orders"] ?? 0} ped."),
                const SizedBox(width: 12),
                Text(_money(m["sales"])),
              ],
            ),
          );
        })
      else
        const Text("—", style: TextStyle(color: Colors.white38)),
    ];
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
