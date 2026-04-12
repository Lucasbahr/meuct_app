import 'package:flutter/material.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/graduacao/bjj_graduacao.dart';
import '../../../core/api/dio_unauthorized.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/storage/gym_context_storage.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../gyms/screens/gym_select_page.dart';
import '../../training/services/training_service.dart';
import '../services/student_service.dart';
import '../services/checkin_service.dart';
import '../../../widgets/drawer_widget.dart';

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
  int? _diasTreinados;
  Map<String, dynamic>? _checkinSummary;
  List<Map<String, dynamic>> _trainingProgress = [];
  final _authRepository = AuthRepository();
  final _sessionService = SessionService();
  final _checkinService = CheckinService();
  final _trainingService = TrainingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    await _ensureSystemAdminGym();
    if (!mounted) return;
    await _loadRole();
    loadStudent();
    _loadCheckinStats();
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
      _loadTrainingProgress();

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

  Future<void> _loadCheckinStats() async {
    try {
      final history = await _checkinService.getHistory();
      final summary = await _checkinService.getSummary();
      if (!mounted) return;
      setState(() {
        _diasTreinados = CheckinService.countDistinctTrainingDays(history);
        _checkinSummary = summary;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _diasTreinados = null;
        _checkinSummary = null;
      });
    }
  }

  int? _studentIdFrom(Map<String, dynamic>? s) {
    if (s == null) return null;
    final id = s["id"];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse(id.toString());
  }

  Future<void> _loadTrainingProgress() async {
    final sid = _studentIdFrom(student);
    if (sid == null) return;
    try {
      final list = await _trainingService.getStudentProgress(sid);
      if (!mounted) return;
      setState(() => _trainingProgress = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _trainingProgress = []);
    }
  }

  String _fmtHours(dynamic v) {
    if (v == null) return "0";
    if (v is num) {
      final x = v.toDouble();
      return x == x.roundToDouble() ? "${x.round()}" : x.toStringAsFixed(1);
    }
    return v.toString();
  }

  Future<void> _logout() async {
    await _authRepository.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: Builder(
          builder: (menuContext) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(menuContext).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: AppDrawer(
        onNavigate: (route) async {
          Navigator.pop(context);

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
                    content: Text("Apenas administrador do sistema pode trocar a academia ativa."),
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
              await loadStudent();
              if (mounted) await _loadCheckinStats();
              break;
          }
        },
        isAdmin: _isAdmin,
        isStaff: _isStaff,
        isSystemAdmin: _isSystemAdmin,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : student == null
              ? (_isSystemAdmin
                  ? _buildSystemAdminWithoutStudent()
                  : const Center(child: Text("Erro")))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "GENESIS MMA",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD32F2F),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Muay Thai • Jiu-Jitsu • MMA",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Bem-vindo",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          student!["nome"] ?? "",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_academyLabel(student!) != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _academyLabel(student!)!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Seu status",
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _infoItem(
                                    "Graduação",
                                    graduationLabelFromStudent(student!),
                                  ),
                                  _infoItem(
                                    "Status",
                                    student!["status"] ?? "-",
                                  ),
                                ],
                              ),
                              if (_diasTreinados != null ||
                                  _checkinSummary != null) ...[
                                const SizedBox(height: 14),
                                const Divider(height: 1, color: Colors.white12),
                                const SizedBox(height: 12),
                                _infoItem(
                                  "Dias treinados",
                                  _diasTreinados != null
                                      ? "${_diasTreinados!} dia${_diasTreinados == 1 ? "" : "s"} com presença"
                                      : "-",
                                ),
                                if (_checkinSummary != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    "Frequência: ${_checkinSummary!["total_mes"] ?? 0} check-ins no mês · "
                                    "${_checkinSummary!["total_geral"] ?? 0} no total",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                              if (_trainingProgress.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const Divider(height: 1, color: Colors.white12),
                                const SizedBox(height: 12),
                                const Text(
                                  "Horas de treino (próxima graduação)",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ..._trainingProgress.map(_trainingProgressTile),
                              ],
                            ],
                          ),
                        ),
                        if (_trainingProgress.any((p) => p["eligible"] == true)) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () async {
                                await Navigator.pushNamed(
                                  context,
                                  "/graduation-schedule",
                                );
                                if (mounted) await _loadTrainingProgress();
                              },
                              icon: const Icon(Icons.event_available_outlined),
                              label: const Text("Agendar graduação"),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E1E1E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.white12),
                              ),
                            ),
                            onPressed: () async {
                              await Navigator.pushNamed(context, "/checkin");
                              if (mounted) {
                                await _loadCheckinStats();
                                await _loadTrainingProgress();
                              }
                            },
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: const Text("Fazer check-in"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _trainingProgressTile(Map<String, dynamic> p) {
    final name = (p["modality_name"] ?? "Modalidade").toString();
    final trained = p["hours_trained"];
    final required = p["required_hours"];
    final pct = p["progress_percent"];
    final pctVal = pct is num ? pct.toDouble() : double.tryParse("$pct") ?? 0.0;
    final eligible = p["eligible"] == true;
    final grad = (p["graduation_name"] ?? "").toString().trim();
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (eligible)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Meta atingida",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
            ],
          ),
          if (grad.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              grad,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            "${_fmtHours(trained)} h de ${_fmtHours(required)} h necessárias",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pctVal / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white12,
              color: primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${pctVal.toStringAsFixed(0)}% do caminho para a próxima graduação",
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
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
            const Text(
              "Sua conta não tem ficha de aluno na academia selecionada (comportamento esperado). "
              "Use o menu para abrir o painel admin, relatórios e demais ferramentas. "
              "Para atuar em outra academia, use \"Trocar academia\" no menu.",
              style: TextStyle(color: Colors.white70, height: 1.4),
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
                await loadStudent();
                if (mounted) await _loadCheckinStats();
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

  Widget _infoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
