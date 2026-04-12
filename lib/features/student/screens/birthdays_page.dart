import 'package:flutter/material.dart';
import '../../admin/services/admin_service.dart';

class BirthdaysPage extends StatefulWidget {
  const BirthdaysPage({super.key});

  @override
  State<BirthdaysPage> createState() => _BirthdaysPageState();
}

class _BirthdaysPageState extends State<BirthdaysPage> {
  final _service = AdminService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final students = await _service.getStudents();
      if (!mounted) return;
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  DateTime? _parseBirthDate(Map<String, dynamic> s) {
    final raw = s["data_nascimento"] ?? s["nascimento"] ?? s["birth_date"];
    if (raw is! String || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  int? _calcAge(DateTime? birth) {
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    final hadBirthday = (now.month > birth.month) ||
        (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthday) age--;
    return age;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    final d = date.day.toString().padLeft(2, "0");
    final m = date.month.toString().padLeft(2, "0");
    final y = date.year.toString();
    return "$d/$m/$y";
  }

  List<Map<String, dynamic>> _birthdayToday() {
    final now = DateTime.now();
    return _students.where((s) {
      final b = _parseBirthDate(s);
      return b != null && b.day == now.day && b.month == now.month;
    }).toList();
  }

  List<Map<String, dynamic>> _birthdayMonth() {
    final now = DateTime.now();
    return _students.where((s) {
      final b = _parseBirthDate(s);
      return b != null && b.month == now.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = _birthdayToday();
    final month = _birthdayMonth();

    return Scaffold(
      appBar: AppBar(title: const Text("Aniversariantes")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      "Aniversariantes de hoje",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (today.isEmpty)
                      const ListTile(
                        dense: true,
                        title: Text("Nenhum aniversariante hoje."),
                      )
                    else
                      ...today.map((s) {
                        final b = _parseBirthDate(s);
                        final age = _calcAge(b);
                        return Card(
                          child: ListTile(
                            title: Text((s["nome"] ?? "Sem nome").toString()),
                            subtitle: Text(
                              "Nascimento: ${_formatDate(b)} • Idade: ${age?.toString() ?? "-"}",
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 14),
                    Text(
                      "Aniversariantes do mês",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (month.isEmpty)
                      const ListTile(
                        dense: true,
                        title: Text("Nenhum aniversariante neste mês."),
                      )
                    else
                      ...month.map((s) {
                        final b = _parseBirthDate(s);
                        final age = _calcAge(b);
                        return Card(
                          child: ListTile(
                            title: Text((s["nome"] ?? "Sem nome").toString()),
                            subtitle: Text(
                              "Nascimento: ${_formatDate(b)} • Idade: ${age?.toString() ?? "-"}",
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}
