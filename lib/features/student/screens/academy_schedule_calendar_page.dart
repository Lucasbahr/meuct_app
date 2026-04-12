import 'package:flutter/material.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../gym_schedule/gym_schedule_utils.dart';
import '../../gym_schedule/services/gym_schedule_service.dart';

const _mesesPt = <String>[
  "Janeiro",
  "Fevereiro",
  "Março",
  "Abril",
  "Maio",
  "Junho",
  "Julho",
  "Agosto",
  "Setembro",
  "Outubro",
  "Novembro",
  "Dezembro",
];

const _diasSemanaPt = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"];

/// Calendário mensal com aulas da grade (`GET /gym-schedule?grouped=true`).
class AcademyScheduleCalendarPage extends StatefulWidget {
  const AcademyScheduleCalendarPage({super.key});

  @override
  State<AcademyScheduleCalendarPage> createState() =>
      _AcademyScheduleCalendarPageState();
}

class _AcademyScheduleCalendarPageState
    extends State<AcademyScheduleCalendarPage> {
  final _schedule = GymScheduleService();
  final _auth = AuthRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _grouped = [];

  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
    _selected = dateOnly(n);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final grouped = await _schedule.listScheduleGrouped(activeOnly: true);
      if (!mounted) return;
      setState(() {
        _grouped = grouped;
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

  int _classCountForDay(DateTime day) {
    return slotsForApiWeekday(_grouped, apiScheduleWeekday(day)).length;
  }

  List<Map<String, dynamic>> _slotsForDay(DateTime day) {
    return slotsForApiWeekday(_grouped, apiScheduleWeekday(day));
  }

  void _shiftMonth(int delta) {
    setState(() {
      final nm = DateTime(_month.year, _month.month + delta);
      _month = DateTime(nm.year, nm.month);
      final lastDay = DateTime(_month.year, _month.month + 1, 0).day;
      final day = _selected.day > lastDay ? lastDay : _selected.day;
      _selected = DateTime(_month.year, _month.month, day);
    });
  }

  Widget _dayIndicators(int count, Color primary) {
    if (count == 0) {
      return const SizedBox(height: 14);
    }
    const maxDots = 3;
    final dots = count > maxDots ? maxDots : count;
    final extra = count > maxDots ? count - maxDots : 0;
    final colors = [
      primary,
      primary.withValues(alpha: 0.75),
      const Color(0xFF26A69A),
      const Color(0xFFFFB74D),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < dots; i++)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                shape: BoxShape.circle,
              ),
            ),
          if (extra > 0)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                "+$extra",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: primary.withValues(alpha: 0.9),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final today = dateOnly(DateTime.now());
    final grid = monthCalendarGrid(_month);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendário de aulas"),
        actions: [
          IconButton(
            onPressed: () => _shiftMonth(-1),
            icon: const Icon(Icons.chevron_left),
            tooltip: "Mês anterior",
          ),
          IconButton(
            onPressed: () => _shiftMonth(1),
            icon: const Icon(Icons.chevron_right),
            tooltip: "Próximo mês",
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text("Tentar novamente"),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Center(
                        child: Text(
                          "${_mesesPt[_month.month - 1]} ${_month.year}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                for (final w in _diasSemanaPt)
                                  Expanded(
                                    child: Text(
                                      w,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(
                                          alpha: 0.55,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                childAspectRatio: 0.68,
                              ),
                              itemCount: grid.length,
                              itemBuilder: (context, index) {
                                final cell = grid[index];
                                if (cell == null) {
                                  return const SizedBox.shrink();
                                }
                                final n = _classCountForDay(cell);
                                final sel = dateOnly(cell) == dateOnly(_selected);
                                final isToday = dateOnly(cell) == today;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () =>
                                        setState(() => _selected = dateOnly(cell)),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: sel
                                              ? primary
                                              : isToday
                                                  ? primary.withValues(
                                                      alpha: 0.45,
                                                    )
                                                  : Colors.white12,
                                          width: sel ? 2 : 1,
                                        ),
                                        color: sel
                                            ? primary.withValues(alpha: 0.14)
                                            : isToday
                                                ? primary.withValues(alpha: 0.06)
                                                : Colors.black26,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 2,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "${cell.day}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: sel
                                                  ? Colors.white
                                                  : Colors.white70,
                                            ),
                                          ),
                                          _dayIndicators(n, primary),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(Icons.event_note, color: primary, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Aulas em ${_selected.day.toString().padLeft(2, '0')}/"
                              "${_selected.month.toString().padLeft(2, '0')}/${_selected.year}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Cada ponto no calendário indica aulas naquele dia da semana "
                        "(repetem todas as semanas). Toque em outro dia para ver os horários.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ..._buildDaySlotList(primary),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildDaySlotList(Color primary) {
    final slots = _slotsForDay(_selected);
    if (slots.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text(
              "Nenhuma aula na grade para ${_diasSemanaPt[apiScheduleWeekday(_selected)]}.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ),
      ];
    }

    return slots.map((slot) {
      final ci = slot["class_info"];
      final name =
          ci is Map ? (ci["name"] ?? "Aula").toString() : "Aula";
      final inst = ci is Map
          ? (ci["instructor_name"] ?? "").toString().trim()
          : "";
      final st = (slot["start_time"] ?? "").toString();
      final et = (slot["end_time"] ?? "").toString();
      final room = (slot["room"] ?? "").toString().trim();

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$st – $et",
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (inst.isNotEmpty || room.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (inst.isNotEmpty) "Prof. $inst",
                            if (room.isNotEmpty) room,
                          ].join(" · "),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
