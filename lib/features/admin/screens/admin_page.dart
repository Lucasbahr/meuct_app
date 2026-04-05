import 'package:flutter/material.dart';
import '../../../core/auth/session_service.dart';
import '../services/admin_service.dart';
import 'admin_students_tab.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _service = AdminService();
  final _sessionService = SessionService();
  late Future<List<Map<String, dynamic>>> _rankingFuture;
  bool _isAdmin = false;
  bool _isCheckingRole = true;
  int _studentsReloadToken = 0;

  @override
  void initState() {
    super.initState();
    _checkRole();
    _rankingFuture = _service.getRanking();
  }

  Future<void> _checkRole() async {
    final isAdmin = await _sessionService.isAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _isCheckingRole = false;
    });
  }

  Future<void> _reload() async {
    setState(() {
      _studentsReloadToken++;
      _rankingFuture = _service.getRanking();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text("Admin")),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text("Acesso permitido somente para administradores."),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin"),
          actions: [
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Alunos"),
              Tab(text: "Frequencia"),
              Tab(text: "Ranking"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AdminStudentsTab(
              key: ValueKey(_studentsReloadToken),
              service: _service,
            ),
            _buildFrequencyTab(),
            _buildRankingTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _rankingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }
        final ranking = snapshot.data ?? [];
        if (ranking.isEmpty) {
          return const Center(child: Text("Sem dados de frequencia."));
        }

        final maxTotal = ranking
            .map((e) => (e["total"] as num?)?.toDouble() ?? 0)
            .fold<double>(0, (prev, curr) => curr > prev ? curr : prev);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ranking.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = ranking[index];
            final nome = (item["nome"] ?? "Aluno").toString();
            final total = ((item["total"] as num?) ?? 0).toInt();
            final progress = maxTotal == 0 ? 0.0 : total / maxTotal;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text("$total check-ins"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRankingTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _rankingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }
        final ranking = snapshot.data ?? [];
        if (ranking.isEmpty) {
          return const Center(child: Text("Ranking vazio."));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ranking.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = ranking[index];
            final nome = (item["nome"] ?? "Aluno").toString();
            final total = ((item["total"] as num?) ?? 0).toInt();
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: const Color(0xFF1E1E1E),
              leading: CircleAvatar(child: Text("${index + 1}")),
              title: Text(nome),
              trailing: Text("$total"),
            );
          },
        );
      },
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
