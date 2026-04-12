import 'package:flutter/material.dart';

import '../../../shared/components/empty_state.dart';
import '../../../shared/components/student_card.dart';
import '../../../shared/themes/app_tokens.dart';
import '../../admin/services/admin_service.dart';
import '../../admin/widgets/register_student_attendance.dart';
import '../screens/gym_student_detail_page.dart';

class GymStudentsTab extends StatefulWidget {
  const GymStudentsTab({
    super.key,
    required this.canLoadStudents,
    required this.canCheckInForOthers,
  });

  final bool canLoadStudents;

  /// Registro de presença em nome do aluno (API exige admin).
  final bool canCheckInForOthers;

  @override
  State<GymStudentsTab> createState() => _GymStudentsTabState();
}

class _GymStudentsTabState extends State<GymStudentsTab> {
  final _admin = AdminService();
  final _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;

  void _onSearchChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _future = _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (!widget.canLoadStudents) return [];
    return _admin.getStudents();
  }

  static String _nomeAluno(Map<String, dynamic> s) =>
      (s['nome'] ?? '').toString().trim();

  static int _compareNome(Map<String, dynamic> a, Map<String, dynamic> b) {
    final na = _nomeAluno(a).toLowerCase();
    final nb = _nomeAluno(b).toLowerCase();
    return na.compareTo(nb);
  }

  List<Map<String, dynamic>> _sortedAndFiltered(List<Map<String, dynamic>> raw) {
    final q = _searchController.text.trim().toLowerCase();
    final list = List<Map<String, dynamic>>.from(raw);
    list.sort(_compareNome);
    if (q.isEmpty) return list;
    return list.where((s) {
      final n = (s['nome'] ?? '').toString().toLowerCase();
      final e = (s['email'] ?? '').toString().toLowerCase();
      final tel = (s['telefone'] ?? '').toString().toLowerCase();
      return n.contains(q) || e.contains(q) || tel.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canLoadStudents) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 48),
          EmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Lista restrita à equipe',
            message:
                'Apenas administradores e professores veem todos os alunos aqui. '
                'Use a aba Atletas no menu para a vitrine pública.',
          ),
        ],
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Não foi possível carregar',
                message: snap.error.toString().replaceFirst('Exception: ', ''),
                actionLabel: 'Tentar de novo',
                onAction: () => setState(() => _future = _load()),
              ),
            ],
          );
        }
        final raw = snap.data ?? [];
        if (raw.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 48),
              EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'Nenhum aluno encontrado',
                message: 'Cadastre alunos no painel admin ou verifique permissões da API.',
              ),
            ],
          );
        }

        final list = _sortedAndFiltered(raw);
        final hasFilter = _searchController.text.trim().isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, e-mail ou telefone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar',
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            if (hasFilter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  '${list.length} de ${raw.length} aluno${raw.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Expanded(
              child: list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        EmptyState(
                          icon: Icons.person_search_rounded,
                          title: 'Nenhum resultado',
                          message:
                              'Nenhum aluno corresponde à busca. Ajuste os termos ou limpe o filtro.',
                          actionLabel: 'Limpar busca',
                          onAction: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() => _future = _load());
                        await _future;
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.lg + 8,
                        ),
                        itemCount: list.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final s = list[i];
                          return StudentCard(
                            student: s,
                            onTap: () async {
                              final changed =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute<bool>(
                                  builder: (_) => GymStudentDetailPage(
                                    student: s,
                                    canManageStudent:
                                        widget.canCheckInForOthers,
                                  ),
                                ),
                              );
                              if (changed == true && context.mounted) {
                                setState(() => _future = _load());
                              }
                            },
                            onCheckIn: widget.canCheckInForOthers
                                ? () => registerStudentAttendance(
                                      context: context,
                                      service: _admin,
                                      student: s,
                                      onSuccess: () {
                                        if (context.mounted) {
                                          setState(() => _future = _load());
                                        }
                                      },
                                    )
                                : null,
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
