import 'package:flutter/material.dart';

import '../../../shared/components/app_card.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/themes/app_tokens.dart';
import '../../admin/screens/academy_admin_page.dart';
import '../../admin/screens/admin_payment_tab.dart';
import '../../dashboard/screens/sales_dashboard_page.dart';
import '../more/commercial_store_page.dart';
import '../more/finance_module_page.dart';
import '../more/plans_module_page.dart';
import '../more/stock_module_page.dart';

/// Aba **Mais**: navegação secundária (sem drawer). Espaçamento amplo, pouco texto auxiliar.
class GymMoreTab extends StatelessWidget {
  const GymMoreTab({
    super.key,
    required this.isStaff,
    required this.isAdmin,
    required this.isSystemAdmin,
    required this.onGoHome,
    required this.onNavigateRoute,
  });

  final bool isStaff;
  final bool isAdmin;
  final bool isSystemAdmin;
  final VoidCallback onGoHome;
  final Future<void> Function(String route) onNavigateRoute;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg + 32,
      ),
      children: [
        _sectionTitle(context, 'Navegação'),
        const SizedBox(height: AppSpacing.sm),
        _tile(
          context,
          icon: Icons.home_rounded,
          title: 'Início',
          onTap: onGoHome,
        ),
        const SizedBox(height: AppSpacing.lg),
        _sectionTitle(context, 'Para você'),
        const SizedBox(height: AppSpacing.sm),
        _tile(
          context,
          icon: Icons.person_rounded,
          title: 'Meus dados',
          onTap: () => onNavigateRoute('profile'),
        ),
        _tile(
          context,
          icon: Icons.calendar_today_rounded,
          title: 'Frequência',
          onTap: () => onNavigateRoute('checkin'),
        ),
        _tile(
          context,
          icon: Icons.calendar_month_rounded,
          title: 'Calendário de aulas',
          onTap: () => onNavigateRoute('schedule_calendar'),
        ),
        _tile(
          context,
          icon: Icons.cake_rounded,
          title: 'Aniversariantes',
          onTap: () => onNavigateRoute('birthdays'),
        ),
        _tile(
          context,
          icon: Icons.sports_martial_arts_rounded,
          title: 'Atletas',
          onTap: () => onNavigateRoute('athletes'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _sectionTitle(context, 'Comunidade'),
        const SizedBox(height: AppSpacing.sm),
        _tile(
          context,
          icon: Icons.newspaper_rounded,
          title: 'Feed',
          onTap: () => onNavigateRoute('feed'),
        ),
        _tile(
          context,
          icon: Icons.emoji_events_rounded,
          title: 'Gamificação',
          onTap: () => onNavigateRoute('gamification'),
        ),
        _tile(
          context,
          icon: Icons.school_rounded,
          title: 'Graduação',
          onTap: () => onNavigateRoute('graduation'),
        ),
        _tile(
          context,
          icon: Icons.leaderboard_rounded,
          title: 'Ranking',
          onTap: () => onNavigateRoute('ranking'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _sectionTitle(context, 'Loja'),
        const SizedBox(height: AppSpacing.sm),
        _tile(
          context,
          icon: Icons.shopping_bag_rounded,
          title: 'Loja',
          onTap: () => onNavigateRoute('marketplace'),
        ),
        if (isStaff) ...[
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Financeiro'),
          const SizedBox(height: AppSpacing.sm),
          _tile(
            context,
            icon: Icons.account_balance_rounded,
            title: 'Controle financeiro',
            onTap: () => _push(context, const FinanceModulePage()),
          ),
          _tile(
            context,
            icon: Icons.payments_rounded,
            title: 'Pagamentos gerais',
            onTap: () => _push(
              context,
              Scaffold(
                appBar: AppBar(
                  title: const Text('Pagamentos e gateways'),
                ),
                body: const AdminPaymentTab(),
              ),
            ),
          ),
          _tile(
            context,
            icon: Icons.analytics_outlined,
            title: 'Relatórios de vendas',
            onTap: () => _push(context, const SalesDashboardPage()),
          ),
          _tile(
            context,
            icon: Icons.query_stats_rounded,
            title: 'Indicadores e evolução',
            onTap: () => onNavigateRoute('dashboard-analytics'),
          ),
          _tile(
            context,
            icon: Icons.apartment_rounded,
            title: 'Painel da academia',
            onTap: () => onNavigateRoute('dashboard-academy'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Gestão'),
          const SizedBox(height: AppSpacing.sm),
          _tile(
            context,
            icon: Icons.storefront_rounded,
            title: 'Loja e produtos',
            onTap: () => _push(context, const CommercialStorePage()),
          ),
          _tile(
            context,
            icon: Icons.price_change_rounded,
            title: 'Planos',
            onTap: () => _push(context, const PlansModulePage()),
          ),
          _tile(
            context,
            icon: Icons.warehouse_rounded,
            title: 'Estoque',
            onTap: () => _push(context, const StockModulePage()),
          ),
          if (isAdmin) ...[
            const SizedBox(height: AppSpacing.md),
            _tile(
              context,
              icon: Icons.dashboard_customize_rounded,
              title: 'Painel completo',
              onTap: () => _push(context, const AcademyAdminPage()),
            ),
          ],
        ],
        if (isAdmin) ...[
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Administração'),
          const SizedBox(height: AppSpacing.sm),
          _tile(
            context,
            icon: Icons.admin_panel_settings_rounded,
            title: isSystemAdmin ? 'Central do admin' : 'Painel admin',
            onTap: () => onNavigateRoute('students'),
          ),
          if (isSystemAdmin)
            _tile(
              context,
              icon: Icons.swap_horiz_rounded,
              title: 'Trocar academia',
              onTap: () => onNavigateRoute('change_academy'),
            ),
        ],
        if (!isStaff) ...[
          const SizedBox(height: AppSpacing.lg),
          const EmptyState(
            icon: Icons.groups_rounded,
            title: 'Equipe',
            message:
                'Professores e administradores têm atalhos extras de gestão nesta aba.',
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _sectionTitle(context, 'Conta'),
        const SizedBox(height: AppSpacing.sm),
        _tile(
          context,
          icon: Icons.settings_rounded,
          title: 'Configurações',
          onTap: () => onNavigateRoute('settings'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _tile(
          context,
          icon: Icons.logout_rounded,
          title: 'Sair',
          destructive: true,
          onTap: () => onNavigateRoute('logout'),
        ),
      ],
    );
  }

  static Future<void> _push(BuildContext context, Widget page) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: cs.onSurfaceVariant,
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = destructive ? cs.error : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md - 2,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: destructive
                    ? cs.error.withValues(alpha: 0.08)
                    : cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: destructive
                      ? cs.error.withValues(alpha: 0.2)
                      : cs.outline.withValues(alpha: 0.22),
                ),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: destructive ? cs.error : cs.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
