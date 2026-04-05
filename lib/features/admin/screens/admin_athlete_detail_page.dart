import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/graduacao/bjj_graduacao.dart';

class AdminAthleteDetailPage extends StatelessWidget {
  final Map<String, dynamic> athlete;

  const AdminAthleteDetailPage({super.key, required this.athlete});

  DateTime? _parseBirthDate(dynamic raw) {
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

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    final d = date.day.toString().padLeft(2, "0");
    final m = date.month.toString().padLeft(2, "0");
    final y = date.year.toString();
    return "$d/$m/$y";
  }

  String _buildCopyText() {
    final birth = _parseBirthDate(
      athlete["data_nascimento"] ?? athlete["nascimento"] ?? athlete["birth_date"],
    );
    final age = _calcAge(birth);
    return '''
*DADOS DO ATLETA - GENESIS MMA*

Nome: ${athlete["nome"] ?? "-"}
Data de nascimento: ${_formatDate(birth)}
Idade: ${age?.toString() ?? "-"} anos
Email: ${athlete["email"] ?? "-"}
Telefone: ${athlete["telefone"] ?? "-"}
Modalidade: ${athlete["modalidade"] ?? "-"}
Graduacao: ${formatGraduacaoDisplay((athlete["graduacao"] ?? "").toString())}
Status: ${athlete["status"] ?? "-"}
Atleta: ${(athlete["e_atleta"] ?? false) == true ? "SIM" : "NAO"}
Cartel MMA: ${athlete["cartel_mma"] ?? "-"}
Cartel Jiu: ${athlete["cartel_jiu"] ?? "-"}
Cartel K1: ${athlete["cartel_k1"] ?? "-"}
Nivel competicao: ${athlete["nivel_competicao"] ?? "-"}
Tapology: ${athlete["link_tapology"] ?? "-"}
Ultima luta: ${athlete["ultima_luta_em"] ?? "-"} (${athlete["ultima_luta_modalidade"] ?? "-"})
''';
  }

  @override
  Widget build(BuildContext context) {
    final birth = _parseBirthDate(
      athlete["data_nascimento"] ?? athlete["nascimento"] ?? athlete["birth_date"],
    );
    final age = _calcAge(birth);
    final copyText = _buildCopyText();

    return Scaffold(
      appBar: AppBar(
        title: Text((athlete["nome"] ?? "Atleta").toString()),
        actions: [
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _buildCopyText()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Informacoes copiadas.")),
              );
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Texto para WhatsApp",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  copyText,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: copyText));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Texto copiado para WhatsApp.")),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("Copiar texto"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _item("Nome", (athlete["nome"] ?? "-").toString()),
          _item("Email", (athlete["email"] ?? "-").toString()),
          _item("Telefone", (athlete["telefone"] ?? "-").toString()),
          _item("Endereco", (athlete["endereco"] ?? "-").toString()),
          _item("Modalidade", (athlete["modalidade"] ?? "-").toString()),
          _item(
            "Graduacao",
            formatGraduacaoDisplay((athlete["graduacao"] ?? "").toString()),
          ),
          _item("Status", (athlete["status"] ?? "-").toString()),
          _item(
            "Atleta",
            (athlete["e_atleta"] ?? false) == true ? "SIM" : "NAO",
          ),
          _item(
            "Data nascimento",
            _formatDate(birth),
          ),
          _item("Idade", age?.toString() ?? "-"),
          _item("Cartel MMA", (athlete["cartel_mma"] ?? "-").toString()),
          _item("Cartel Jiu", (athlete["cartel_jiu"] ?? "-").toString()),
          _item("Cartel K1", (athlete["cartel_k1"] ?? "-").toString()),
          _item(
            "Nivel competicao",
            (athlete["nivel_competicao"] ?? "-").toString(),
          ),
          _item("Tapology", (athlete["link_tapology"] ?? "-").toString()),
          _item(
            "Ultima luta",
            "${athlete["ultima_luta_em"] ?? "-"} (${athlete["ultima_luta_modalidade"] ?? "-"})",
          ),
        ],
      ),
    );
  }

  Widget _item(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
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

