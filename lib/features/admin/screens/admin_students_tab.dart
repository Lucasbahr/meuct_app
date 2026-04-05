import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'admin_edit_student_page.dart';
import 'admin_student_detail_page.dart';
import '../widgets/register_student_attendance.dart';

class AdminStudentsTab extends StatefulWidget {
  final AdminService service;
  const AdminStudentsTab({super.key, required this.service});

  @override
  State<AdminStudentsTab> createState() => _AdminStudentsTabState();
}

class _AdminStudentsTabState extends State<AdminStudentsTab> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _ranking = [];
  final Map<int, Map<String, dynamic>> _rankingByStudentId = {};
  final Map<String, Map<String, dynamic>> _rankingByNomeLower = {};
  final _searchController = TextEditingController();
  bool _onlyAthletes = false;
  /// Evita duplo envio e mostra progresso no item da lista.
  int? _busyCheckInStudentId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final students = await widget.service.getStudents();
      List<Map<String, dynamic>> ranking = [];
      try {
        ranking = await widget.service.getRanking();
      } catch (_) {
        ranking = [];
      }
      if (!mounted) return;
      setState(() {
        _students = students;
        _ranking = ranking;
        _reindexRanking();
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

  void _reindexRanking() {
    _rankingByStudentId.clear();
    _rankingByNomeLower.clear();
    for (final r in _ranking) {
      final sid = r['student_id'] ?? r['aluno_id'] ?? r['id'];
      if (sid is num) {
        _rankingByStudentId[sid.toInt()] = r;
      }
      final nome =
          (r['nome'] ?? r['aluno_nome'] ?? '').toString().trim().toLowerCase();
      if (nome.isNotEmpty) {
        _rankingByNomeLower[nome] = r;
      }
    }
  }

  Map<String, dynamic>? _rankingForStudent(Map<String, dynamic> s) {
    final id = s['id'];
    if (id is num) {
      final hit = _rankingByStudentId[id.toInt()];
      if (hit != null) return hit;
    }
    final nome = (s['nome'] ?? '').toString().trim().toLowerCase();
    return _rankingByNomeLower[nome];
  }

  int? _diasTreinoFromRow(Map<String, dynamic>? r) {
    if (r == null) return null;
    const keys = [
      'dias_treinados',
      'dias_com_treino',
      'dias_presenca',
      'dias',
      'distinct_days',
      'total_dias',
      'dias_distintos',
    ];
    for (final k in keys) {
      final v = r[k];
      if (v is num) return v.toInt();
    }
    return null;
  }

  int? _idOf(Map<String, dynamic> s) {
    final raw = s['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }

  int? _presencasFromRow(Map<String, dynamic>? r) {
    if (r == null) return null;
    for (final k in ['total', 'total_checkins', 'checkins', 'presencas']) {
      final v = r[k];
      if (v is num) return v.toInt();
    }
    return null;
  }

  int? _diasTreinoFromStudent(Map<String, dynamic> s) {
    for (final k in ['dias_treinados', 'dias_com_treino']) {
      final v = s[k];
      if (v is num) return v.toInt();
    }
    return null;
  }

  String _studentSubtitle(Map<String, dynamic> s) {
    final status = (s['status'] ?? '-').toString();
    final eAtleta = (s['e_atleta'] ?? false) == true;
    final birth = _parseBirthDate(s);
    final age = _calcAge(birth);
    final rank = _rankingForStudent(s);
    final dias = _diasTreinoFromStudent(s) ?? _diasTreinoFromRow(rank);
    final pres = _presencasFromRow(rank);

    final parts = <String>[status];
    if (dias != null) parts.add('Dias treino: $dias');
    if (pres != null) parts.add('Presenças: $pres');
    if (eAtleta) {
      parts.add('Nasc: ${_formatDate(birth)}');
      parts.add('Idade: ${age?.toString() ?? "-"}');
    }
    return parts.join(' • ');
  }

  List<Map<String, dynamic>> _filteredStudents() {
    final q = _searchController.text.trim().toLowerCase();
    return _students.where((s) {
      if (_onlyAthletes && (s["e_atleta"] ?? false) != true) return false;
      if (q.isEmpty) return true;
      final nome = (s["nome"] ?? "").toString().toLowerCase();
      final email = (s["email"] ?? "").toString().toLowerCase();
      return nome.contains(q) || email.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredStudents();

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _errorView(_error!)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: "Buscar aluno (nome ou email)",
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: _onlyAthletes,
                    onChanged: (v) => setState(() => _onlyAthletes = v),
                    title: const Text("Mostrar somente atletas"),
                  ),
                  const SizedBox(height: 10),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: Text("Nenhum aluno encontrado.")),
                    ),
                  ...list.map((s) {
                    final nome = (s["nome"] ?? "Sem nome").toString();
                    final eAtleta = (s["e_atleta"] ?? false) == true;
                    final sid = _idOf(s);
                    final checkinBusy = sid != null && _busyCheckInStudentId == sid;
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      child: ListTile(
                        title: Text(
                          nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          _studentSubtitle(s),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (eAtleta)
                              const Icon(Icons.star, color: Colors.yellow),
                            if (checkinBusy)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            else if (sid != null)
                              TextButton(
                                onPressed: () => registerStudentAttendance(
                                  context: context,
                                  service: widget.service,
                                  student: s,
                                  onBusy: (busy) {
                                    if (!mounted) return;
                                    setState(
                                      () => _busyCheckInStudentId =
                                          busy ? sid : null,
                                    );
                                  },
                                  onSuccess: () {
                                    if (mounted) _load();
                                  },
                                ),
                                child: const Text('Check-in'),
                              ),
                            IconButton(
                              tooltip: "Editar",
                              onPressed: () async {
                                final result = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => AdminEditStudentPage(
                                      service: widget.service,
                                      student: s,
                                    ),
                                  ),
                                );
                                if (result == true && mounted) {
                                  await _load();
                                }
                              },
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => AdminStudentDetailPage(
                                service: widget.service,
                                student: s,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            await _load();
                          }
                        },
                      ),
                    );
                  }),
                ],
              );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message.replaceFirst("Exception: ", ""),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

