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
    final cs = Theme.of(context).colorScheme;
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
                      Text(
                        _error!,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text("Tentar novamente")),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_gami != null) ..._buildGami(context, _gami!),
                      if (_progress.any((p) => p["eligible"] == true)) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                Navigator.pushNamed(context, "/graduation-schedule"),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(Icons.school_outlined, color: cs.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Você está elegível para graduação. Toque para solicitar agendamento.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        "Progresso por modalidade",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_progress.isEmpty)
                        Text(
                          "Nenhuma modalidade vinculada ainda.",
                          style: TextStyle(color: cs.onSurfaceVariant),
                        )
                      else
                        ..._progress.map((p) => _progressTile(context, p)),
                    ],
                  ),
      ),
    );
  }

  List<Widget> _buildGami(BuildContext context, Map<String, dynamic> g) {
    final cs = Theme.of(context).colorScheme;
    final badges = g["badges"];
    return [
      Row(
        children: [
          Expanded(
            child: _statBox(context, "XP total", "${g["total_xp"] ?? 0}"),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statBox(context, "Nível", "${g["level"] ?? 0}"),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _statBox(context, "Streak atual", "${g["current_streak"] ?? 0}"),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statBox(context, "Melhor streak", "${g["best_streak"] ?? 0}"),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _statBox(
        context,
        "Posição no ranking",
        g["ranking_position"] != null ? "#${g["ranking_position"]}" : "—",
      ),
      if (g["last_training_date"] != null) ...[
        const SizedBox(height: 8),
        Text(
          "Último treino: ${g["last_training_date"]}",
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
      ],
      const SizedBox(height: 16),
      Text(
        "Conquistas",
        style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
      ),
      const SizedBox(height: 8),
      if (badges is List && badges.isNotEmpty)
        ...badges.map((raw) {
          if (raw is! Map) return const SizedBox.shrink();
          final b = Map<String, dynamic>.from(raw);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.military_tech, color: cs.primary),
            title: Text(b["name"]?.toString() ?? ""),
            subtitle: Text(b["description"]?.toString() ?? ""),
          );
        })
      else
        Text(
          "Nenhuma conquista ainda.",
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
    ];
  }

  Widget _statBox(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressTile(BuildContext context, Map<String, dynamic> p) {
    final cs = Theme.of(context).colorScheme;
    final pct = p["progress_percent"];
    final pctVal = pct is num ? pct.toDouble() : double.tryParse("$pct") ?? 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p["modality_name"]?.toString() ?? "Modalidade",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${p["graduation_name"] ?? ""} · "
              "${p["hours_trained"] ?? 0} / ${p["required_hours"] ?? 0} h",
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (pctVal / 100).clamp(0.0, 1.0),
              backgroundColor: cs.outline.withValues(alpha: 0.25),
              color: cs.primary,
            ),
            const SizedBox(height: 4),
            Text(
              "${pctVal.toStringAsFixed(1)}% · "
              "${(p["eligible"] == true) ? "Elegível à próxima graduação" : "Continue treinando"}",
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
