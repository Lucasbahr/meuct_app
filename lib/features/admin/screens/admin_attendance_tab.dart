import 'package:flutter/material.dart';

import '../widgets/admin_shell.dart';

/// Check-ins agregados: volume e posição (mesma API que ranking de frequência).
class AdminAttendanceTab extends StatelessWidget {
  const AdminAttendanceTab({
    super.key,
    required this.rankingFuture,
    required this.onRefresh,
  });

  final Future<List<Map<String, dynamic>>> rankingFuture;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AdminHeroIntro(
            icon: Icons.leaderboard_outlined,
            title: "Presença",
            subtitle:
                "Volume de check-ins e ranking — mesmos dados; duas formas de enxergar.",
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Material(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: accent,
                    dividerColor: Colors.white.withValues(alpha: 0.06),
                    tabs: const [
                      Tab(icon: Icon(Icons.bar_chart_rounded, size: 20), text: "Volume"),
                      Tab(icon: Icon(Icons.emoji_events_outlined, size: 20), text: "Ranking"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _VolumeView(future: rankingFuture, onRetry: onRefresh),
                      _RankingView(future: rankingFuture, onRetry: onRefresh),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VolumeView extends StatelessWidget {
  const _VolumeView({required this.future, required this.onRetry});

  final Future<List<Map<String, dynamic>>> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AdminErrorPanel(
            message: snapshot.error.toString(),
            onRetry: onRetry,
            accent: primary,
          );
        }
        final ranking = snapshot.data ?? [];
        if (ranking.isEmpty) {
          return const AdminEmptyHint(
            message: "Ainda não há dados de check-in para montar o volume.",
            icon: Icons.event_busy_outlined,
          );
        }
        final maxTotal = ranking
            .map((e) => (e["total"] as num?)?.toDouble() ?? 0)
            .fold<double>(0, (prev, curr) => curr > prev ? curr : prev);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ranking.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = ranking[index];
            final nome = (item["nome"] ?? "Aluno").toString();
            final total = ((item["total"] as num?) ?? 0).toInt();
            final progress = maxTotal == 0 ? 0.0 : total / maxTotal;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: AdminPanelStyle.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        "$total check-ins",
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      color: primary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RankingView extends StatelessWidget {
  const _RankingView({required this.future, required this.onRetry});

  final Future<List<Map<String, dynamic>>> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AdminErrorPanel(
            message: snapshot.error.toString(),
            onRetry: onRetry,
            accent: primary,
          );
        }
        final ranking = snapshot.data ?? [];
        if (ranking.isEmpty) {
          return const AdminEmptyHint(
            message: "Ranking vazio — ainda sem check-ins registrados.",
            icon: Icons.emoji_events_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ranking.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = ranking[index];
            final nome = (item["nome"] ?? "Aluno").toString();
            final total = ((item["total"] as num?) ?? 0).toInt();
            final pos = index + 1;
            final medal = pos == 1
                ? const Color(0xFFFFD700)
                : pos == 2
                    ? const Color(0xFFB0BEC5)
                    : pos == 3
                        ? const Color(0xFFCD7F32)
                        : const Color(0xFF2A2A2A);
            return Container(
              decoration: AdminPanelStyle.cardDecoration(),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: medal,
                  foregroundColor: pos <= 3 ? Colors.black : Colors.white,
                  child: Text(
                    "$pos",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Text(
                  "$total",
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
