import 'package:flutter/material.dart';

import '../../marketplace/services/marketplace_service.dart';
import '../services/stock_service.dart';
import '../widgets/admin_shell.dart';

class AdminStockTab extends StatefulWidget {
  const AdminStockTab({super.key});

  @override
  State<AdminStockTab> createState() => _AdminStockTabState();
}

class _AdminStockTabState extends State<AdminStockTab> {
  final _marketplace = MarketplaceService();
  final _stock = AdminStockService();
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _error;

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
      final list = await _marketplace.listProducts(sort: "name", order: "asc");
      if (!mounted) return;
      setState(() {
        _products = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
    }
  }

  Future<void> _qtyDialog({
    required String title,
    required void Function(int) onSubmit,
  }) async {
    final ctrl = TextEditingController(text: "1");
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Quantidade"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Confirmar")),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final q = int.tryParse(ctrl.text.trim()) ?? 0;
    if (q < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantidade inválida.")),
      );
      return;
    }
    onSubmit(q);
  }

  Future<void> _add(int productId) async {
    await _qtyDialog(
      title: "Entrada de estoque",
      onSubmit: (q) async {
        try {
          await _stock.addStock(productId, q);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Entrada registrada.")),
          );
          _load();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      },
    );
  }

  Future<void> _remove(int productId) async {
    final reasonHolder = <String>["manual"];
    final ctrl = TextEditingController(text: "1");
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text("Saída de estoque"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantidade"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: reasonHolder.first,
                decoration: const InputDecoration(labelText: "Motivo"),
                items: const [
                  DropdownMenuItem(value: "manual", child: Text("Manual")),
                  DropdownMenuItem(value: "loss", child: Text("Perda")),
                  DropdownMenuItem(value: "adjustment", child: Text("Ajuste")),
                  DropdownMenuItem(value: "cancel", child: Text("Cancelamento")),
                ],
                onChanged: (v) {
                  if (v != null) setLocal(() => reasonHolder[0] = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Confirmar")),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final q = int.tryParse(ctrl.text.trim()) ?? 0;
    if (q < 1) return;
    try {
      await _stock.removeStock(productId, q, reason: reasonHolder.first);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saída registrada.")),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _history(int? productId) async {
    try {
      final rows = await _stock.listMovements(productId: productId);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF2B2B2B),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          builder: (_, scroll) => Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Movimentos recentes",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: rows.isEmpty
                    ? const Center(child: Text("Sem movimentos."))
                    : ListView.builder(
                        controller: scroll,
                        itemCount: rows.length,
                        itemBuilder: (_, i) {
                          final m = rows[i];
                          return ListTile(
                            dense: true,
                            title: Text(
                              "${m["movement_type"] ?? ""} · "
                              "produto #${m["product_id"] ?? ""} · "
                              "qtd ${m["quantity"] ?? ""}",
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              "${m["reason"] ?? ""} · ${m["created_at"] ?? ""}",
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _history(null),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text("Histórico geral"),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
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
                      Center(
                        child: CircularProgressIndicator(color: AdminPanelStyle.accent),
                      ),
                    ],
                  )
                : _error != null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.45,
                            child: AdminErrorPanel(
                              message: _error!,
                              onRetry: _load,
                            ),
                          ),
                        ],
                      )
                    : _products.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 40),
                              AdminEmptyHint(
                                message:
                                    "Nenhum produto listado. Cadastre itens na aba Produtos.",
                                icon: Icons.warehouse_outlined,
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _products.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final p = _products[i];
                              final idRaw = p["id"];
                              final id = idRaw is int ? idRaw : int.tryParse(idRaw.toString());
                              final name = (p["name"] ?? "").toString();
                              final track = p["track_stock"] != false;
                              final stock = p["stock"];
                              return Material(
                                color: AdminPanelStyle.cardBgElevated,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(name, maxLines: 2),
                                          subtitle: Text(
                                            track
                                                ? "Estoque: ${stock ?? "—"}"
                                                : "Sem rastreamento de estoque",
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      if (id != null && track) ...[
                                        IconButton(
                                          tooltip: "Entrada",
                                          icon: const Icon(Icons.add_circle_outline),
                                          onPressed: () => _add(id),
                                        ),
                                        IconButton(
                                          tooltip: "Saída",
                                          icon: const Icon(Icons.remove_circle_outline),
                                          onPressed: () => _remove(id),
                                        ),
                                        IconButton(
                                          tooltip: "Movimentos",
                                          icon: const Icon(Icons.history),
                                          onPressed: () => _history(id),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}

