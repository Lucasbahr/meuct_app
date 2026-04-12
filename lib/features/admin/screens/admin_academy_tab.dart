import 'package:flutter/material.dart';

import '../../../core/branding/app_branding.dart';
import '../../gym_schedule/services/gym_schedule_service.dart';
import '../../tenant/services/tenant_service.dart';
import '../widgets/branding_color_row.dart';
import 'admin_academy_modalities_tab.dart';

const _weekdayChoices = <String>[
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

const _weekdayShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

int? _jsonInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

String _timeHms(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

class AdminAcademyTab extends StatelessWidget {
  const AdminAcademyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: _AdminAcademyTabBody(),
    );
  }
}

class _AdminAcademyTabBody extends StatefulWidget {
  const _AdminAcademyTabBody();

  @override
  State<_AdminAcademyTabBody> createState() => _AdminAcademyTabBodyState();
}

class _AdminAcademyTabBodyState extends State<_AdminAcademyTabBody> {
  final _tenant = TenantService();
  final _schedule = GymScheduleService();

  final _desc = TextEditingController();
  final _corPri = TextEditingController();
  final _corSec = TextEditingController();
  final _corBg = TextEditingController();
  final _logo = TextEditingController();

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _grouped = [];
  List<Map<String, dynamic>> _modalidades = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _desc.dispose();
    _corPri.dispose();
    _corSec.dispose();
    _corBg.dispose();
    _logo.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cfg = await _tenant.getTenantConfig();
      final tenant = cfg["tenant"];
      if (tenant is Map) {
        final m = Map<String, dynamic>.from(tenant);
        _desc.text = (m["public_description"] ?? "").toString();
        _corPri.text = (m["cor_primaria"] ?? "").toString();
        _corSec.text = (m["cor_secundaria"] ?? "").toString();
        _corBg.text = (m["cor_background"] ?? "").toString();
        _logo.text = (m["logo_url"] ?? "").toString();
      }

      final classes = await _schedule.listGymClasses(activeOnly: false);
      final grouped = await _schedule.listScheduleGrouped(activeOnly: false);
      List<Map<String, dynamic>> mods = [];
      try {
        mods = await _schedule.listModalidades();
      } catch (_) {
        mods = [];
      }

      if (!mounted) return;
      setState(() {
        _classes = classes;
        _grouped = grouped;
        _modalidades = mods;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
    }
  }

  Future<void> _saveBranding() async {
    try {
      await _tenant.patchTenantBranding(
        publicDescription: _desc.text,
        corPrimaria: _corPri.text.trim().isEmpty ? null : _corPri.text.trim(),
        corSecundaria:
            _corSec.text.trim().isEmpty ? null : _corSec.text.trim(),
        corBackground: _corBg.text.trim().isEmpty ? null : _corBg.text.trim(),
        logoUrl: _logo.text.trim().isEmpty ? null : _logo.text.trim(),
      );
      await AppBrandingController.instance.refreshFromApi();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aparência salva. O app já usa a nova paleta.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  Future<void> _openClassEditor({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?["name"]?.toString() ?? "");
    final descCtrl =
        TextEditingController(text: existing?["description"]?.toString() ?? "");
    final instCtrl =
        TextEditingController(text: existing?["instructor_name"]?.toString() ?? "");
    final durCtrl = TextEditingController(
      text: existing?["duration_minutes"]?.toString() ?? "",
    );
    int? modalityId;
    final rawMod = existing?["modality_id"];
    if (rawMod is int) {
      modalityId = rawMod;
    } else if (rawMod != null) {
      modalityId = int.tryParse(rawMod.toString());
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? "Nova aula" : "Editar aula"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nome da aula *"),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: "Descrição"),
                  maxLines: 2,
                ),
                TextField(
                  controller: instCtrl,
                  decoration: const InputDecoration(labelText: "Professor"),
                ),
                TextField(
                  controller: durCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Duração (minutos)",
                  ),
                ),
                if (_modalidades.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: modalityId,
                    decoration: const InputDecoration(labelText: "Modalidade (opcional)"),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text("—")),
                      ..._modalidades.expand((m) {
                        final idRaw = m["id"];
                        final id = idRaw is int ? idRaw : int.tryParse("$idRaw");
                        if (id == null) return <DropdownMenuItem<int?>>[];
                        return [
                          DropdownMenuItem<int?>(
                            value: id,
                            child: Text((m["nome"] ?? "").toString()),
                          ),
                        ];
                      }),
                    ],
                    onChanged: (v) => setLocal(() => modalityId = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Salvar")),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) {
      nameCtrl.dispose();
      descCtrl.dispose();
      instCtrl.dispose();
      durCtrl.dispose();
      return;
    }

    final dur = int.tryParse(durCtrl.text.trim());
    try {
      if (existing == null) {
        await _schedule.createGymClass(
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          instructorName: instCtrl.text.trim().isEmpty ? null : instCtrl.text.trim(),
          durationMinutes: dur,
          modalityId: modalityId,
        );
      } else {
        final id = _jsonInt(existing["id"])!;
        await _schedule.updateGymClass(
          id,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          instructorName: instCtrl.text.trim().isEmpty ? null : instCtrl.text.trim(),
          durationMinutes: dur,
          modalityId: modalityId,
        );
      }
      nameCtrl.dispose();
      descCtrl.dispose();
      instCtrl.dispose();
      durCtrl.dispose();
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aula salva.")));
      }
    } catch (e) {
      nameCtrl.dispose();
      descCtrl.dispose();
      instCtrl.dispose();
      durCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    }
  }

  Future<void> _confirmDeleteClass(int id, String label) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover aula"),
        content: Text("Remover \"$label\"? Horários desta aula também deixam de aparecer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Não")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Remover")),
        ],
      ),
    );
    if (go != true) return;
    try {
      await _schedule.deleteGymClass(id);
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    }
  }

  Future<void> _openSlotEditor({Map<String, dynamic>? existing}) async {
    if (_classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cadastre pelo menos uma aula antes.")),
      );
      return;
    }

    int classId = _jsonInt(_classes.first["id"]) ?? 0;
    if (existing != null) {
      final ci = existing["class_info"];
      if (ci is Map && ci["id"] != null) {
        classId = _jsonInt(ci["id"]) ?? classId;
      }
    }

    int weekday = _jsonInt(existing?["weekday"]) ?? 0;

    final selectedWeekdays = <int>{};

    TimeOfDay parseT(String? s) {
      if (s == null || s.isEmpty) return const TimeOfDay(hour: 18, minute: 0);
      final parts = s.split(":");
      final h = int.tryParse(parts[0]) ?? 18;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return TimeOfDay(hour: h, minute: m);
    }

    var start = parseT(existing?["start_time"]?.toString());
    var end = parseT(existing?["end_time"]?.toString());
    final roomCtrl = TextEditingController(text: existing?["room"]?.toString() ?? "");

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            existing == null
                ? "Novo horário (vários dias)"
                : "Editar horário",
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  value: classId,
                  decoration: const InputDecoration(labelText: "Aula"),
                  items: _classes
                      .map((c) {
                        final id = _jsonInt(c["id"]);
                        if (id == null) return null;
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text((c["name"] ?? "").toString()),
                        );
                      })
                      .whereType<DropdownMenuItem<int>>()
                      .toList(),
                  onChanged: (v) => setLocal(() => classId = v ?? classId),
                ),
                if (existing == null) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Dias da semana",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Marque um ou mais. O mesmo horário será criado em cada dia.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(7, (i) {
                      return FilterChip(
                        label: Text(_weekdayShort[i]),
                        selected: selectedWeekdays.contains(i),
                        onSelected: (sel) {
                          setLocal(() {
                            if (sel) {
                              selectedWeekdays.add(i);
                            } else {
                              selectedWeekdays.remove(i);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: weekday.clamp(0, 6),
                    decoration:
                        const InputDecoration(labelText: "Dia da semana"),
                    items: List.generate(
                      7,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(_weekdayChoices[i]),
                      ),
                    ),
                    onChanged: (v) => setLocal(() => weekday = v ?? 0),
                  ),
                ],
                ListTile(
                  title: const Text("Início"),
                  subtitle: Text(start.format(ctx)),
                  onTap: () async {
                    final p =
                        await showTimePicker(context: ctx, initialTime: start);
                    if (p != null) setLocal(() => start = p);
                  },
                ),
                ListTile(
                  title: const Text("Fim"),
                  subtitle: Text(end.format(ctx)),
                  onTap: () async {
                    final p =
                        await showTimePicker(context: ctx, initialTime: end);
                    if (p != null) setLocal(() => end = p);
                  },
                ),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(labelText: "Sala (opcional)"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () {
                if (existing == null && selectedWeekdays.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text("Selecione pelo menos um dia da semana."),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) {
      roomCtrl.dispose();
      return;
    }

    try {
      if (existing == null) {
        final days = selectedWeekdays.toList()..sort();
        for (final wd in days) {
          await _schedule.createScheduleSlot(
            gymClassId: classId,
            weekday: wd,
            startTimeHms: _timeHms(start),
            endTimeHms: _timeHms(end),
            room: roomCtrl.text.trim().isEmpty ? null : roomCtrl.text.trim(),
          );
        }
      } else {
        final sid = _jsonInt(existing["id"]);
        if (sid == null) throw Exception("ID do horário inválido.");
        await _schedule.updateScheduleSlot(
          sid,
          gymClassId: classId,
          weekday: weekday,
          startTimeHms: _timeHms(start),
          endTimeHms: _timeHms(end),
          room: roomCtrl.text.trim().isEmpty ? null : roomCtrl.text.trim(),
        );
      }
      roomCtrl.dispose();
      await _reload();
      if (mounted) {
        final msg = existing == null
            ? (selectedWeekdays.length == 1
                ? "Horário salvo."
                : "${selectedWeekdays.length} horários salvos na grade.")
            : "Horário atualizado.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      roomCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    }
  }

  Future<void> _deleteSlot(int id) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover horário"),
        content: const Text("Confirma remover este horário da grade?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Não")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Remover")),
        ],
      ),
    );
    if (go != true) return;
    try {
      await _schedule.deleteScheduleSlot(id);
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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
              FilledButton(onPressed: _reload, child: const Text("Tentar novamente")),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Material(
          color: const Color(0xFF1A1A1A),
          child: TabBar(
            labelColor: primary,
            unselectedLabelColor: Colors.white54,
            indicatorColor: primary,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: "Aparência"),
              Tab(text: "Grade de aulas"),
              Tab(text: "Modalidades"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    "Texto e cores passam a orientar o tema do app (botões, destaques e vinheta sobre o fundo).",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _desc,
                    decoration: const InputDecoration(
                      labelText: "Descrição pública (Sobre a academia)",
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _logo,
                    decoration: const InputDecoration(
                      labelText: "URL do logo (opcional)",
                    ),
                  ),
                  const SizedBox(height: 16),
                  BrandingColorRow(
                    label: "Cor primária",
                    helper: "Botões, destaques e indicadores.",
                    controller: _corPri,
                    fallbackColor: kDefaultBrandingPrimary,
                  ),
                  const SizedBox(height: 20),
                  BrandingColorRow(
                    label: "Cor secundária",
                    helper: "Complementa a primária no tema.",
                    controller: _corSec,
                    fallbackColor: kDefaultBrandingSecondary,
                  ),
                  const SizedBox(height: 20),
                  BrandingColorRow(
                    label: "Cor de fundo / vinheta",
                    helper: "Tom sobre o fundo escuro do app (opcional).",
                    controller: _corBg,
                    fallbackColor: kDefaultBrandingBackgroundHint,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saveBranding,
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text("Salvar aparência"),
                  ),
                ],
              ),
              RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Aulas cadastradas",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _openClassEditor(),
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: "Nova aula",
                        ),
                      ],
                    ),
                    if (_classes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          "Nenhuma aula. Toque em + para criar.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ..._classes.map((c) {
                        final id = _jsonInt(c["id"]);
                        if (id == null) return const SizedBox.shrink();
                        final name = (c["name"] ?? "").toString();
                        return Card(
                          color: const Color(0xFF1E1E1E),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text(
                              (c["instructor_name"] ?? "—").toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _openClassEditor(existing: c),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _confirmDeleteClass(id, name),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Horários na grade",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _openSlotEditor(),
                          icon: const Icon(Icons.schedule),
                          tooltip: "Novo horário",
                        ),
                      ],
                    ),
                    if (_grouped.isEmpty)
                      const Text(
                        "Sem horários. Use o ícone de agenda para adicionar.",
                        style: TextStyle(color: Colors.white54),
                      )
                    else
                      ..._grouped.map((day) {
                        final label = (day["weekday_label"] ?? "").toString();
                        final slots = day["slots"];
                        final list = slots is List
                            ? slots.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
                            : <Map<String, dynamic>>[];
                        return ExpansionTile(
                          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          children: list.map((slot) {
                            final ci = slot["class_info"];
                            final cname = ci is Map
                                ? (ci["name"] ?? "").toString()
                                : "";
                            final st = (slot["start_time"] ?? "").toString();
                            final et = (slot["end_time"] ?? "").toString();
                            final room = (slot["room"] ?? "").toString();
                            return ListTile(
                              title: Text("$st – $et · $cname"),
                              subtitle: room.isEmpty ? null : Text(room),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _openSlotEditor(existing: slot),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () {
                                      final sid = _jsonInt(slot["id"]);
                                      if (sid != null) _deleteSlot(sid);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }),
                  ],
                ),
              ),
              AdminAcademyModalitiesTab(
                schedule: _schedule,
                onModalitiesChanged: () {
                  _reload();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
