import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

import '../../../core/api/dio_unauthorized.dart';
import '../../auth/repositories/auth_repository.dart';
import '../services/training_service.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  final _service = TrainingService();
  final _authRepository = AuthRepository();
  List<Map<String, dynamic>> _rows = [];
  String? _error;
  bool _loading = true;

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
      final list = await _service.getRanking(limit: 50);
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (dioIsUnauthorized(e)) {
        await _authRepository.logout();
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Ranking (XP)")),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text("Tentar novamente")),
                    ],
                  )
                : _rows.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              "Ninguém no ranking ainda.",
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _rows.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final r = _rows[i];
                          final pos = r["position"] ?? i + 1;
                          final scheme = Theme.of(context).colorScheme;
                          return ListTile(
                            tileColor: scheme.surfaceContainerHigh,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: pos == 1
                                  ? const Color(0xFFFFD700)
                                  : pos == 2
                                      ? const Color(0xFFC0C0C0)
                                      : pos == 3
                                          ? const Color(0xFFCD7F32)
                                          : scheme.surfaceContainerHighest,
                              child: Text(
                                "$pos",
                                style: TextStyle(
                                  color: pos <= 3
                                      ? AppPalette.lightPrimary
                                      : scheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(r["nome"]?.toString() ?? "—"),
                            subtitle: Text(
                              r["email"]?.toString() ?? "",
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${r["total_xp"] ?? 0} XP",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.primary,
                                  ),
                                ),
                                Text(
                                  "Nv. ${r["level"] ?? 0}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
