import 'package:flutter/material.dart';

import '../widgets/admin_shell.dart';
import 'admin_payment_tab.dart';
import 'admin_stock_tab.dart';
import 'admin_store_tab.dart';

/// Loja, credenciais de pagamento e estoque no mesmo lugar.
class AdminCommercialTab extends StatelessWidget {
  const AdminCommercialTab({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AdminHeroIntro(
            icon: Icons.storefront_outlined,
            title: "Comercial",
            subtitle:
                "Produtos na loja do app, vínculo Mercado Pago/PayPal e movimentação de estoque.",
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Material(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: TabBar(
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: accent,
                    dividerColor: Colors.white.withValues(alpha: 0.06),
                    tabs: const [
                      Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: "Produtos"),
                      Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 18), text: "Pagamentos"),
                      Tab(icon: Icon(Icons.warehouse_outlined, size: 18), text: "Estoque"),
                    ],
                  ),
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      AdminStoreTab(),
                      AdminPaymentTab(),
                      AdminStockTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
