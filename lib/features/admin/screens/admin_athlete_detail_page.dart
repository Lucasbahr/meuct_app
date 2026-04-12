import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/graduacao/bjj_graduacao.dart';
import '../../tenant/services/tenant_service.dart';

class AdminAthleteDetailPage extends StatefulWidget {
  final Map<String, dynamic> athlete;

  const AdminAthleteDetailPage({super.key, required this.athlete});

  @override
  State<AdminAthleteDetailPage> createState() => _AdminAthleteDetailPageState();
}

class _AdminAthleteDetailPageState extends State<AdminAthleteDetailPage> {
  String _academyLine = 'Academia';

  @override
  void initState() {
    super.initState();
    _loadAcademyName();
  }

  Future<void> _loadAcademyName() async {
    try {
      final cfg = await TenantService().getTenantConfig();
      final n = TenantService.displayNameFromConfig(cfg)?.trim();
      if (!mounted) return;
      if (n != null && n.isNotEmpty) setState(() => _academyLine = n);
    } catch (_) {}
  }

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
    final a = widget.athlete;
    final birth = _parseBirthDate(
      a["data_nascimento"] ?? a["nascimento"] ?? a["birth_date"],
    );
    final age = _calcAge(birth);
    final header = _academyLine.toUpperCase();
    return '''
*DADOS DO ATLETA - $header*

Nome: ${a["nome"] ?? "-"}
Data de nascimento: ${_formatDate(birth)}
Idade: ${age?.toString() ?? "-"} anos
Modalidade: ${a["modalidade"] ?? "-"}
Graduacao: ${formatGraduacaoDisplay((a["graduacao"] ?? "").toString())}
Cartel MMA: ${a["cartel_mma"] ?? "-"}
Cartel Jiu: ${a["cartel_jiu"] ?? "-"}
Cartel K1: ${a["cartel_k1"] ?? "-"}
Nivel competicao: ${a["nivel_competicao"] ?? "-"}
Tapology: ${a["link_tapology"] ?? "-"}
Ultima luta: ${a["ultima_luta_em"] ?? "-"} (${a["ultima_luta_modalidade"] ?? "-"})
''';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = widget.athlete;
    final birth = _parseBirthDate(
      a["data_nascimento"] ?? a["nascimento"] ?? a["birth_date"],
    );
    final age = _calcAge(birth);
    final copyText = _buildCopyText();

    return Scaffold(
      appBar: AppBar(
        title: Text((a["nome"] ?? "Atleta").toString()),
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
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Texto para WhatsApp",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  copyText,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
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
          _item(context, "Nome", (a["nome"] ?? "-").toString()),
          _item(context, "Endereco", (a["endereco"] ?? "-").toString()),
          _item(context, "Modalidade", (a["modalidade"] ?? "-").toString()),
          _item(
            context,
            "Graduacao",
            formatGraduacaoDisplay((a["graduacao"] ?? "").toString()),
          ),
          _item(
            context,
            "Data nascimento",
            _formatDate(birth),
          ),
          _item(context, "Idade", age?.toString() ?? "-"),
          _item(context, "Cartel MMA", (a["cartel_mma"] ?? "-").toString()),
          _item(context, "Cartel Jiu", (a["cartel_jiu"] ?? "-").toString()),
          _item(context, "Cartel K1", (a["cartel_k1"] ?? "-").toString()),
          _item(
            context,
            "Nivel competicao",
            (a["nivel_competicao"] ?? "-").toString(),
          ),
          _item(context, "Tapology", (a["link_tapology"] ?? "-").toString()),
          _item(
            context,
            "Ultima luta",
            "${a["ultima_luta_em"] ?? "-"} (${a["ultima_luta_modalidade"] ?? "-"})",
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
