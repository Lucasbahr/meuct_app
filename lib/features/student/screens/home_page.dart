import 'package:flutter/material.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/api/dio_unauthorized.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/storage/gym_context_storage.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../gyms/screens/gym_select_page.dart';
import '../services/student_service.dart';
import '../../gym_home/gym_home_shell.dart';
import '../../tenant/services/tenant_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? student;
  bool isLoading = true;
  bool _isAdmin = false;
  bool _isStaff = false;
  bool _isSystemAdmin = false;
  bool _redirectingToCompleteProfile = false;
  final _authRepository = AuthRepository();
  final _sessionService = SessionService();
  /// Nome da academia vindo de `GET /tenant/config` (prioridade sobre campos do aluno).
  String? _tenantDisplayName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    await _ensureSystemAdminGym();
    if (!mounted) return;
    await _loadRole();
    await Future.wait<void>([
      loadStudent(),
      _loadTenantDisplayName(),
    ]);
  }

  /// Admin sistema: API exige `X-Gym-Id` quando o usuário não tem gym fixo no token.
  Future<void> _ensureSystemAdminGym() async {
    if (!await _sessionService.isSystemAdmin()) return;
    var gid = await GymContextStorage.instance.getGymId();
    final fromToken = await _sessionService.getGymIdFromToken();
    if (gid == null && fromToken != null) {
      await GymContextStorage.instance.setGymId(fromToken);
      gid = fromToken;
    }
    if (gid != null) return;
    if (!mounted) return;
    await Navigator.of(context).push<int>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const GymSelectPage(barrierDismissible: false),
      ),
    );
    if (!mounted) return;
    await AppBrandingController.instance.refreshFromApi();
  }

  Future<void> _loadRole() async {
    final isAdmin = await _sessionService.isAdmin();
    final isStaff = await _sessionService.isStaff();
    final isSys = await _sessionService.isSystemAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _isStaff = isStaff;
      _isSystemAdmin = isSys;
    });
  }

  Future<void> loadStudent() async {
    try {
      final data = await StudentService().getMe();
      if (!mounted) return;
      setState(() {
        student = data;
        isLoading = false;
      });

      final nome = (data["nome"] ?? "").toString().trim();
      if (nome.isEmpty && !_redirectingToCompleteProfile) {
        _redirectingToCompleteProfile = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, "/complete-profile");
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (dioIsUnauthorized(e)) {
        await _authRepository.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
        return;
      }
      final sys = await _sessionService.isSystemAdmin();
      if (dioIsNotFound(e) && sys) {
        setState(() {
          student = null;
          isLoading = false;
        });
        return;
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authRepository.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }

  Future<void> _onMoreNavigate(String route) async {
    switch (route) {
      case "home":
        break;

      case "profile":
        Navigator.pushNamed(context, "/profile");
        break;

      case "checkin":
        Navigator.pushNamed(context, "/checkin");
        break;

      case "schedule_calendar":
        Navigator.pushNamed(context, "/schedule-calendar");
        break;

      case "birthdays":
        Navigator.pushNamed(context, "/birthdays");
        break;

      case "students":
        if (!_isAdmin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Acesso restrito ao painel admin."),
            ),
          );
          break;
        }
        Navigator.pushNamed(context, "/admin");
        break;

      case "feed":
        Navigator.pushNamed(context, "/feed");
        break;

      case "athletes":
        Navigator.pushNamed(context, "/athletes");
        break;

      case "marketplace":
        Navigator.pushNamed(context, "/marketplace");
        break;

      case "gamification":
        Navigator.pushNamed(context, "/gamification");
        break;

      case "graduation":
        Navigator.pushNamed(context, "/graduation-schedule");
        break;

      case "ranking":
        Navigator.pushNamed(context, "/ranking");
        break;

      case "dashboard-academy":
        if (!_isStaff) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Acesso restrito à equipe da academia."),
            ),
          );
          break;
        }
        Navigator.pushNamed(context, "/dashboard-academy");
        break;

      case "dashboard-sales":
        if (!_isStaff) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Acesso restrito à equipe da academia."),
            ),
          );
          break;
        }
        Navigator.pushNamed(context, "/dashboard-sales");
        break;

      case "dashboard-analytics":
        if (!_isStaff) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Acesso restrito à equipe da academia."),
            ),
          );
          break;
        }
        Navigator.pushNamed(context, "/dashboard-analytics");
        break;

      case "settings":
        Navigator.pushNamed(context, "/settings");
        break;

      case "logout":
        await _logout();
        break;

      case "change_academy":
        if (!_isSystemAdmin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Apenas administrador do sistema pode trocar a academia ativa.",
              ),
            ),
          );
          break;
        }
        await Navigator.of(context).push<int>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const GymSelectPage(
              title: "Trocar academia",
              barrierDismissible: true,
            ),
          ),
        );
        if (!mounted) return;
        await AppBrandingController.instance.refreshFromApi();
        setState(() => isLoading = true);
        await Future.wait<void>([
          loadStudent(),
          _loadTenantDisplayName(),
        ]);
        break;
    }
  }

  Future<void> _loadTenantDisplayName() async {
    try {
      final cfg = await TenantService().getTenantConfig();
      String? name;
      final tenant = cfg['tenant'];
      if (tenant is Map) {
        final t = Map<String, dynamic>.from(tenant);
        final n = t['nome'] ?? t['name'] ?? t['display_name'];
        if (n is String && n.trim().isNotEmpty) name = n.trim();
      }
      for (final k in ['gym_name', 'nome', 'name', 'tenant_name', 'academy_name']) {
        if (name != null) break;
        final v = cfg[k];
        if (v is String && v.trim().isNotEmpty) name = v.trim();
      }
      if (!mounted) return;
      setState(() => _tenantDisplayName = name);
    } catch (_) {
      if (!mounted) return;
      setState(() => _tenantDisplayName = null);
    }
  }

  String _homeAppBarTitle() {
    final t = _tenantDisplayName?.trim();
    if (t != null && t.isNotEmpty) return t;
    if (student != null) {
      final fromStudent = _academyLabel(student!);
      if (fromStudent != null && fromStudent.isNotEmpty) return fromStudent;
    }
    return 'MeuCT';
  }

  String? _academyNameForShell() {
    final t = _tenantDisplayName?.trim();
    if (t != null && t.isNotEmpty) return t;
    if (student != null) return _academyLabel(student!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_homeAppBarTitle()),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : student == null
              ? (_isSystemAdmin
                  ? _buildSystemAdminWithoutStudent()
                  : const Center(child: Text("Erro")))
              : GymHomeShell(
                  isAdmin: _isAdmin,
                  isStaff: _isStaff,
                  isSystemAdmin: _isSystemAdmin,
                  onMoreNavigate: _onMoreNavigate,
                  student: student,
                  academyName: _academyNameForShell(),
                ),
    );
  }

  Widget _buildSystemAdminWithoutStudent() {
    final primary = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.admin_panel_settings_outlined, size: 48, color: primary),
            const SizedBox(height: 16),
            Text(
              "Administrador do sistema",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              "Sua conta não tem ficha de aluno na academia selecionada (comportamento esperado). "
              "Use os botões abaixo para o painel admin ou para trocar de academia. "
              "Com perfil de aluno, a aba Mais concentra atalhos e configurações.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, "/admin"),
              icon: const Icon(Icons.settings),
              label: const Text("Abrir painel admin"),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push<int>(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const GymSelectPage(
                      title: "Trocar academia",
                      barrierDismissible: true,
                    ),
                  ),
                );
                if (!mounted) return;
                await AppBrandingController.instance.refreshFromApi();
                setState(() => isLoading = true);
                await Future.wait<void>([
                  loadStudent(),
                  _loadTenantDisplayName(),
                ]);
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text("Trocar academia"),
            ),
          ],
        ),
      ),
    );
  }

  String? _academyLabel(Map<String, dynamic> s) {
    final keys = [
      "gym_name",
      "academy_name",
      "nome_academia",
      "academia",
    ];
    for (final k in keys) {
      final v = s[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    final id = s["gym_id"];
    if (id is int) return "Academia #$id";
    if (id is String && id.isNotEmpty) return "Academia #$id";
    return null;
  }
}
