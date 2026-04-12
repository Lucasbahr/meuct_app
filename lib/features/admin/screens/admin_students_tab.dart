import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'admin_edit_student_page.dart';
import 'admin_student_detail_page.dart';
import '../widgets/register_student_attendance.dart';

const _kAccent = Color(0xFFE53935);
const _kCardBg = Color(0xFF1A1A1A);

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

  String _initials(String nome) {
    final t = nome.trim();
    if (t.isEmpty) return "?";
    final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return t.substring(0, 1).toUpperCase();
  }

  Widget _metaChip(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _studentCard(Map<String, dynamic> s) {
    final nome = (s["nome"] ?? "Sem nome").toString();
    final eAtleta = (s["e_atleta"] ?? false) == true;
    final sid = _idOf(s);
    final checkinBusy = sid != null && _busyCheckInStudentId == sid;
    final status = (s['status'] ?? '—').toString();
    final rank = _rankingForStudent(s);
    final dias = _diasTreinoFromStudent(s) ?? _diasTreinoFromRow(rank);
    final pres = _presencasFromRow(rank);
    final birth = _parseBirthDate(s);
    final age = _calcAge(birth);

    final chips = <Widget>[
      _metaChip(status, icon: Icons.flag_outlined),
      if (dias != null) _metaChip("$dias dias de treino", icon: Icons.calendar_today_outlined),
      if (pres != null) _metaChip("$pres presenças", icon: Icons.how_to_reg_outlined),
      if (eAtleta) ...[
        _metaChip("Atleta", icon: Icons.sports_mma),
        _metaChip("${age ?? "—"} anos", icon: Icons.cake_outlined),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => AdminStudentDetailPage(
                  service: widget.service,
                  student: s,
                ),
              ),
            );
            if (result == true && mounted) await _load();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF2C2C2C),
                        child: Text(
                          _initials(nome),
                          style: const TextStyle(
                            color: _kAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                if (eAtleta)
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFCA28),
                                    size: 22,
                                  ),
                              ],
                            ),
                            if ((s['email'] ?? '').toString().trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                (s['email'] ?? '').toString(),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: chips,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      if (sid != null)
                        TextButton.icon(
                          onPressed: checkinBusy
                              ? null
                              : () => registerStudentAttendance(
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
                          icon: checkinBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_outline, size: 20),
                          label: const Text("Check-in"),
                          style: TextButton.styleFrom(foregroundColor: _kAccent),
                        ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => AdminEditStudentPage(
                                service: widget.service,
                                student: s,
                              ),
                            ),
                          );
                          if (result == true && mounted) await _load();
                        },
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text("Editar"),
                      ),
                      IconButton(
                        tooltip: "Abrir ficha",
                        onPressed: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => AdminStudentDetailPage(
                                service: widget.service,
                                student: s,
                              ),
                            ),
                          );
                          if (result == true && mounted) await _load();
                        },
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: Colors.white.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(
                _error!.replaceFirst("Exception: ", ""),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text("Tentar novamente"),
                style: FilledButton.styleFrom(backgroundColor: _kAccent),
              ),
            ],
          ),
        ),
      );
    }

    final list = _filteredStudents();

    return RefreshIndicator(
      color: _kAccent,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _kAccent.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _kAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.groups_outlined, color: _kAccent, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Gestão da academia",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${list.length} ${_students.length == list.length ? "membros" : "resultados"} · ${_students.length} no total",
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _kCardBg,
                      hintText: "Buscar por nome ou e-mail",
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kAccent, width: 1.2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Todos"),
                        selected: !_onlyAthletes,
                        onSelected: (_) => setState(() => _onlyAthletes = false),
                        selectedColor: _kAccent.withValues(alpha: 0.35),
                        labelStyle: TextStyle(
                          color: !_onlyAthletes ? Colors.white : Colors.white70,
                          fontWeight: !_onlyAthletes ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: const BorderSide(color: Colors.white24),
                        showCheckmark: false,
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("Só atletas"),
                        selected: _onlyAthletes,
                        onSelected: (_) => setState(() => _onlyAthletes = true),
                        selectedColor: _kAccent.withValues(alpha: 0.35),
                        labelStyle: TextStyle(
                          color: _onlyAthletes ? Colors.white : Colors.white70,
                          fontWeight: _onlyAthletes ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: const BorderSide(color: Colors.white24),
                        showCheckmark: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  _students.isEmpty
                      ? "Nenhum membro cadastrado."
                      : "Nenhum resultado para o filtro.",
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _studentCard(list[index]),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
