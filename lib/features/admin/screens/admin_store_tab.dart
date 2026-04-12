import 'package:flutter/material.dart';

import '../../../shared/components/product_card.dart';
import '../../marketplace/services/marketplace_service.dart';
import '../widgets/admin_shell.dart';
import 'admin_product_editor_page.dart';

class AdminStoreTab extends StatefulWidget {
  const AdminStoreTab({super.key});

  @override
  State<AdminStoreTab> createState() => _AdminStoreTabState();
}

class _AdminStoreTabState extends State<AdminStoreTab> {
  final _service = MarketplaceService();
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
      final list = await _service.listProducts(order: "desc");
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

  Future<void> _newCategory() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nova categoria"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: "Nome"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Criar")),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    try {
      final row = await _service.createCategory(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Categoria criada (id ${row["id"] ?? "—"}).")),
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
    final accent = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          color: accent,
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
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.35,
                          child: AdminErrorPanel(
                            message: _error!,
                            onRetry: _load,
                            buttonColor: accent,
                          ),
                        ),
                      ],
                    )
                  : _products.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 48),
                            AdminEmptyHint(
                              message:
                                  "Nenhum produto. Use + para cadastrar ou organize por categoria.",
                              icon: Icons.inventory_2_outlined,
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                          itemCount: _products.length,
                          itemBuilder: (context, i) {
                            final p = _products[i];
                            return ProductCard(
                              product: p,
                              onTap: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute<bool>(
                                    builder: (_) => AdminProductEditorPage(
                                      existing: Map<String, dynamic>.from(p),
                                    ),
                                  ),
                                );
                                if (changed == true && mounted) _load();
                              },
                            );
                          },
                        ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: "cat",
                onPressed: _newCategory,
                child: const Icon(Icons.category_outlined),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "add",
                onPressed: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => const AdminProductEditorPage(),
                    ),
                  );
                  if (changed == true && mounted) _load();
                },
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
