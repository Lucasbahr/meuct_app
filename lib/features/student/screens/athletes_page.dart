import 'package:flutter/material.dart';
import '../../admin/services/admin_service.dart';

class AthletesPage extends StatefulWidget {
  const AthletesPage({super.key});

  @override
  State<AthletesPage> createState() => _AthletesPageState();
}

class _AthletesPageState extends State<AthletesPage> {
  final _service = AdminService();
  late Future<List<Map<String, dynamic>>> _athletesFuture;

  DateTime? _parseBirthDate(Map<String, dynamic> a) {
    final raw = a["data_nascimento"] ?? a["nascimento"] ?? a["birth_date"];
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

  @override
  void initState() {
    super.initState();
    _athletesFuture = _service.getAthletes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Atletas"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _athletesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  snapshot.error
                      .toString()
                      .replaceFirst("Exception: ", ""),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final athletes = snapshot.data ?? [];
          if (athletes.isEmpty) {
            return const Center(
              child: Text("Nenhum atleta encontrado."),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _athletesFuture = _service.getAthletes();
              });
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: athletes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final a = athletes[index];
                final nome = (a["nome"] ?? "Sem nome").toString();
                final modalidade = (a["modalidade"] ?? "-").toString();
                final nivel = (a["nivel_competicao"] ?? "-").toString();
                final cartelMma = (a["cartel_mma"] ?? "-").toString();
                final cartelJiu = (a["cartel_jiu"] ?? "-").toString();
                final cartelK1 = (a["cartel_k1"] ?? "-").toString();
                final ultimaLuta = (a["ultima_luta_em"] ?? "-").toString();
                final ultimaModalidade =
                    (a["ultima_luta_modalidade"] ?? "-").toString();
                final age = _calcAge(_parseBirthDate(a));

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _item("Modalidade", modalidade),
                      _item("Nível", nivel),
                      _item("Idade", age?.toString() ?? "-"),
                      _item("Cartel MMA", cartelMma),
                      _item("Cartel Jiu", cartelJiu),
                      _item("Cartel K1", cartelK1),
                      _item("Última luta", "$ultimaLuta ($ultimaModalidade)"),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$label:",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

