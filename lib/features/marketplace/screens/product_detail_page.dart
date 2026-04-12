import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../marketplace_cart_store.dart';
import '../services/marketplace_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final name = (p["name"] ?? "Produto").toString();
    final desc = (p["description"] ?? "").toString().trim();
    final price = MarketplaceService.formatPrice(p["price"]);
    final img = MarketplaceService.productPrimaryImageUrl(p);

    final active = p["is_active"] != false;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (img != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: img,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: Color(0xFF2A2A2A),
                    child: Icon(Icons.broken_image, color: Colors.white24),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.white24,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            "R\$ $price",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE53935),
            ),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(desc, style: const TextStyle(color: Colors.white70)),
          ],
          const SizedBox(height: 24),
          if (!active)
            const Text(
              "Produto indisponível.",
              style: TextStyle(color: Colors.orangeAccent),
            )
          else ...[
            Row(
              children: [
                const Text("Quantidade", style: TextStyle(color: Colors.white70)),
                const Spacer(),
                IconButton(
                  onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text("$_qty", style: const TextStyle(fontSize: 18)),
                IconButton(
                  onPressed: () => setState(() => _qty++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  MarketplaceCartStore.addOrUpdate(p, _qty);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Adicionado ao carrinho")),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Adicionar ao carrinho"),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
