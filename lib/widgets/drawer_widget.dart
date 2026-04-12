import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final Function(String route) onNavigate;
  final bool isAdmin;
  final bool isStaff;
  final bool isSystemAdmin;

  const AppDrawer({
    super.key,
    required this.onNavigate,
    required this.isAdmin,
    this.isStaff = false,
    this.isSystemAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2B2B2B),
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: const Color(0xFF343434),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "GENESIS MMA",
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Menu principal",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          _item(Icons.home, "☰ Início", "home"),
          _item(Icons.person, "👤 Meus dados", "profile"),
          _item(Icons.cake_outlined, "🎂 Aniversariantes", "birthdays"),
          _item(Icons.check_circle, "📊 Frequência", "checkin"),
          _item(Icons.calendar_month, "📅 Calendário de aulas", "schedule_calendar"),
          _item(Icons.sports_mma, "🥋 Atletas", "athletes"),
          if (isAdmin)
            _item(
              Icons.admin_panel_settings,
              isSystemAdmin ? "⚙️ Central do admin" : "⚙️ Painel admin",
              "students",
            ),
          if (isSystemAdmin)
            _item(Icons.swap_horiz, "🔄 Trocar academia", "change_academy"),
          _item(Icons.emoji_events_outlined, "🏆 Gamificação", "gamification"),
          _item(Icons.school_outlined, "🎓 Graduação", "graduation"),
          _item(Icons.leaderboard_outlined, "🥇 Ranking", "ranking"),
          _item(Icons.feed, "📰 Feed", "feed"),
          _item(Icons.storefront_outlined, "🛒 Loja", "marketplace"),
          if (isStaff) ...[
            const Divider(color: Colors.white24),
            _item(Icons.apartment, "🏢 Painel da academia", "dashboard-academy"),
            _item(Icons.point_of_sale, "💰 Vendas (loja)", "dashboard-sales"),
          ],
          _item(Icons.settings, "⚙️ Configurações", "settings"),

          const Divider(color: Colors.white24),

          _item(Icons.logout, "🚪 Sair", "logout"),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFE53935)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => onNavigate(route),
    );
  }
}