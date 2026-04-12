import 'package:flutter/material.dart';

import '../../../shared/components/app_card.dart';
import '../../../shared/themes/app_tokens.dart';
import '../../admin/screens/admin_payment_tab.dart';
import '../../dashboard/screens/analytics_dashboard_page.dart';
import '../../dashboard/screens/sales_dashboard_page.dart';

/// Financeiro: acesso a gateways e relatório de vendas (sem Scaffold duplicado).
class FinanceModulePage extends StatelessWidget {
  const FinanceModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Pagamentos e gateways'),
                    ),
                    body: const AdminPaymentTab(),
                  ),
                ),
              );
            },
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.account_balance_wallet_outlined),
              ),
              title: const Text(
                'Pagamentos',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Mercado Pago, PayPal e credenciais da loja.',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const SalesDashboardPage(),
                ),
              );
            },
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.analytics_outlined),
              ),
              title: const Text(
                'Relatório de vendas',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Resumo da loja por período.',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const AnalyticsDashboardPage(),
                ),
              );
            },
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.query_stats_rounded),
              ),
              title: const Text(
                'Indicadores e evolução',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Receita de produtos, mensalidades e alunos mês a mês.',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
