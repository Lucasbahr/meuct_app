import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    return Stack(
      children: [
        RefreshIndicator(
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
                          height: MediaQuery.sizeOf(context).height * 0.35,
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
                            SizedBox(height: 48),
                            AdminEmptyHint(
                              message:
                                  "Nenhum produto. Use + para cadastrar ou a categoria para organizar.",
                              icon: Icons.inventory_2_outlined,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                          itemCount: _products.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final p = _products[i];
                            final name = (p["name"] ?? "").toString();
                            final price = MarketplaceService.formatPrice(p["price"]);
                            final active = p["is_active"] != false;
                            final stock = p["stock"];
                            final img = MarketplaceService.productPrimaryImageUrl(p);
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tileColor: AdminPanelStyle.cardBgElevated,
                              leading: img != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: CachedNetworkImage(
                                          imageUrl: img,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) => const Icon(Icons.image),
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.inventory_2_outlined),
                              title: Text(name),
                              subtitle: Text(
                                "R\$ $price · Estoque: ${stock ?? "—"} · "
                                "${active ? "Ativo" : "Inativo"}",
                                style: const TextStyle(fontSize: 12),
                              ),
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
