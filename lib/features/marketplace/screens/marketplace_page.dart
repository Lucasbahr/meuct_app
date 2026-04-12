import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../auth/repositories/auth_repository.dart';
import '../marketplace_cart_store.dart';
import '../services/marketplace_service.dart';
import 'cart_checkout_page.dart';
import 'product_detail_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final _service = MarketplaceService();
  final _authRepository = AuthRepository();
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
      final list = await _service.listProducts();
      if (!mounted) return;
      setState(() {
        _products = list;
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Loja"),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: MarketplaceCartStore.totalItemCount > 0,
              label: Text("${MarketplaceCartStore.totalItemCount}"),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const CartCheckoutPage(),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
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
                : _products.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              "Nenhum produto disponível no momento.",
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, i) {
                          final p = _products[i];
                          final name = (p["name"] ?? "Produto").toString();
                          final price = MarketplaceService.formatPrice(p["price"]);
                          final img = MarketplaceService.productPrimaryImageUrl(p);
                          return Material(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ProductDetailPage(product: p),
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(14),
                                      ),
                                      child: img != null
                                          ? CachedNetworkImage(
                                              imageUrl: img,
                                              fit: BoxFit.cover,
                                              placeholder: (_, _) =>
                                                  const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              errorWidget: (_, _, _) =>
                                                  ColoredBox(
                                                color: cs.surfaceContainerHighest,
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: cs.onSurfaceVariant
                                                      .withValues(alpha: 0.45),
                                                ),
                                              ),
                                            )
                                          : ColoredBox(
                                              color: cs.surfaceContainerHighest,
                                              child: Icon(
                                                Icons.inventory_2_outlined,
                                                color: cs.onSurfaceVariant
                                                    .withValues(alpha: 0.45),
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      8,
                                      10,
                                      10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "R\$ $price",
                                          style: TextStyle(
                                            color: cs.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
