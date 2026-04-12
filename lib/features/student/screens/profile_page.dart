import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/graduacao/bjj_graduacao.dart';
import '../../../core/graduacao/graduation_palette.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/themes/app_tokens.dart';
import '../../../widgets/br_address_editor.dart';
import '../services/student_service.dart';
import '../services/checkin_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _studentService = StudentService();
  final _checkinService = CheckinService();
  Map<String, dynamic>? _student;
  int? _diasTreinados;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  bool _isSavingProfile = false;
  String? _error;
  bool _isEditing = false;
  Uint8List? _photoBytes;

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final GlobalKey<BrAddressEditorState> _addressKey =
      GlobalKey<BrAddressEditorState>();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  DateTime? _parseBirthDate(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    final d = date.day.toString().padLeft(2, "0");
    final m = date.month.toString().padLeft(2, "0");
    final y = date.year.toString();
    return "$d/$m/$y";
  }

  String _formatDateIso(DateTime date) {
    final d = date.day.toString().padLeft(2, "0");
    final m = date.month.toString().padLeft(2, "0");
    final y = date.year.toString();
    return "$y-$m-$d";
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _studentService.getMe();
      if (!mounted) return;
      setState(() {
        _student = data;
        _isLoading = false;

        _nomeController.text = (_student?["nome"] ?? "").toString();
        _telefoneController.text = (_student?["telefone"] ?? "").toString();
        final birth = _parseBirthDate(_student?["data_nascimento"]);
        _dataNascimentoController.text = _formatDate(birth);
      });
      final extra = await Future.wait<Object?>([
        _studentService
            .getMyProfilePhotoBytes()
            .then<Uint8List?>((b) => b)
            .catchError((Object _) => null),
        _checkinService
            .getHistory()
            .catchError((Object _) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      final bytes = extra[0] as Uint8List?;
      final history = (extra[1] as List).cast<Map<String, dynamic>>();
      setState(() {
        _photoBytes = bytes;
        _diasTreinados = CheckinService.countDistinctTrainingDays(history);
        _history = history;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final updated = await _studentService.uploadProfilePhoto(image.path);
      final bytes = await _studentService.getMyProfilePhotoBytes();
      if (!mounted) return;
      setState(() {
        _student = updated;
        _photoBytes = bytes;
      });
      _showSnack("Foto atualizada com sucesso.", ok: true);
    } catch (e) {
      _showSnack(
        "Não foi possível enviar a foto. Verifique se a rota de upload existe no backend.",
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showSnack(String message, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? AppColors.success : null,
      ),
    );
  }

  String _enderecoExibicao() {
    final e = (_student?["endereco"] ?? "").toString().trim();
    return e.isEmpty ? "-" : e;
  }

  Future<void> _saveProfile() async {
    if (_isSavingProfile) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    final addressState = _addressKey.currentState;
    if (addressState == null) {
      _showSnack(
        "Não foi possível ler o endereço. Toque em Cancelar e em Editar de novo.",
      );
      return;
    }
    final enderecoErr = addressState.validateEnderecoParaSalvar();
    if (enderecoErr != null) {
      _showSnack(enderecoErr);
      return;
    }
    final enderecoLine = addressState.composeEndereco().trim();

    setState(() => _isSavingProfile = true);
    try {
      await _studentService.updateMyProfile(
        nome: _nomeController.text.trim().isEmpty ? null : _nomeController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty ? null : _telefoneController.text.trim(),
        endereco: enderecoLine.isEmpty ? null : enderecoLine,
        dataNascimento: _dataNascimentoController.text.trim().isEmpty ||
                _dataNascimentoController.text.trim() == "-"
            ? null
            : _dataNascimentoController.text.trim(),
      );
      await _loadProfile();
      if (!mounted) return;
      setState(() => _isEditing = false);
      _showSnack("Dados atualizados com sucesso.", ok: true);
    } catch (e) {
      _showSnack(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  List<Map<String, dynamic>> _sortedHistory() {
    final list = List<Map<String, dynamic>>.from(_history);
    list.sort((a, b) {
      final da = DateTime.tryParse(a['date']?.toString() ?? '') ??
          DateTime(1970);
      final db = DateTime.tryParse(b['date']?.toString() ?? '') ??
          DateTime(1970);
      return db.compareTo(da);
    });
    return list.take(14).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.tertiary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _student == null
                  ? const Center(child: Text('Dados não encontrados.'))
                  : Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: [
                            _heroHeader(context),
                            const SizedBox(height: AppSpacing.md),
                            PrimaryButton(
                              label: 'Ir para check-in',
                              icon: Icons.how_to_reg_rounded,
                              onPressed: () {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(context);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Na tela inicial, toque em "Registrar presença".',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Você volta ao início e abre a lista de presença em um toque.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isUploadingPhoto
                                        ? null
                                        : () {
                                            final next = !_isEditing;
                                            setState(() => _isEditing = next);
                                            if (next) {
                                              final birth = _parseBirthDate(
                                                _student!["data_nascimento"],
                                              );
                                              _dataNascimentoController.text =
                                                  birth == null
                                                      ? ""
                                                      : _formatDateIso(birth);
                                            } else {
                                              _nomeController.text =
                                                  (_student!["nome"] ?? "")
                                                      .toString();
                                              _telefoneController.text =
                                                  (_student!["telefone"] ?? "")
                                                      .toString();
                                              final birth = _parseBirthDate(
                                                _student!["data_nascimento"],
                                              );
                                              _dataNascimentoController.text =
                                                  _formatDate(birth);
                                              _addressKey.currentState
                                                  ?.hydrateFrom(
                                                Map<String, dynamic>.from(
                                                  _student!,
                                                ),
                                              );
                                            }
                                          },
                                    icon: Icon(
                                        _isEditing ? Icons.close : Icons.edit),
                                    label: Text(
                                        _isEditing ? 'Cancelar' : 'Editar'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (_isEditing) ..._editForm() else ..._readOnly(),
                          ],
                        ),
                        if (_isSavingProfile)
                          Positioned.fill(
                            child: AbsorbPointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .scrim
                                      .withValues(alpha: 0.35),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Salvando...',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }

  Widget _heroHeader(BuildContext context) {
    final nome = (_student!['nome'] ?? '').toString().trim();
    final gradRaw = _student!['graduacao']?.toString() ?? '';
    final grad = graduationLabelFromStudent(_student!);
    final belt = graduationAccentColor(gradRaw.isNotEmpty ? gradRaw : grad);
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.card + 4),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: primary.withValues(alpha: 0.1),
                backgroundImage:
                    _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                child: _photoBytes == null
                    ? Text(
                        _initials(nome),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      )
                    : null,
              ),
              Material(
                color: cs.surface,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: 'Alterar foto',
                  onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                  icon: _isUploadingPhoto
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            nome.isEmpty ? 'Aluno' : nome,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  belt.withValues(alpha: 0.2),
                  belt.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: belt.withValues(alpha: 0.35)),
            ),
            child: Text(
              grad,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: belt.computeLuminance() > 0.55
                    ? cs.onSurface
                    : belt,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              _chip(
                Icons.verified_rounded,
                (_student!['status'] ?? '—').toString(),
                cs.primary,
              ),
              if (_diasTreinados != null)
                _chip(
                  Icons.local_fire_department_outlined,
                  '$_diasTreinados dia${_diasTreinados == 1 ? '' : 's'} treinados',
                  AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Histórico recente de presença',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_sortedHistory().isEmpty)
            Text(
              'Nenhum check-in registrado ainda.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ..._sortedHistory().map((e) => _historyRow(context, e)),
        ],
      ),
    );
  }

  Widget _historyRow(BuildContext context, Map<String, dynamic> e) {
    final total = (e['total'] as num?)?.toInt() ?? 0;
    final ok = total > 0;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok
                  ? AppColors.success
                  : cs.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              e['date']?.toString() ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          Text(
            ok ? '$total' : '—',
            style: TextStyle(
              color: ok ? AppColors.success : cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final list =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (list.isEmpty) return '?';
    if (list.length == 1) {
      final p = list.first;
      if (p.length >= 2) return p.substring(0, 2).toUpperCase();
      return p.toUpperCase();
    }
    return ('${list.first[0]}${list.last[0]}').toUpperCase();
  }

  List<Widget> _editForm() {
    return [
      TextField(
        controller: _nomeController,
        decoration: const InputDecoration(labelText: 'Nome'),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _telefoneController,
        decoration: const InputDecoration(labelText: 'Telefone'),
      ),
      const SizedBox(height: AppSpacing.md),
      InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Graduação',
          helperText: 'Definida pela equipe; não pode ser alterada aqui.',
        ),
        child: Text(
          graduationLabelFromStudent(_student!),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      BrAddressEditor(
        key: _addressKey,
        studentSnapshot: Map<String, dynamic>.from(_student!),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _dataNascimentoController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Data de nascimento',
          suffixIcon: Icon(Icons.calendar_month),
        ),
        onTap: () async {
          final current =
              _parseBirthDate(_student?["data_nascimento"]) ?? DateTime(2000, 1, 1);
          final picked = await showDatePicker(
            context: context,
            initialDate: current,
            firstDate: DateTime(1930, 1, 1),
            lastDate: DateTime.now(),
          );
          if (picked == null) return;
          _dataNascimentoController.text = _formatDateIso(picked);
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(
        label: 'Salvar alterações',
        loading: _isSavingProfile,
        onPressed: (_isSavingProfile || _isUploadingPhoto) ? null : _saveProfile,
      ),
    ];
  }

  List<Widget> _readOnly() {
    return [
      _tile('Telefone', (_student!['telefone'] ?? '-').toString()),
      _tile('Endereço', _enderecoExibicao()),
      _tile('Modalidade', modalityLabelFromStudent(_student!)),
      _tile('Graduação', graduationLabelFromStudent(_student!)),
      _tile('Status', (_student!['status'] ?? '-').toString()),
      _tile(
        'Data de nascimento',
        _formatDate(_parseBirthDate(_student!['data_nascimento'])),
      ),
    ];
  }

  Widget _tile(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 108,
              child: Text(
                label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
