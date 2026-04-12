import 'package:flutter/material.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../../widgets/loading_overlay.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../gym_schedule/gym_schedule_utils.dart';
import '../../gym_schedule/services/gym_schedule_service.dart';
import '../services/checkin_service.dart';

class CheckinCalendarPage extends StatefulWidget {
  const CheckinCalendarPage({super.key});

  @override
  State<CheckinCalendarPage> createState() => _CheckinCalendarPageState();
}

class _CheckinCalendarPageState extends State<CheckinCalendarPage> {
  final _service = CheckinService();
  final _schedule = GymScheduleService();
  final _auth = AuthRepository();

  bool _isLoading = true;
  bool _isCheckingIn = false;
  int? _checkingSlotId;

  DateTime _selectedDay = DateTime.now();
  DateTime _weekStart = _getWeekStart(DateTime.now());

  Map<DateTime, int> _checkinsByDay = {};
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _todaySlots = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  static DateTime _getWeekStart(DateTime date) {
    final mondayDelta = date.weekday - DateTime.monday;
    final start = date.subtract(Duration(days: mondayDelta));
    return DateTime(start.year, start.month, start.day);
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final history = await _service.getHistory();
      final summary = await _service.getSummary();
      final grouped = await _schedule.listScheduleGrouped(activeOnly: true);

      final map = <DateTime, int>{};
      for (final item in history) {
        final rawDate = item["date"];
        final total = (item["total"] as num?)?.toInt() ?? 0;
        if (rawDate is String) {
          final parsed = DateTime.tryParse(rawDate);
          if (parsed != null) {
            map[dateOnly(parsed)] = total;
          }
        }
      }

      final now = DateTime.now();
      final slots = slotsForApiWeekday(grouped, apiScheduleWeekday(now));

      if (!mounted) return;
      setState(() {
        _checkinsByDay = map;
        _summary = summary;
        _todaySlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (dioIsUnauthorized(e)) {
        await _auth.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  Future<void> _checkinForSlot(Map<String, dynamic> slot) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = dateOnly(_selectedDay);
    if (selected != today) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Selecione hoje no calendário para fazer check-in."),
        ),
      );
      return;
    }

    final idRaw = slot["id"];
    final slotId = idRaw is int ? idRaw : int.tryParse("$idRaw");
    if (slotId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Horário inválido.")),
      );
      return;
    }

    final ci = slot["class_info"];
    final name = ci is Map ? (ci["name"] ?? "Aula").toString() : "Aula";
    final start = (slot["start_time"] ?? "").toString();
    final end = (slot["end_time"] ?? "").toString();

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar check-in"),
        content: Text(
          "$name\n$start – $end\n\n"
          "As horas de treino creditadas seguem a duração desta aula na grade.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Check-in"),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;

    setState(() {
      _isCheckingIn = true;
      _checkingSlotId = slotId;
    });
    try {
      final data = await _service.doCheckin(scheduleSlotId: slotId);
      if (!mounted) return;
      final h = data["hours_credited"];
      final msg = h != null
          ? "Check-in ok! +${h.toString()} h creditadas na modalidade."
          : "Check-in realizado com sucesso!";
      messenger.showSnackBar(SnackBar(content: Text(msg)));
      await _refresh();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
          _checkingSlotId = null;
        });
      }
    }
  }

  Future<void> _shiftWeek(int deltaWeeks) async {
    final newStart = _weekStart.add(Duration(days: deltaWeeks * 7));
    setState(() {
      _weekStart = newStart;
      _selectedDay = newStart;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final days = List<DateTime>.generate(7, (i) => _weekStart.add(Duration(days: i)));

    final selectedTotal = _checkinsByDay[dateOnly(_selectedDay)] ?? 0;
    final diasComTreino = _checkinsByDay.values.where((t) => t > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Frequência"),
        actions: [
          IconButton(
            onPressed: () => _shiftWeek(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: () => _shiftWeek(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LoadingOverlay(
              visible: _isCheckingIn,
              message: 'Registrando check-in...',
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_summary != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Resumo",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    "Mês: ${_summary!["total_mes"] ?? 0} · "
                                    "Geral: ${_summary!["total_geral"] ?? 0}",
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Dias com check-in: $diasComTreino",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Semana",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: days.length,
                            itemBuilder: (context, index) {
                              final day = days[index];
                              final total = _checkinsByDay[dateOnly(day)] ?? 0;
                              final isSelected = dateOnly(day) ==
                                  dateOnly(_selectedDay);

                              return InkWell(
                                onTap: () {
                                  setState(() => _selectedDay = day);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primary.withValues(alpha: 0.22)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? primary : Colors.white10,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Text(
                                          "${day.day}",
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: total > 0
                                                ? primary
                                                : Colors.white12,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dia selecionado: ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Check-ins neste dia: $selectedTotal",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Check-in nas aulas de hoje",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Escolha o horário da grade em que você está treinando. "
                      "Você pode fazer mais de um por dia, em aulas diferentes. "
                      "É necessário estar no horário da aula (com tolerância).",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_todaySlots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          dateOnly(_selectedDay) == dateOnly(DateTime.now())
                              ? "Nenhuma aula na grade para hoje. "
                                  "Peça à administração para cadastrar horários em Painel admin → Academia."
                              : "Só é possível check-in no dia de hoje. "
                                  "Selecione a data atual no calendário.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ..._todaySlots.map((slot) {
                        final ci = slot["class_info"];
                        final name =
                            ci is Map ? (ci["name"] ?? "Aula").toString() : "Aula";
                        final start = (slot["start_time"] ?? "").toString();
                        final end = (slot["end_time"] ?? "").toString();
                        final room = (slot["room"] ?? "").toString();
                        final idRaw = slot["id"];
                        final sid = idRaw is int ? idRaw : int.tryParse("$idRaw");
                        final busy = _isCheckingIn && _checkingSlotId == sid;
                        final isToday =
                            dateOnly(_selectedDay) == dateOnly(DateTime.now());

                        return Card(
                          color: const Color(0xFF252525),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(name,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              [
                                "$start – $end",
                                if (room.isNotEmpty) room,
                              ].join(" · "),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: busy
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : FilledButton(
                                    onPressed: (!isToday || _isCheckingIn)
                                        ? null
                                        : () => _checkinForSlot(slot),
                                    child: const Text("Check-in"),
                                  ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}
