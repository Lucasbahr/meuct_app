import 'package:flutter/material.dart';
import '../services/student_service.dart';

class AcademyInfoPage extends StatefulWidget {
  const AcademyInfoPage({super.key});

  @override
  State<AcademyInfoPage> createState() => _AcademyInfoPageState();
}

class _AcademyInfoPageState extends State<AcademyInfoPage> {
  final _studentService = StudentService();
  Map<String, dynamic>? _student;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _studentService.getMe();
      if (!mounted) return;
      setState(() {
        _student = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Informações"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _student == null
                  ? const Center(child: Text("Dados não encontrados."))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "História da academia",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Aqui você verá a história, valores e conquistas da academia. "
                                "Quando você criar endpoints para “posts”/“feed”, esta seção pode ficar dinâmica.",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Suas lutas",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _row("Última luta", _student?["ultima_luta_em"] != null
                                  ? "${_student!["ultima_luta_em"]} (${_student!["ultima_luta_modalidade"] ?? "-"})"
                                  : "-"),
                              _row("Nível de competição",
                                  (_student?["nivel_competicao"] ?? "-").toString()),
                              _row(
                                  "Cartel MMA",
                                  (_student?["cartel_mma"] ?? "-").toString()),
                              _row(
                                  "Cartel Jiu",
                                  (_student?["cartel_jiu"] ?? "-").toString()),
                              _row(
                                  "Cartel K1",
                                  (_student?["cartel_k1"] ?? "-").toString()),
                              _row(
                                "Tapology",
                                (_student?["link_tapology"] ?? "-").toString(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

