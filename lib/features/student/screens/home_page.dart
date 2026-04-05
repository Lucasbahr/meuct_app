import 'package:flutter/material.dart';
import '../../../core/graduacao/bjj_graduacao.dart';
import '../../../core/api/dio_unauthorized.dart';
import '../../../core/auth/session_service.dart';
import '../../auth/repositories/auth_repository.dart';
import '../services/student_service.dart';
import '../services/checkin_service.dart';
import '../../../widgets/drawer_widget.dart';
import '../../../widgets/loading_overlay.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? student;
  bool isLoading = true;
  bool _isAdmin = false;
  bool _redirectingToCompleteProfile = false;
  bool _isCheckingIn = false;
  int? _diasTreinados;
  Map<String, dynamic>? _checkinSummary;
  final _authRepository = AuthRepository();
  final _sessionService = SessionService();
  final _checkinService = CheckinService();

  @override
  void initState() {
    super.initState();
    _loadRole();
    loadStudent();
    _loadCheckinStats();
  }

  Future<void> _loadRole() async {
    final isAdmin = await _sessionService.isAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
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

            case "birthdays":
              Navigator.pushNamed(context, "/birthdays");
              break;

            case "students":
              if (!_isAdmin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Acesso restrito a administradores."),
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

            case "settings":
              Navigator.pushNamed(context, "/settings");
              break;

            case "logout":
              await _logout();
              break;
          }
        },
        isAdmin: _isAdmin,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : student == null
              ? const Center(child: Text("Erro"))
              : SafeArea(
                  child: LoadingOverlay(
                    visible: _isCheckingIn,
                    message: 'Registrando check-in...',
                    child: Padding(
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
                                    formatGraduacaoDisplay(
                                      (student!["graduacao"] ?? "").toString(),
                                    ),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _infoItem(
                          "Modalidade",
                          student!["modalidade"] ?? "-",
                        ),
                        const SizedBox(height: 10),
                        _infoItem(
                          "Telefone",
                          student!["telefone"] ?? "-",
                        ),
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
                            onPressed: _isCheckingIn
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    setState(() => _isCheckingIn = true);
                                    try {
                                      await _checkinService.doCheckin();
                                      if (!mounted) return;
                                      await _loadCheckinStats();
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text("Check-in realizado!"),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceFirst("Exception: ", ""),
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) setState(() => _isCheckingIn = false);
                                    }
                                  },
                            icon: Icon(
                              _isCheckingIn
                                  ? Icons.hourglass_top_rounded
                                  : Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: Text(
                              _isCheckingIn ? "Enviando check-in..." : "Fazer check-in",
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
    );
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
