import 'package:flutter/material.dart';
import '../../../widgets/loading_overlay.dart';
import '../services/checkin_service.dart';

class CheckinCalendarPage extends StatefulWidget {
  const CheckinCalendarPage({super.key});

  @override
  State<CheckinCalendarPage> createState() => _CheckinCalendarPageState();
}

class _CheckinCalendarPageState extends State<CheckinCalendarPage> {
  final _service = CheckinService();
  bool _isLoading = true;
  bool _isCheckingIn = false;

  DateTime _selectedDay = DateTime.now();
  DateTime _weekStart = _getWeekStart(DateTime.now());

  Map<DateTime, int> _checkinsByDay = {};
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  static DateTime _getWeekStart(DateTime date) {
    final mondayDelta = date.weekday - DateTime.monday; // Mon=0
    final start = date.subtract(Duration(days: mondayDelta));
    return DateTime(start.year, start.month, start.day);
  }

  DateTime _toDateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final history = await _service.getHistory();
      final summary = await _service.getSummary();

      final map = <DateTime, int>{};
      for (final item in history) {
        final rawDate = item["date"];
        final total = (item["total"] as num?)?.toInt() ?? 0;
        if (rawDate is String) {
          final parsed = DateTime.tryParse(rawDate);
          if (parsed != null) {
            map[_toDateOnly(parsed)] = total;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _checkinsByDay = map;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  Future<void> _checkinIfAllowed() async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = _toDateOnly(_selectedDay);
    if (selected != today) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Selecione a data de hoje para check-in.")),
      );
      return;
    }

    setState(() => _isCheckingIn = true);
    try {
      await _service.doCheckin();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text("Check-in realizado com sucesso!")),
      );
      await _refresh();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
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
    final days = List<DateTime>.generate(7, (i) => _weekStart.add(Duration(days: i)));

    final selectedTotal = _checkinsByDay[_toDateOnly(_selectedDay)] ?? 0;
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
                            "Dias treinados: $diasComTreino "
                            "(dias distintos com pelo menos um check-in)",
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
                            final total = _checkinsByDay[_toDateOnly(day)] ?? 0;
                            final isSelected = _toDateOnly(day) ==
                                _toDateOnly(_selectedDay);

                            return InkWell(
                              onTap: () {
                                setState(() => _selectedDay = day);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFD32F2F).withOpacity(0.25)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFD32F2F) : Colors.white10,
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
                                          color: isSelected ? Colors.white : Colors.white70,
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
                                              ? const Color(0xFFD32F2F)
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
                          "Check-in: $selectedTotal",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCheckingIn ? null : _checkinIfAllowed,
                      icon: const Icon(Icons.check),
                      label: Text(_isCheckingIn ? "Realizando..." : "FAZER CHECK-IN"),
                    ),
                  ),
                ],
              ),
              ),
            ),
    );
  }
}

