import 'dart:collection';

/// Carrinho simples em memória para o fluxo da loja (multi-tenant por sessão do app).
class MarketplaceCartStore {
  MarketplaceCartStore._();
  static final List<MarketplaceCartLine> _lines = [];

  static UnmodifiableListView<MarketplaceCartLine> get lines =>
      UnmodifiableListView(_lines);

  static int get totalItemCount =>
      _lines.fold<int>(0, (sum, line) => sum + line.quantity);

  static int? _productId(Map<String, dynamic> product) {
    final v = product["id"];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  static void addOrUpdate(Map<String, dynamic> product, int quantity) {
    if (quantity < 1) return;
    final id = _productId(product);
    if (id == null) return;
    final idx = _lines.indexWhere((l) => l.productId == id);
    if (idx >= 0) {
      _lines[idx].quantity += quantity;
    } else {
      _lines.add(MarketplaceCartLine(product: product, quantity: quantity));
    }
  }

  static void setQuantity(int productId, int quantity) {
    if (quantity < 1) {
      remove(productId);
      return;
    }
    final idx = _lines.indexWhere((l) => l.productId == productId);
    if (idx >= 0) {
      _lines[idx].quantity = quantity;
    }
  }

  static void remove(int productId) {
    _lines.removeWhere((l) => l.productId == productId);
  }

  static void clear() => _lines.clear();
}

class MarketplaceCartLine {
  final Map<String, dynamic> product;
  int quantity;

  MarketplaceCartLine({
    required this.product,
    required this.quantity,
  });

  int? get productId {
    final v = product["id"];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
}
