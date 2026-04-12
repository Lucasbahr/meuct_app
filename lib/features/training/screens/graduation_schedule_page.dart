import 'package:flutter/material.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../auth/repositories/auth_repository.dart';
import '../services/training_service.dart';

const _kAccent = Color(0xFFE53935);

/// Aluno: quando elegível (`eligible_for_promotion`), solicita agendamento de graduação.
class GraduationSchedulePage extends StatefulWidget {
  const GraduationSchedulePage({super.key});

  @override
  State<GraduationSchedulePage> createState() => _GraduationSchedulePageState();
}

class _GraduationSchedulePageState extends State<GraduationSchedulePage> {
  final _training = TrainingService();
  final _auth = AuthRepository();

  List<Map<String, dynamic>> _rows = [];
  String? _error;
  bool _loading = true;
  int? _submittingModalityId;

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
      final list = await _training.getMyGraduationEligibility();
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (dioIsUnauthorized(e)) {
        await _auth.logout();
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

  Future<void> _submit(int modalityId, String modalityLabel) async {
    DateTime? picked;
    final noteCtrl = TextEditingController();

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text("Agendar graduação"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  modalityLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setLocal(() => picked = d);
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    picked == null
                        ? "Preferência de data (opcional)"
                        : "${picked!.year}-${picked!.month.toString().padLeft(2, "0")}-${picked!.day.toString().padLeft(2, "0")}",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Observação (opcional)",
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Enviar pedido"),
            ),
          ],
        ),
      ),
    );
    if (go != true || !mounted) return;

    String? iso;
    if (picked != null) {
      iso =
          "${picked!.year}-${picked!.month.toString().padLeft(2, "0")}-${picked!.day.toString().padLeft(2, "0")}";
    }

    setState(() => _submittingModalityId = modalityId);
    try {
      await _training.requestGraduation(
        modalityId: modalityId,
        preferredDateIso: iso,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Pedido enviado. A equipe verá na auditoria do painel admin.",
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _submittingModalityId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Graduação")),
      body: RefreshIndicator(
        color: _kAccent,
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator(color: _kAccent)),
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
                      const Text(
                        "Quando você completar as horas da faixa atual, pode solicitar "
                        "agendamento da cerimônia de graduação. A academia confirma o horário.",
                        style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      if (_rows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              "Nenhuma modalidade vinculada ao seu perfil.",
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                        )
                      else
                        ..._rows.map((r) {
                          final eligible = r["eligible_for_promotion"] == true;
                          final mid = r["modality_id"];
                          final modalityId = mid is int ? mid : int.tryParse(mid?.toString() ?? "");
                          final mname =
                              (r["modality_name"] ?? "Modalidade #$mid").toString();
                          final current =
                              (r["current_graduation_name"] ?? "—").toString();
                          final nxt = r["next_graduation"];
                          Map<String, dynamic>? nextMap;
                          if (nxt is Map) nextMap = Map<String, dynamic>.from(nxt);
                          final nextName = nextMap?["name"]?.toString() ?? "—";
                          final busy = modalityId != null &&
                              _submittingModalityId == modalityId;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: eligible
                                      ? _kAccent.withValues(alpha: 0.45)
                                      : Colors.white10,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mname,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Faixa atual: $current",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Próxima: $nextName",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (eligible && modalityId != null)
                                    FilledButton.icon(
                                      onPressed: busy
                                          ? null
                                          : () => _submit(modalityId, mname),
                                      icon: busy
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.event_available_outlined),
                                      label: Text(
                                        busy ? "Enviando..." : "Solicitar agendamento",
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _kAccent,
                                      ),
                                    )
                                  else
                                    Text(
                                      nextMap == null
                                          ? "Não há próxima faixa cadastrada na API."
                                          : "Complete as horas necessárias para solicitar.",
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.45),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
