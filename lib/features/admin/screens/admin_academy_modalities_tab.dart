import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../gym_schedule/services/gym_schedule_service.dart';
import '../../tenant/services/tenant_service.dart';
import '../widgets/admin_shell.dart';

int? _jsonInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

int? _firstIntIn(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v.trim());
      if (p != null) return p;
    }
  }
  return null;
}

String _firstStringIn(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return '';
}

Map<String, dynamic> _asStringKeyMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
  if (raw is Map) {
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }
  return {};
}

/// Lista vinda do JSON (objetos ou mapas genéricos).
List<Map<String, dynamic>> _normalizeRoleList(dynamic raw) {
  if (raw == null) return [];
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      raw = jsonDecode(raw);
    } catch (_) {
      return [];
    }
  }
  if (raw is! List) return [];
  final out = <Map<String, dynamic>>[];
  for (final e in raw) {
    if (e is Map<String, dynamic>) {
      out.add(Map<String, dynamic>.from(e));
    } else if (e is Map) {
      out.add(_asStringKeyMap(e));
    }
  }
  return out;
}

Iterable<dynamic> _candidateGraduationLists(Map<String, dynamic> m) sync* {
  yield m['graduation_roles'];
  yield m['graduationRoles'];
  yield m['graduation_rules'];
  yield m['graduations'];
  yield m['faixas'];
  yield m['belt_levels'];
  yield m['niveis_graduacao'];
  yield m['niveis'];
  for (final k in ['config', 'settings', 'training', 'training_config', 'metadata']) {
    final n = m[k];
    if (n is Map) {
      final nm = _asStringKeyMap(n);
      yield nm['graduation_roles'];
      yield nm['graduationRoles'];
      yield nm['graduations'];
      yield nm['faixas'];
      yield nm['belt_levels'];
    }
  }
}

int? _hoursFromModality(Map<String, dynamic> m) {
  return _firstIntIn(m, [
    'hours_for_next_graduation',
    'hoursForNextGraduation',
    'required_hours_default',
    'requiredHoursDefault',
    'horas_proxima_graduacao',
    'horas_para_proxima_graduacao',
    'next_graduation_hours',
    'hours_for_promotion',
    'horas_graduacao',
    'min_hours_next_graduation',
  ]);
}

List<Map<String, dynamic>> _rolesFromModality(Map<String, dynamic> m) {
  for (final raw in _candidateGraduationLists(m)) {
    final list = _normalizeRoleList(raw);
    if (list.isNotEmpty) return list;
  }
  return [];
}

String _roleName(Map<String, dynamic> r) => _firstStringIn(r, [
      'name',
      'nome',
      'graduation_name',
      'title',
      'label',
      'belt',
      'faixa',
      'level',
      'descricao',
    ]);

int? _roleHours(Map<String, dynamic> r) {
  return _firstIntIn(r, [
    'hours_to_next',
    'hoursToNext',
    'horas_para_proxima',
    'required_hours',
    'requiredHours',
    'min_hours',
    'horas',
    'hours',
  ]);
}

String _modalityDisplayName(Map<String, dynamic> m) {
  final s = _firstStringIn(m, ['nome', 'name', 'titulo', 'title']);
  return s.isEmpty ? '—' : s;
}

/// Aba admin: modalidades da academia + horas para graduação + faixas/níveis.
class AdminAcademyModalitiesTab extends StatefulWidget {
  const AdminAcademyModalitiesTab({
    super.key,
    required this.schedule,
    required this.onModalitiesChanged,
  });

  final GymScheduleService schedule;
  final VoidCallback onModalitiesChanged;

  @override
  State<AdminAcademyModalitiesTab> createState() =>
      _AdminAcademyModalitiesTabState();
}

class _AdminAcademyModalitiesTabState extends State<AdminAcademyModalitiesTab> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

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
      var rows = await widget.schedule.listModalidades();
      if (rows.isEmpty) {
        try {
          final cfg = await TenantService().getTenantConfig();
          rows = GymScheduleService.parseFlexibleDataList(cfg);
          if (rows.isEmpty) {
            final data = cfg['data'];
            if (data is Map) {
              rows = GymScheduleService.parseFlexibleDataList(data);
            }
          }
          if (rows.isEmpty && cfg['tenant'] is Map) {
            rows = GymScheduleService.parseFlexibleDataList(cfg['tenant']);
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _list = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? existing}) async {
    final id = existing != null
        ? (_jsonInt(existing['id']) ??
            _jsonInt(existing['modality_id']) ??
            _jsonInt(existing['modalityId']))
        : null;
    final initialParsedRoles =
        existing != null ? _rolesFromModality(existing) : <Map<String, dynamic>>[];
    final nomeCtrl = TextEditingController(
      text: existing != null
          ? _firstStringIn(existing, ['nome', 'name', 'titulo', 'title'])
          : '',
    );
    final descCtrl = TextEditingController(
      text: (existing?['descricao'] ?? existing?['description'] ?? '')
          .toString(),
    );
    final sortCtrl = TextEditingController(
      text: _jsonInt(existing?['sort_order'])?.toString() ?? '',
    );
    final hoursCtrl = TextEditingController(
      text: existing != null
          ? (_hoursFromModality(existing)?.toString() ?? '')
          : '',
    );

    final roles = <_RoleRow>[];
    /// Linhas removidas pelo usuário: não dar dispose durante o rebuild do sheet.
    final orphanedRoleRows = <_RoleRow>[];
    if (existing != null) {
      for (final r in initialParsedRoles) {
        final n = _roleName(r);
        final h = _roleHours(r);
        if (n.isNotEmpty || h != null) {
          roles.add(_RoleRow(
            TextEditingController(text: n),
            TextEditingController(text: h != null ? '$h' : ''),
          ));
        }
      }
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: bottom + 16 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            id == null
                                ? 'Nova modalidade'
                                : 'Editar modalidade',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (existing != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Valores carregados do servidor — edite, remova faixas com − ou '
                          'toque em + Faixa para incluir.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: Theme.of(ctx)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    TextField(
                      controller: nomeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome da modalidade *',
                        hintText: 'Ex.: Jiu-Jitsu, Muay Thai',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sortCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ordem na lista (opcional)',
                        hintText: '0, 1, 2…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hoursCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Horas para próxima graduação',
                        helperText:
                            'Total de horas de treino para o aluno poder '
                            'pedir a próxima faixa (quando não usa faixas detalhadas abaixo).',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Faixas / níveis (opcional)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setLocal(() {
                              roles.add(_RoleRow(
                                TextEditingController(),
                                TextEditingController(),
                              ));
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Faixa'),
                        ),
                      ],
                    ),
                    Text(
                      'Ordene da inicial à mais avançada. Em cada linha: nome da graduação '
                      'e horas de treino para avançar à próxima.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (roles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Nenhuma faixa cadastrada — a academia pode usar só o campo de horas acima.',
                          style: TextStyle(
                            color: Theme.of(ctx)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      ...List.generate(roles.length, (i) {
                        final row = roles[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: row.name,
                                  decoration: InputDecoration(
                                    labelText: 'Graduação ${i + 1}',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: row.hours,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Horas',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (i < 0 || i >= roles.length) return;
                                  setLocal(() {
                                    orphanedRoleRows.add(roles.removeAt(i));
                                  });
                                },
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: AdminPanelStyle.filledPrimary(ctx),
                      onPressed: () {
                        if (nomeCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Informe o nome da modalidade.'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: Text(id == null ? 'Cadastrar' : 'Salvar alterações'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    var editorsDisposed = false;
    void disposeEditors() {
      if (editorsDisposed) return;
      editorsDisposed = true;
      nomeCtrl.dispose();
      descCtrl.dispose();
      sortCtrl.dispose();
      hoursCtrl.dispose();
      for (final r in roles) {
        r.dispose();
      }
      for (final r in orphanedRoleRows) {
        r.dispose();
      }
    }

    if (ok != true || !mounted) {
      scheduleMicrotask(disposeEditors);
      return;
    }

    final sortOrder = int.tryParse(sortCtrl.text.trim());
    final hours = int.tryParse(hoursCtrl.text.trim());
    final payloadRoles = <Map<String, dynamic>>[];
    for (final r in roles) {
      final n = r.name.text.trim();
      final h = int.tryParse(r.hours.text.trim());
      if (n.isEmpty) continue;
      payloadRoles.add({
        'name': n,
        if (h != null && h >= 0) 'hours_to_next': h,
      });
    }

    try {
      if (id == null) {
        await widget.schedule.createModality(
          nome: nomeCtrl.text,
          descricao: descCtrl.text.trim().isEmpty ? null : descCtrl.text,
          sortOrder: sortOrder,
          hoursForNextGraduation: hours != null && hours > 0 ? hours : null,
          graduationRoles: payloadRoles.isNotEmpty ? payloadRoles : null,
        );
      } else {
        final patchRoles = (payloadRoles.isNotEmpty || initialParsedRoles.isNotEmpty)
            ? payloadRoles
            : null;
        final hadStoredHours =
            existing != null && _hoursFromModality(existing) != null;
        final hoursFieldEmpty = hoursCtrl.text.trim().isEmpty;
        await widget.schedule.updateModality(
          id,
          nome: nomeCtrl.text,
          descricao: descCtrl.text.trim().isEmpty ? null : descCtrl.text,
          sortOrder: sortOrder,
          clearHoursForNextGraduation: hoursFieldEmpty && hadStoredHours,
          hoursForNextGraduation: hoursFieldEmpty
              ? null
              : (hours != null && hours >= 0 ? hours : null),
          graduationRoles: patchRoles,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id == null ? 'Modalidade criada.' : 'Alterações salvas.'),
        ),
      );
      widget.onModalitiesChanged();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      scheduleMicrotask(disposeEditors);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    final id =
        _jsonInt(row['id']) ?? _jsonInt(row['modality_id']) ?? _jsonInt(row['modalityId']);
    if (id == null) return;
    final nome = _modalityDisplayName(row);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover modalidade'),
        content: Text(
          'Remover "$nome"? Aulas que usam esta modalidade podem precisar ser ajustadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: AdminPanelStyle.filledPrimary(ctx),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (go != true) return;
    try {
      await widget.schedule.deleteModality(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modalidade removida.')),
      );
      widget.onModalitiesChanged();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.tertiary,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AdminHeroIntro(
            icon: Icons.sports_martial_arts_outlined,
            title: 'Modalidades e graduação',
            subtitle:
                'Cadastre as artes da sua academia, defina horas para próxima graduação '
                'e, se quiser, a sequência de faixas/níveis. Os alunos veem o progresso no app.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_list.length} modalidade${_list.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ),
              FilledButton.icon(
                style: AdminPanelStyle.filledPrimary(context),
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Nova'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: AdminEmptyHint(
                message:
                    'Nenhuma modalidade ainda. Cadastre Jiu-Jitsu, Muay Thai, etc., '
                    'para vincular nas aulas da grade e no progresso dos alunos.',
                icon: Icons.interests_outlined,
              ),
            )
          else
            ..._list.map((m) {
              final id =
                  _jsonInt(m['id']) ?? _jsonInt(m['modality_id']) ?? _jsonInt(m['modalityId']);
              final nome = _modalityDisplayName(m);
              final h = _hoursFromModality(m);
              final rolesParsed = _rolesFromModality(m);
              final roleCount = rolesParsed.length;
              final rolePreview = rolesParsed
                  .map(_roleName)
                  .where((n) => n.isNotEmpty)
                  .toList();
              final desc = (m['descricao'] ?? m['description'] ?? m['desc'] ?? '')
                  .toString()
                  .trim();

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: id == null ? null : () => _openEditor(existing: m),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
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
                                  ),
                                ),
                              ),
                              if (id != null)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _confirmDelete(m),
                                  tooltip: 'Remover',
                                ),
                            ],
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (h != null)
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text('$h h → próxima graduação'),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                )
                              else
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(
                                    'Horas globais não definidas',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              if (roleCount > 0)
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  avatar: const Icon(Icons.military_tech, size: 16),
                                  label: Text('$roleCount faixa${roleCount == 1 ? '' : 's'}'),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                            ],
                          ),
                          if (rolePreview.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              rolePreview.length > 4
                                  ? '${rolePreview.take(4).join(' → ')}…'
                                  : rolePreview.join(' → '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'Toque para ver tudo do servidor, editar, excluir faixas ou adicionar.',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RoleRow {
  _RoleRow(this.name, this.hours);
  final TextEditingController name;
  final TextEditingController hours;

  void dispose() {
    name.dispose();
    hours.dispose();
  }
}
