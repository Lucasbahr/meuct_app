import 'package:flutter/material.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../student/services/student_service.dart';
import '../services/training_service.dart';

class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});

  @override
  State<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends State<GamificationPage> {
  final _studentService = StudentService();
  final _trainingService = TrainingService();
  final _authRepository = AuthRepository();

  Map<String, dynamic>? _gami;
  List<Map<String, dynamic>> _progress = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await _studentService.getMe();
      final idRaw = me["id"];
      final studentId = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? "");
      if (studentId == null) {
        throw Exception("Perfil de aluno sem id.");
      }

      final results = await Future.wait([
        _trainingService.getStudentGamification(studentId),
        _trainingService.getStudentProgress(studentId),
      ]);

      if (!mounted) return;
      setState(() {
        _gami = results[0] as Map<String, dynamic>;
        _progress = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (dioIsUnauthorized(e)) {
        await _authRepository.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gamificação")),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text("Tentar novamente")),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_gami != null) ..._buildGami(_gami!),
                      if (_progress.any((p) => p["eligible"] == true)) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: const Color(0xFF2A2418),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                Navigator.pushNamed(context, "/graduation-schedule"),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  const Icon(Icons.school_outlined,
                                      color: Color(0xFFE53935)),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      "Você está elegível para graduação. Toque para solicitar agendamento.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        "Progresso por modalidade",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_progress.isEmpty)
                        const Text(
                          "Nenhuma modalidade vinculada ainda.",
                          style: TextStyle(color: Colors.white54),
                        )
                      else
                        ..._progress.map(_progressTile),
                    ],
                  ),
      ),
    );
  }

  List<Widget> _buildGami(Map<String, dynamic> g) {
    final badges = g["badges"];
    return [
      Row(
        children: [
          Expanded(
            child: _statBox("XP total", "${g["total_xp"] ?? 0}"),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statBox("Nível", "${g["level"] ?? 0}"),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _statBox("Streak atual", "${g["current_streak"] ?? 0}"),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statBox("Melhor streak", "${g["best_streak"] ?? 0}"),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _statBox(
        "Posição no ranking",
        g["ranking_position"] != null ? "#${g["ranking_position"]}" : "—",
      ),
      if (g["last_training_date"] != null) ...[
        const SizedBox(height: 8),
        Text(
          "Último treino: ${g["last_training_date"]}",
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
      const SizedBox(height: 16),
      const Text(
        "Conquistas",
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
      ),
      const SizedBox(height: 8),
      if (badges is List && badges.isNotEmpty)
        ...badges.map((raw) {
          if (raw is! Map) return const SizedBox.shrink();
          final b = Map<String, dynamic>.from(raw);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.military_tech, color: Color(0xFFE53935)),
            title: Text(b["name"]?.toString() ?? ""),
            subtitle: Text(b["description"]?.toString() ?? ""),
          );
        })
      else
        const Text(
          "Nenhuma conquista ainda.",
          style: TextStyle(color: Colors.white54),
        ),
    ];
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressTile(Map<String, dynamic> p) {
    final pct = p["progress_percent"];
    final pctVal = pct is num ? pct.toDouble() : double.tryParse("$pct") ?? 0.0;
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p["modality_name"]?.toString() ?? "Modalidade",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "${p["graduation_name"] ?? ""} · "
              "${p["hours_trained"] ?? 0} / ${p["required_hours"] ?? 0} h",
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (pctVal / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              color: const Color(0xFFE53935),
            ),
            const SizedBox(height: 4),
            Text(
              "${pctVal.toStringAsFixed(1)}% · "
              "${(p["eligible"] == true) ? "Elegível à próxima graduação" : "Continue treinando"}",
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
