import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../gym_schedule/services/gym_schedule_service.dart';
import '../../tenant/services/tenant_service.dart';

class AcademyInfoPage extends StatefulWidget {
  const AcademyInfoPage({super.key});

  @override
  State<AcademyInfoPage> createState() => _AcademyInfoPageState();
}

class _AcademyInfoPageState extends State<AcademyInfoPage> {
  final _tenantSvc = TenantService();
  final _schedule = GymScheduleService();
  final _auth = AuthRepository();

  Map<String, dynamic>? _tenantInfo;
  List<Map<String, dynamic>> _grouped = [];
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
      final cfg = await _tenantSvc.getTenantConfig();
      final t = cfg["tenant"];
      final grouped = await _schedule.listScheduleGrouped(activeOnly: true);
      if (!mounted) return;
      setState(() {
        _tenantInfo = t is Map ? Map<String, dynamic>.from(t) : null;
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

  List<Widget> _buildAboutSection() {
    final t = _tenantInfo;
    if (t == null) {
      return const [
        Text("Dados da academia indisponíveis."),
      ];
    }
    final logo = t["logo_url"]?.toString();
    final desc = (t["public_description"] ?? "").toString().trim();
    return [
      if (logo != null && logo.isNotEmpty) ...[
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: logo,
              height: 100,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      Text(
        (t["nome"] ?? "Academia").toString(),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        desc.isEmpty
            ? "A administração ainda não cadastrou a descrição da academia. "
                "Peça para atualizarem em Painel admin → Academia."
            : desc,
        style: const TextStyle(
          color: Colors.white70,
          height: 1.45,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Academia"),
          bottom: TabBar(
            indicatorColor: primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: "Sobre"),
              Tab(text: "Grade de aulas"),
            ],
          ),
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
                : TabBarView(
                    children: [
                      RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: _buildAboutSection(),
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _load,
                        child: _grouped.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      "Nenhum horário publicado na grade.",
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _grouped.length,
                                itemBuilder: (context, i) {
                                  final day = _grouped[i];
                                  final label =
                                      (day["weekday_label"] ?? "").toString();
                                  final slots = day["slots"];
                                  final list = slots is List
                                      ? slots
                                          .whereType<Map>()
                                          .map((e) => Map<String, dynamic>.from(e))
                                          .toList()
                                      : <Map<String, dynamic>>[];
                                  return Card(
                                    color: const Color(0xFF1E1E1E),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ExpansionTile(
                                      title: Text(
                                        label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      children: list.map((slot) {
                                        final ci = slot["class_info"];
                                        final name = ci is Map
                                            ? (ci["name"] ?? "").toString()
                                            : "";
                                        final inst = ci is Map
                                            ? (ci["instructor_name"] ?? "")
                                                .toString()
                                            : "";
                                        final st =
                                            (slot["start_time"] ?? "").toString();
                                        final et =
                                            (slot["end_time"] ?? "").toString();
                                        final room =
                                            (slot["room"] ?? "").toString();
                                        return ListTile(
                                          title: Text("$st – $et  $name"),
                                          subtitle: inst.isEmpty && room.isEmpty
                                              ? null
                                              : Text(
                                                  [
                                                    if (inst.isNotEmpty)
                                                      "Prof. $inst",
                                                    if (room.isNotEmpty) room,
                                                  ].join(" · "),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
