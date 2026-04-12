import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/graduacao/bjj_graduacao.dart';
import '../../../shared/themes/app_button_styles.dart';
import '../services/admin_service.dart';
import '../widgets/register_student_attendance.dart';
import '../../../widgets/loading_overlay.dart';
import 'admin_edit_student_page.dart';
import 'admin_athlete_detail_page.dart';

/// Visualização de dados + foto do aluno (aba Alunos no admin).
class AdminStudentDetailPage extends StatefulWidget {
  const AdminStudentDetailPage({
    super.key,
    required this.service,
    required this.student,
  });

  final AdminService service;
  final Map<String, dynamic> student;

  @override
  State<AdminStudentDetailPage> createState() => _AdminStudentDetailPageState();
}

class _AdminStudentDetailPageState extends State<AdminStudentDetailPage> {
  Uint8List? _photoBytes;
  bool _loadingPhoto = true;
  bool _registeringPresence = false;

  int? get _studentId {
    final id = widget.student['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final id = _studentId;
    if (id == null) {
      setState(() => _loadingPhoto = false);
      return;
    }
    final bytes = await widget.service.getStudentPhotoBytes(id);
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _loadingPhoto = false;
    });
  }

  String _t(String key) => (widget.student[key] ?? '-').toString();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final eAtleta = (widget.student['e_atleta'] ?? false) == true;
    final nome = _t('nome');
    return Scaffold(
      appBar: AppBar(
        title: Text(nome.isEmpty ? 'Aluno' : nome),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AdminEditStudentPage(
                    service: widget.service,
                    student: widget.student,
                  ),
                ),
              );
              if (ok == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: LoadingOverlay(
        visible: _registeringPresence,
        message: 'Registrando presença...',
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: cs.surfaceContainerHighest,
                  backgroundImage:
                      _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                  child: _loadingPhoto
                      ? SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.tertiary,
                          ),
                        )
                      : _photoBytes == null
                          ? const Icon(Icons.person, size: 56)
                          : null,
                ),
                const SizedBox(height: 8),
                Text(
                  nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => registerStudentAttendance(
                context: context,
                service: widget.service,
                student: widget.student,
                onBusy: (busy) {
                  if (mounted) setState(() => _registeringPresence = busy);
                },
              ),
              icon: const Icon(Icons.how_to_reg_outlined),
              label: const Text('Registrar presença (hoje)'),
              style: AppButtonStyles.tertiaryAccentFilled(
                Theme.of(context).colorScheme,
              ).merge(
                const ButtonStyle(
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Para alunos sem celular ou sem app: o professor registra a presença aqui.',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _card(context, 'Email', _t('email')),
          _card(context, 'Telefone', _t('telefone')),
          _card(context, 'Modalidade', _t('modalidade')),
          _card(
            context,
            'Graduação',
            formatGraduacaoDisplay(
              (widget.student['graduacao'] ?? '').toString(),
            ),
          ),
          _card(context, 'Status', _t('status')),
          _card(context, 'Endereço', _t('endereco')),
          _card(context, 'Data de nascimento', _t('data_nascimento')),
          if (eAtleta) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminAthleteDetailPage(
                        athlete: widget.student,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.sports_mma),
                label: const Text('Ver ficha de atleta'),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String label, String value) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
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
