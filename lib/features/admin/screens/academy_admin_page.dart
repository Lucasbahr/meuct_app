import 'package:flutter/material.dart';

import '../../tenant/services/tenant_service.dart';
import '../services/admin_service.dart';
import 'admin_academy_tab.dart';
import 'admin_attendance_tab.dart';
import 'admin_commercial_tab.dart';
import 'admin_dashboard_tab.dart';
import 'admin_plans_tab.dart';
import 'admin_students_tab.dart';

/// Painel operacional da **academia ativa** (admin academia, professor com permissões, ou admin sistema com `X-Gym-Id`).
class AcademyAdminPage extends StatefulWidget {
  const AcademyAdminPage({super.key});

  @override
  State<AcademyAdminPage> createState() => _AcademyAdminPageState();
}

class _AcademyAdminPageState extends State<AcademyAdminPage> {
  final _service = AdminService();
  late Future<List<Map<String, dynamic>>> _rankingFuture;
  int _studentsReloadToken = 0;
  String? _tenantName;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _service.getRanking();
    _loadTenantName();
  }

  Future<void> _loadTenantName() async {
    try {
      final cfg = await TenantService().getTenantConfig();
      final tenant = cfg["tenant"];
      if (tenant is Map) {
        final t = Map<String, dynamic>.from(tenant);
        final n = t["nome"] ?? t["name"];
        if (n is String && n.trim().isNotEmpty && mounted) {
          setState(() => _tenantName = n.trim());
        }
      }
    } catch (_) {}
  }

  void _reload() {
    _loadTenantName();
    setState(() {
      _studentsReloadToken++;
      _rankingFuture = _service.getRanking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Painel da academia"),
              Text(
                _tenantName ?? "Resumo, pessoas, financeiro e loja",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: "Atualizar ranking e listas",
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            dividerColor: Colors.white.withValues(alpha: 0.08),
            indicatorColor: accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            splashBorderRadius: BorderRadius.circular(8),
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(
                icon: Icon(Icons.dashboard_outlined, size: 20),
                text: "Resumo",
                height: 56,
              ),
              Tab(
                icon: Icon(Icons.apartment_outlined, size: 20),
                text: "Academia",
                height: 56,
              ),
              Tab(
                icon: Icon(Icons.groups_outlined, size: 20),
                text: "Alunos",
                height: 56,
              ),
              Tab(
                icon: Icon(Icons.payments_outlined, size: 20),
                text: "Mensalidades",
                height: 56,
              ),
              Tab(
                icon: Icon(Icons.event_available_outlined, size: 20),
                text: "Presença",
                height: 56,
              ),
              Tab(
                icon: Icon(Icons.storefront_outlined, size: 20),
                text: "Comercial",
                height: 56,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const AdminDashboardTab(),
            const AdminAcademyTab(),
            AdminStudentsTab(
              key: ValueKey(_studentsReloadToken),
              service: _service,
            ),
            const AdminPlansTab(),
            AdminAttendanceTab(
              rankingFuture: _rankingFuture,
              onRefresh: _reload,
            ),
            const AdminCommercialTab(),
          ],
        ),
      ),
    );
  }
}
