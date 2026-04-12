import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../../core/payment/checkout_payment_urls.dart';
import '../../auth/repositories/auth_repository.dart';
import '../marketplace_cart_store.dart';
import '../services/marketplace_service.dart';

class CartCheckoutPage extends StatefulWidget {
  const CartCheckoutPage({super.key});

  @override
  State<CartCheckoutPage> createState() => _CartCheckoutPageState();
}

class _CartCheckoutPageState extends State<CartCheckoutPage> {
  final _service = MarketplaceService();
  final _authRepository = AuthRepository();
  String _provider = "mercado_pago";
  bool _busy = false;

  Future<void> _checkout() async {
    final lines = MarketplaceCartStore.lines;
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Carrinho vazio.")),
      );
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final line in lines) {
      final id = line.productId;
      if (id == null) continue;
      items.add({"product_id": id, "quantity": line.quantity});
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Itens inválidos no carrinho.")),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final order = await _service.createOrder(items);
      final orderIdRaw = order["id"] ?? order["order_id"];
      final orderId = orderIdRaw is int
          ? orderIdRaw
          : int.tryParse(orderIdRaw?.toString() ?? "");
      if (orderId == null) {
        throw Exception(
          "Pedido criado, mas a resposta não trouxe o id do pedido.",
        );
      }

      final checkoutData = await _service.checkout(
        orderId,
        provider: _provider,
        returnUrl: CheckoutPaymentUrls.returnUrl(),
        cancelUrl: CheckoutPaymentUrls.cancelUrl(),
      );

      final payUrl = MarketplaceService.extractPaymentUrl(checkoutData);
      if (payUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Pedido criado, mas a URL de pagamento não veio no formato esperado. "
              "Confira na API o JSON de checkout (ex.: approval_url, init_point).",
            ),
          ),
        );
        return;
      }

      final uri = Uri.parse(payUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (launched) {
        MarketplaceCartStore.clear();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Pagamento aberto no navegador. Após concluir, volte ao app.",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (dioIsUnauthorized(e)) {
        await _authRepository.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = MarketplaceCartStore.lines;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Carrinho")),
      body: lines.isEmpty
          ? Center(
              child: Text(
                "Nenhum item no carrinho.",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final line = lines[i];
                      final name =
                          (line.product["name"] ?? "Produto").toString();
                      final price = MarketplaceService.formatPrice(
                        line.product["price"],
                      );
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text("R\$ $price × ${line.quantity}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                final id = line.productId;
                                if (id == null) return;
                                MarketplaceCartStore.setQuantity(
                                  id,
                                  line.quantity - 1,
                                );
                                setState(() {});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final id = line.productId;
                                if (id == null) return;
                                MarketplaceCartStore.setQuantity(
                                  id,
                                  line.quantity + 1,
                                );
                                setState(() {});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                final id = line.productId;
                                if (id == null) return;
                                MarketplaceCartStore.remove(id);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Forma de pagamento",
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: "mercado_pago",
                            label: Text("Mercado Pago"),
                          ),
                          ButtonSegment(
                            value: "paypal",
                            label: Text("PayPal"),
                          ),
                        ],
                        selected: {_provider},
                        onSelectionChanged: (s) {
                          setState(() => _provider = s.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _checkout,
                        child: Text(_busy ? "Processando..." : "Ir para pagamento"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
