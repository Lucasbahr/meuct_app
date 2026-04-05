import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
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
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
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
      final bytes = await _studentService.getMyProfilePhotoBytes();
      if (!mounted) return;
      setState(() => _photoBytes = bytes);
      try {
        final history = await _checkinService.getHistory();
        if (!mounted) return;
        setState(() {
          _diasTreinados = CheckinService.countDistinctTrainingDays(history);
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _diasTreinados = null);
      }
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
      _showSnack("Foto atualizada com sucesso.");
    } catch (e) {
      _showSnack(
        "Nao foi possivel enviar a foto. Verifique se a rota de upload existe no backend.",
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile() async {
    try {
      final enderecoLine = _addressKey.currentState?.composeEndereco().trim();
      await _studentService.updateMyProfile(
        nome: _nomeController.text.trim().isEmpty ? null : _nomeController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty ? null : _telefoneController.text.trim(),
        endereco: (enderecoLine == null || enderecoLine.isEmpty) ? null : enderecoLine,
        dataNascimento: _dataNascimentoController.text.trim().isEmpty ||
                _dataNascimentoController.text.trim() == "-"
            ? null
            : _dataNascimentoController.text.trim(),
      );
      await _loadProfile();
      if (!mounted) return;
      setState(() => _isEditing = false);
      _showSnack("Dados atualizados com sucesso.");
    } catch (e) {
      _showSnack(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meus dados")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : _student == null
                  ? const Center(child: Text("Dados nao encontrados."))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: const Color(0xFF2A2A2A),
                                    backgroundImage: _photoBytes != null
                                        ? MemoryImage(_photoBytes!)
                                        : null,
                                    child: _photoBytes == null
                                        ? const Icon(Icons.person, size: 42)
                                        : null,
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: Text(
                                  _isUploadingPhoto ? "Enviando..." : "Alterar foto",
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                            const SizedBox(height: 8),
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
                                                  (_student!["nome"] ?? "").toString();
                                              _telefoneController.text =
                                                  (_student!["telefone"] ?? "").toString();
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
                                    icon: Icon(_isEditing ? Icons.close : Icons.edit),
                                    label: Text(_isEditing ? "Cancelar" : "Editar dados"),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_isEditing) ...[
                              TextField(
                                controller: _nomeController,
                                decoration: const InputDecoration(
                                  labelText: "Nome",
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _telefoneController,
                                decoration: const InputDecoration(
                                  labelText: "Telefone",
                                ),
                              ),
                              const SizedBox(height: 12),
                              BrAddressEditor(
                                key: _addressKey,
                                studentSnapshot: Map<String, dynamic>.from(
                                  _student!,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _dataNascimentoController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: "Data de nascimento",
                                  suffixIcon: Icon(Icons.calendar_month),
                                ),
                                onTap: () async {
                                  final current = _parseBirthDate(
                                        _student?["data_nascimento"],
                                      ) ??
                                      DateTime(2000, 1, 1);
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: current,
                                    firstDate: DateTime(1930, 1, 1),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked == null) return;
                                  _dataNascimentoController.text =
                                      _formatDateIso(picked);
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  child: const Text("SALVAR"),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (!_isEditing) ...[
                              _item("Nome", (_student!["nome"] ?? "-").toString()),
                              _item(
                                  "Telefone", (_student!["telefone"] ?? "-").toString()),
                              _item(
                                  "Modalidade", (_student!["modalidade"] ?? "-").toString()),
                              _item(
                                  "Graduacao", (_student!["graduacao"] ?? "-").toString()),
                              _item("Status", (_student!["status"] ?? "-").toString()),
                              if (_diasTreinados != null)
                                _item(
                                  "Dias treinados",
                                  "${_diasTreinados!} dia${_diasTreinados == 1 ? "" : "s"} com presença",
                                ),
                              _item(
                                "Data de nascimento",
                                _formatDate(
                                  _parseBirthDate(_student!["data_nascimento"]),
                                ),
                              ),
                            ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 16),
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
