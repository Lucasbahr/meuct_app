import 'package:flutter/material.dart';

import '../../../core/auth/session_service.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/storage/gym_context_storage.dart';
import '../../gyms/screens/gym_select_page.dart';
import '../../gyms/services/gym_service.dart';
import '../../tenant/services/tenant_service.dart';
import '../services/admin_service.dart';
import '../widgets/admin_shell.dart';

/// Operações de **plataforma** para admin de sistema (tenants e usuários na academia ativa).
class SystemPlatformPage extends StatefulWidget {
  const SystemPlatformPage({super.key});

  @override
  State<SystemPlatformPage> createState() => _SystemPlatformPageState();
}

class _SystemPlatformPageState extends State<SystemPlatformPage> {
  final _session = SessionService();
  final _tenant = TenantService();
  final _admin = AdminService();

  bool _loadingGate = true;
  bool _allowed = false;
  int? _gymId;
  String? _gymName;

  @override
  void initState() {
    super.initState();
    _gate();
  }

  Future<void> _gate() async {
    final ok = await _session.isSystemAdmin();
    await _refreshGymLabel();
    if (!mounted) return;
    setState(() {
      _allowed = ok;
      _loadingGate = false;
    });
  }

  Future<void> _refreshGymLabel() async {
    final gid = await GymContextStorage.instance.getGymId();
    String? name;
    if (gid != null) {
      try {
        final cfg = await _tenant.getTenantConfig();
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
    });
  }

  Future<void> _pickGym() async {
    await Navigator.of(context).push<int>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const GymSelectPage(
          title: "Trocar academia ativa",
          barrierDismissible: true,
        ),
      ),
    );
    if (!mounted) return;
    await AppBrandingController.instance.refreshFromApi();
    await _refreshGymLabel();
  }

  Future<void> _createTenant() async {
    final nome = TextEditingController();
    final slug = TextEditingController();
    final cor = TextEditingController(text: "#E53935");
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nova academia (tenant)"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                decoration: const InputDecoration(
                  labelText: "Nome *",
                  hintText: "Ex.: Academia Centro",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: slug,
                decoration: const InputDecoration(
                  labelText: "Slug (opcional)",
                  hintText: "slug-da-academia",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cor,
                decoration: const InputDecoration(
                  labelText: "Cor primária (opcional)",
                  hintText: "#E53935",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(
            style: AdminPanelStyle.filledPrimary(ctx),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Criar"),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final n = nome.text.trim();
    if (n.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe o nome da academia.")),
      );
      return;
    }
    try {
      final data = await _tenant.createTenant(
        nome: n,
        slug: slug.text.trim().isEmpty ? null : slug.text.trim(),
        corPrimaria: cor.text.trim().isEmpty ? null : cor.text.trim(),
      );
      if (!mounted) return;
      final newId = data["id"];
      int? id;
      if (newId is int) id = newId;
      if (newId is num) id = newId.toInt();
      final slugOut = data["slug"]?.toString() ?? "";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Academia criada (id $newId, slug $slugOut).")),
      );
      if (id != null) {
        final use = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Academia ativa"),
            content: const Text(
              "Definir esta academia como ativa agora? O app passará a enviar X-Gym-Id para ela.",
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Depois")),
              FilledButton(
                style: AdminPanelStyle.filledPrimary(ctx),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Sim, usar agora"),
              ),
            ],
          ),
        );
        if (use == true) {
          await GymContextStorage.instance.setGymId(id);
          await AppBrandingController.instance.refreshFromApi();
          await _refreshGymLabel();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  Future<void> _provisionUser() async {
    if (_gymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Escolha uma academia ativa antes de criar usuários."),
        ),
      );
      return;
    }
    final email = TextEditingController();
    final password = TextEditingController();
    String role = "ADMIN_ACADEMIA";
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text("Novo usuário na academia ativa"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "${_gymName ?? "Academia ativa"} — conta já verificada; pode logar na hora.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: "E-mail *"),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Senha * (mín. 6)"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: "Perfil *"),
                  items: const [
                    DropdownMenuItem(value: "ADMIN_ACADEMIA", child: Text("Admin da academia")),
                    DropdownMenuItem(value: "PROFESSOR", child: Text("Professor")),
                    DropdownMenuItem(value: "ALUNO", child: Text("Aluno")),
                  ],
                  onChanged: (v) => setLocal(() => role = v ?? role),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
            FilledButton(
              style: AdminPanelStyle.filledPrimary(ctx),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Criar"),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final em = email.text.trim();
    final pw = password.text;
    if (em.isEmpty || pw.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("E-mail e senha (mín. 6) são obrigatórios.")),
      );
      return;
    }
    try {
      await _admin.provisionUser(email: em, password: pw, role: role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Usuário criado: $em ($role).")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingGate) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      );
    }
    if (!_allowed) {
      return Scaffold(
        appBar: AppBar(title: const Text("Plataforma")),
        body: const AdminAccessDeniedBody(),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Plataforma"),
        actions: [
          IconButton(
            tooltip: "Atualizar",
            onPressed: _refreshGymLabel,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AdminHeroIntro(
            icon: Icons.hub_outlined,
            title: "Operações de plataforma",
            subtitle:
                "Tenants e usuários na academia ativa. Branding, grade e loja ficam em "
                "\"Administrar esta academia\".",
            trailing: _gymId == null
                ? Chip(
                    avatar: Icon(Icons.warning_amber_outlined, size: 18, color: Colors.amber.shade200),
                    label: const Text("Sem academia ativa"),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )
                : Chip(
                    avatar: const Icon(Icons.fitness_center, size: 18),
                    label: Text(
                      "${_gymName ?? "Academia"} · #$_gymId",
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
          ),
          const SizedBox(height: 12),
          Card(
            color: cs.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Contexto da API",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _gymId == null
                        ? "Nenhuma academia selecionada — escolha uma para enviar X-Gym-Id nas chamadas."
                        : (_gymName ?? "Academia"),
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickGym,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text("Trocar academia ativa"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: cs.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Nova academia",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Registra uma nova academia no sistema.",
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: AdminPanelStyle.filledPrimary(context),
                    onPressed: _createTenant,
                    icon: const Icon(Icons.add_business),
                    label: const Text("Cadastrar nova academia"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: cs.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Delegar acesso",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Cria login na academia ativa (admin, professor ou aluno), já liberado para entrar.",
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: AdminPanelStyle.filledPrimary(context),
                    onPressed: _provisionUser,
                    icon: const Icon(Icons.person_add),
                    label: const Text("Criar usuário na academia ativa"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
