import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/graduacao/bjj_graduacao.dart';
import '../services/student_service.dart';

class AthletesPage extends StatefulWidget {
  const AthletesPage({super.key});

  @override
  State<AthletesPage> createState() => _AthletesPageState();
}

class _AthletesPageState extends State<AthletesPage> {
  final _service = StudentService();
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
    _athletesFuture = _service.listAthletes();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Atletas"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _athletesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  snapshot.error
                      .toString()
                      .replaceFirst("Exception: ", ""),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ),
            );
          }

          final athletes = snapshot.data ?? [];
          if (athletes.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum atleta encontrado.",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return RefreshIndicator(
            color: primary,
            onRefresh: () async {
              setState(() {
                _athletesFuture = _service.listAthletes();
              });
              await _athletesFuture;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: athletes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final a = athletes[index];
                final age = _calcAge(_parseBirthDate(a));
                return _AthleteShowcaseCard(
                  athlete: a,
                  age: age,
                  onTap: () => _AthleteDetailSheet.show(context, a, age),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AthleteShowcaseCard extends StatelessWidget {
  const _AthleteShowcaseCard({
    required this.athlete,
    required this.age,
    required this.onTap,
  });

  final Map<String, dynamic> athlete;
  final int? age;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;

    final nome = (athlete["nome"] ?? "Atleta").toString().trim();
    final nomeDisplay =
        nome.isEmpty ? "Atleta" : nome.toUpperCase();
    final modalidade = (athlete["modalidade"] ?? "").toString().trim();
    final grad = formatGraduacaoDisplay(
      (athlete["graduacao"] ?? "").toString(),
    );
    final nivel = (athlete["nivel_competicao"] ?? "").toString().trim();
    final cartelMma = (athlete["cartel_mma"] ?? "").toString().trim();
    final rawId = athlete["id"];
    final id = rawId is int
        ? rawId
        : rawId is num
            ? rawId.toInt()
            : null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: primary.withValues(alpha: 0.22),
        highlightColor: primary.withValues(alpha: 0.08),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: primary, width: 2),
            color: Colors.black.withValues(alpha: 0.32),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SizedBox(
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _SubtleBackdrop(accent: primary),
                if (id != null)
                  _AthletePhotoLayer(studentId: id, accent: primary)
                else
                  const ColoredBox(color: Color(0xFF121212)),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        "GENESIS",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: primary.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 36,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        "ATLETA",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.95),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.94),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nomeDisplay,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Toque para ver lutas e detalhes",
                          style: TextStyle(
                            fontSize: 11,
                            color: primary.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (modalidade.isNotEmpty)
                              _chip(modalidade, primary, context),
                            if (grad != "-" && grad.isNotEmpty)
                              _chip(grad, Colors.white70, context),
                            if (age != null)
                              _chip("$age anos", Colors.white60, context),
                            if (nivel.isNotEmpty)
                              _chip(nivel, Colors.white70, context),
                            if (cartelMma.isNotEmpty && cartelMma != "-")
                              _chip("MMA $cartelMma", Colors.white54, context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color accentColor, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(
            alpha: accentColor == Theme.of(context).colorScheme.primary
                ? 0.55
                : 0.35,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
      ),
    );
  }
}

class _SubtleBackdrop extends StatelessWidget {
  const _SubtleBackdrop({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF121212),
      child: CustomPaint(
        painter: _AccentStrokePainter(accent: accent),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AccentStrokePainter extends CustomPainter {
  _AccentStrokePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    p.color = accent.withValues(alpha: 0.14);
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.85, size.height * 0.08),
      p,
    );
    p.color = accent.withValues(alpha: 0.1);
    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.75),
      Offset(size.width * 0.95, size.height * 0.55),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _AccentStrokePainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _AthletePhotoLayer extends StatefulWidget {
  const _AthletePhotoLayer({
    required this.studentId,
    required this.accent,
  });

  final int studentId;
  final Color accent;

  @override
  State<_AthletePhotoLayer> createState() => _AthletePhotoLayerState();
}

class _AthletePhotoLayerState extends State<_AthletePhotoLayer> {
  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = StudentService()
        .getAthleteCardOrProfilePhotoBytes(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return ColoredBox(
            color: const Color(0xFF141414),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.accent,
                ),
              ),
            ),
          );
        }
        final b = snap.data;
        if (b == null || b.isEmpty) {
          return ColoredBox(
            color: const Color(0xFF101010),
            child: Center(
              child: Icon(
                Icons.person,
                size: 120,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          );
        }
        return Image.memory(
          b,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          gaplessPlayback: true,
        );
      },
    );
  }
}

/// Bottom sheet com cartéis, última luta, Tapology, etc.
class _AthleteDetailSheet extends StatelessWidget {
  const _AthleteDetailSheet({
    required this.athlete,
    required this.age,
    required this.scrollController,
  });

  final Map<String, dynamic> athlete;
  final int? age;
  final ScrollController scrollController;

  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> athlete,
    int? age,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.58,
          maxChildSize: 0.92,
          minChildSize: 0.38,
          expand: false,
          builder: (context, scrollController) {
            return _AthleteDetailSheet(
              athlete: athlete,
              age: age,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  static String _str(dynamic v) => (v ?? "").toString().trim();

  static String _formatDateBr(String raw) {
    if (raw.isEmpty) return "";
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    final dd = d.day.toString().padLeft(2, "0");
    final mm = d.month.toString().padLeft(2, "0");
    return "$dd/$mm/${d.year}";
  }

  static String _nivelLabel(String raw) {
    final s = raw.toLowerCase();
    if (s == "amador") return "Amador";
    if (s == "profissional") return "Profissional";
    return raw;
  }

  int? _studentId() {
    final rawId = athlete["id"];
    if (rawId is int) return rawId;
    if (rawId is num) return rawId.toInt();
    return null;
  }

  bool _cartelOk(String s) => s.isNotEmpty && s != "-";

  List<Widget> _cartelRows(String mma, String jiu, String k1) {
    final rows = <Widget>[];
    if (_cartelOk(mma)) rows.add(_detailRow("MMA", mma));
    if (_cartelOk(jiu)) rows.add(_detailRow("Jiu-Jitsu", jiu));
    if (_cartelOk(k1)) rows.add(_detailRow("K-1 / kickboxing", k1));
    if (rows.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            "Sem cartel registrado.",
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      ];
    }
    return rows;
  }

  Future<void> _openTapology(BuildContext context, String raw) async {
    var s = raw.trim();
    if (s.isEmpty) return;
    if (!s.contains("://")) {
      s = "https://$s";
    }
    final u = Uri.tryParse(s);
    if (u == null || !u.hasScheme || u.host.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Link inválido."),
          ),
        );
      }
      return;
    }
    try {
      var ok = await launchUrl(u, mode: LaunchMode.externalApplication);
      if (!ok) {
        ok = await launchUrl(u, mode: LaunchMode.platformDefault);
      }
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível abrir o link.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst("Exception: ", ""),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final nome = _str(athlete["nome"]).isEmpty ? "Atleta" : _str(athlete["nome"]);
    final modalidade = _str(athlete["modalidade"]);
    final grad = formatGraduacaoDisplay(_str(athlete["graduacao"]));
    final nivel = _nivelLabel(_str(athlete["nivel_competicao"]));
    final cartelMma = _str(athlete["cartel_mma"]);
    final cartelJiu = _str(athlete["cartel_jiu"]);
    final cartelK1 = _str(athlete["cartel_k1"]);
    final linkTap = _str(athlete["link_tapology"]);
    final ultimaData = _formatDateBr(_str(athlete["ultima_luta_em"]));
    final ultimaMod = _str(athlete["ultima_luta_modalidade"]);
    final tempoTreino = athlete["tempo_de_treino"];
    String tempoTreinoStr = "";
    if (tempoTreino is int && tempoTreino > 0) {
      tempoTreinoStr = "$tempoTreino meses";
    } else if (tempoTreino is num && tempoTreino > 0) {
      tempoTreinoStr = "${tempoTreino.toInt()} meses";
    }

    final sid = _studentId();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Color(0x22FFFFFF), width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                if (sid != null)
                  _DetailAvatar(studentId: sid, primary: primary)
                else
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: primary.withValues(alpha: 0.2),
                    child: Icon(Icons.person, size: 40, color: primary),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (modalidade.isNotEmpty)
                        Text(
                          modalidade,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      if (grad != "-" && grad.isNotEmpty)
                        Text(
                          grad,
                          style: TextStyle(
                            color: primary.withValues(alpha: 0.95),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (age != null)
                        Text(
                          "$age anos",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              children: [
                if (tempoTreinoStr.isNotEmpty || nivel.isNotEmpty) ...[
                  _sectionTitle("Treino e nível", primary),
                  if (tempoTreinoStr.isNotEmpty)
                    _detailRow("Tempo de treino", tempoTreinoStr),
                  if (nivel.isNotEmpty) _detailRow("Competição", nivel),
                  const SizedBox(height: 18),
                ],
                _sectionTitle("Cartéis", primary),
                ..._cartelRows(cartelMma, cartelJiu, cartelK1),
                if (ultimaData.isNotEmpty || ultimaMod.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _sectionTitle("Última luta", primary),
                  if (ultimaData.isNotEmpty)
                    _detailRow("Data", ultimaData),
                  if (ultimaMod.isNotEmpty)
                    _detailRow("Modalidade", ultimaMod),
                ],
                if (linkTap.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openTapology(context, linkTap),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: primary.withValues(alpha: 0.85)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(Icons.open_in_new, color: primary),
                      label: const Text("Abrir Tapology / perfil"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailAvatar extends StatefulWidget {
  const _DetailAvatar({
    required this.studentId,
    required this.primary,
  });

  final int studentId;
  final Color primary;

  @override
  State<_DetailAvatar> createState() => _DetailAvatarState();
}

class _DetailAvatarState extends State<_DetailAvatar> {
  late final Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = StudentService()
        .getAthleteCardOrProfilePhotoBytes(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null || snap.data!.isEmpty) {
          return CircleAvatar(
            radius: 36,
            backgroundColor: widget.primary.withValues(alpha: 0.2),
            child: snap.connectionState == ConnectionState.waiting
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.primary,
                    ),
                  )
                : Icon(Icons.person, size: 40, color: widget.primary),
          );
        }
        return CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFF2A2A2A),
          backgroundImage: MemoryImage(snap.data!),
        );
      },
    );
  }
}
