import 'package:flutter/material.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/storage/gym_context_storage.dart';
import '../../gyms/services/gym_service.dart';
import '../../tenant/services/tenant_service.dart';
import '../widgets/admin_shell.dart';
import 'academy_admin_page.dart';
import 'system_platform_page.dart';

/// Entrada separada para **admin de sistema**: plataforma (tenants) vs admin da academia ativa.
class SystemAdminHubPage extends StatefulWidget {
  const SystemAdminHubPage({super.key});

  @override
  State<SystemAdminHubPage> createState() => _SystemAdminHubPageState();
}

class _SystemAdminHubPageState extends State<SystemAdminHubPage> {
  int? _gymId;
  String? _gymName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final gid = await GymContextStorage.instance.getGymId();
    String? name;
    if (gid != null) {
      try {
        final cfg = await TenantService().getTenantConfig();
        final tenant = cfg["tenant"];
        if (tenant is Map) {
          final t = Map<String, dynamic>.from(tenant);
          final n = t["nome"] ?? t["name"];
          if (n is String && n.trim().isNotEmpty) name = n.trim();
        }
      } catch (_) {}
      if (name == null || name.isEmpty) {
        try {
          final list = await GymService().listGyms();
          for (final row in list) {
            if (GymService.parseGymId(row) == gid) {
              name = GymService.parseGymName(row);
              break;
            }
          }
        } catch (_) {}
      }
    }
    if (!mounted) return;
    setState(() {
      _gymId = gid;
      _gymName = name;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Central do administrador"),
        actions: [
          IconButton(
            tooltip: "Atualizar",
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: cs.tertiary),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                AdminHeroIntro(
                  icon: Icons.hub_outlined,
                  title: "Central do administrador",
                  subtitle:
                      "Plataforma (várias academias) fica separada do dia a dia de uma academia.",
                  trailing: _gymId != null
                      ? Chip(
                          avatar: const Icon(Icons.business, size: 18),
                          label: Text(
                            _gymName ?? "Academia",
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: cs.outline.withValues(alpha: 0.35),
                          ),
                        )
                      : Chip(
                          label: const Text("Sem academia ativa"),
                          backgroundColor: Colors.orange.withValues(alpha: 0.2),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                ),
                const SizedBox(height: 20),
                _hubCard(
                  context,
                  icon: Icons.cloud_outlined,
                  title: "Plataforma (tenants)",
                  subtitle:
                      "Trocar academia ativa, cadastrar nova academia, criar logins de equipe na academia selecionada.",
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const SystemPlatformPage(),
                      ),
                    );
                    await AppBrandingController.instance.refreshFromApi();
                    await _refresh();
                  },
                ),
                const SizedBox(height: 14),
                _hubCard(
                  context,
                  icon: Icons.groups_outlined,
                  title: "Administrar esta academia",
                  subtitle:
                      "Alunos, mensalidades, loja, grade — o mesmo painel usado pelo admin da academia.",
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const AcademyAdminPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _hubCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.tertiary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          "Abrir",
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: cs.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
