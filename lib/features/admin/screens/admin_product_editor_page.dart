import 'package:flutter/material.dart';

import '../../marketplace/services/marketplace_service.dart';

/// Cadastro / edição de produto (admin academia — `POST/PUT /products` na API).
class AdminProductEditorPage extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const AdminProductEditorPage({super.key, this.existing});

  @override
  State<AdminProductEditorPage> createState() => _AdminProductEditorPageState();
}

class _AdminProductEditorPageState extends State<AdminProductEditorPage> {
  final _service = MarketplaceService();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _categoryId = TextEditingController();
  final _subcategoryId = TextEditingController();
  final _imageUrls = TextEditingController();

  bool _trackStock = true;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _name.text = (p["name"] ?? "").toString();
      _description.text = (p["description"] ?? "").toString();
      _price.text = MarketplaceService.formatPrice(p["price"]);
      _stock.text = "${p["stock"] ?? 0}";
      if (p["category_id"] != null) {
        _categoryId.text = p["category_id"].toString();
      }
      if (p["subcategory_id"] != null) {
        _subcategoryId.text = p["subcategory_id"].toString();
      }
      _trackStock = p["track_stock"] != false;
      _isActive = p["is_active"] != false;
      final urls = MarketplaceService.productImageUrlList(
        Map<String, dynamic>.from(p),
      );
      _imageUrls.text = urls.join("\n");
    } else {
      _stock.text = "0";
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _categoryId.dispose();
    _subcategoryId.dispose();
    _imageUrls.dispose();
    super.dispose();
  }

  int? _parseOptionalInt(String t) {
    final s = t.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  List<String> _parseImageUrls() {
    final raw = _imageUrls.text;
    final parts = raw.split(RegExp(r'[\n,;]+'));
    return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack("Informe o nome do produto.");
      return;
    }
    final price = double.tryParse(_price.text.trim().replaceAll(",", "."));
    if (price == null || price <= 0) {
      _snack("Preço inválido (use número maior que zero).");
      return;
    }
    final stock = int.tryParse(_stock.text.trim()) ?? 0;
    if (stock < 0) {
      _snack("Estoque inicial não pode ser negativo.");
      return;
    }

    setState(() => _saving = true);
    try {
      final cat = _parseOptionalInt(_categoryId.text);
      final sub = _parseOptionalInt(_subcategoryId.text);
      final imgs = _parseImageUrls();

      if (_isEdit) {
        final idRaw = widget.existing!["id"];
        final id = idRaw is int ? idRaw : int.tryParse(idRaw.toString());
        if (id == null) throw Exception("Produto sem id.");

        await _service.updateProduct(
          id,
          name: name,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          price: price,
          stock: _trackStock ? stock : null,
          isActive: _isActive,
          categoryId: cat,
          subcategoryId: sub,
          imageUrls: imgs,
        );
      } else {
        await _service.createProduct(
          name: name,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          price: price,
          stock: stock,
          trackStock: _trackStock,
          isActive: _isActive,
          categoryId: cat,
          subcategoryId: sub,
          imageUrls: imgs,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? "Editar produto" : "Novo produto"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: "Nome *"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: "Descrição"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Preço (BRL) *",
              hintText: "ex: 29.90",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stock,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _isEdit ? "Estoque (ajuste)" : "Estoque inicial",
              helperText: _trackStock
                  ? null
                  : "Desativado: produto sem rastreamento de estoque",
            ),
          ),
          SwitchListTile(
            title: const Text("Rastrear estoque"),
            subtitle: _isEdit
                ? const Text(
                    "Não pode ser alterado após criar (API).",
                    style: TextStyle(fontSize: 11),
                  )
                : null,
            value: _trackStock,
            onChanged: _isEdit ? null : (v) => setState(() => _trackStock = v),
          ),
          SwitchListTile(
            title: const Text("Ativo na loja"),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _categoryId,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "ID da categoria (opcional)",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subcategoryId,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "ID da subcategoria (opcional)",
              helperText: "Exige categoria correspondente na API",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imageUrls,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "URLs de imagem",
              hintText: "Uma por linha ou separadas por vírgula",
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? "Salvando..." : "Salvar produto"),
          ),
        ],
      ),
    );
  }
}
