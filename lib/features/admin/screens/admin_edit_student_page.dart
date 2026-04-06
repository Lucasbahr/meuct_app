import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/graduacao/bjj_graduacao.dart';
import '../../../widgets/br_address_editor.dart';
import '../../../widgets/loading_overlay.dart';
import '../services/admin_service.dart';

class AdminEditStudentPage extends StatefulWidget {
  final AdminService service;
  final Map<String, dynamic> student;

  const AdminEditStudentPage({
    super.key,
    required this.service,
    required this.student,
  });

  @override
  State<AdminEditStudentPage> createState() => _AdminEditStudentPageState();
}

class _AdminEditStudentPageState extends State<AdminEditStudentPage> {
  final _emailController = TextEditingController();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final GlobalKey<BrAddressEditorState> _addressKey =
      GlobalKey<BrAddressEditorState>();
  final _modalidadeController = TextEditingController();
  final _statusController = TextEditingController();
  final _tempoTreinoController = TextEditingController();
  final _cartelMmaController = TextEditingController();
  final _cartelJiuController = TextEditingController();
  final _cartelK1Controller = TextEditingController();
  final _nivelCompeticaoController = TextEditingController();
  final _linkTapologyController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _ultimaLutaEmController = TextEditingController();
  final _ultimaLutaModalidadeController = TextEditingController();

  bool _eAtleta = false;
  bool _isSaving = false;
  String _blockingLabel = 'Aguarde...';
  String? _error;
  late String _graduacaoSelecionada;

  int? get _studentId {
    final id = widget.student["id"];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return null;
  }

  @override
  void initState() {
    super.initState();
    _emailController.text = (widget.student["email"] ?? "").toString();
    _eAtleta = (widget.student["e_atleta"] ?? false) == true;
    _nomeController.text = (widget.student["nome"] ?? "").toString();
    _telefoneController.text = (widget.student["telefone"] ?? "").toString();
    _modalidadeController.text = (widget.student["modalidade"] ?? "").toString();
    _graduacaoSelecionada = graduacaoSelecionavelInicial(
      widget.student["graduacao"]?.toString(),
    );
    _statusController.text = (widget.student["status"] ?? "").toString();
    _tempoTreinoController.text =
        (widget.student["tempo_de_treino"] ?? "").toString();
    _cartelMmaController.text = (widget.student["cartel_mma"] ?? "").toString();
    _cartelJiuController.text = (widget.student["cartel_jiu"] ?? "").toString();
    _cartelK1Controller.text = (widget.student["cartel_k1"] ?? "").toString();
    _nivelCompeticaoController.text =
        (widget.student["nivel_competicao"] ?? "").toString();
    _linkTapologyController.text =
        (widget.student["link_tapology"] ?? "").toString();
    _dataNascimentoController.text =
        (widget.student["data_nascimento"] ?? "").toString();
    _ultimaLutaEmController.text =
        (widget.student["ultima_luta_em"] ?? "").toString();
    _ultimaLutaModalidadeController.text = (widget.student["ultima_luta_modalidade"] ??
            "")
        .toString();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _modalidadeController.dispose();
    _statusController.dispose();
    _tempoTreinoController.dispose();
    _cartelMmaController.dispose();
    _cartelJiuController.dispose();
    _cartelK1Controller.dispose();
    _nivelCompeticaoController.dispose();
    _linkTapologyController.dispose();
    _dataNascimentoController.dispose();
    _ultimaLutaEmController.dispose();
    _ultimaLutaModalidadeController.dispose();
    super.dispose();
  }

  String? _cleanString(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  int? _cleanInt(TextEditingController c) {
    final v = c.text.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  DateTime? _parseDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String _dateToIso(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, "0");
    final d = date.day.toString().padLeft(2, "0");
    return "$y-$m-$d";
  }

  String? _normalizeDate(TextEditingController c) {
    final parsed = _parseDate(c.text);
    if (parsed == null) return null;
    return _dateToIso(parsed);
  }

  String _graduacaoDropdownValue() {
    final items = graduacoesDropdownItens(valorAtual: _graduacaoSelecionada);
    return alignGraduacaoDropdownValue(_graduacaoSelecionada, items);
  }

  /// API aceita só `amador` | `profissional` (StudentUpdate / Literal).
  String? _cleanNivelCompeticao(TextEditingController c) {
    final v = c.text.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v == "amador" || v == "profissional") return v;
    return null;
  }

  Map<String, dynamic> _buildPayload() {
    final enderecoLine = _addressKey.currentState?.composeEndereco().trim();
    // StudentAdminUpdate não tem `email` e usa extra=forbid → enviar "email" gera 422.
    // Só enviar chaves com valor: evita mandar null em tudo e sobrescrever campos no backend.
    final map = <String, dynamic>{
      "nome": _cleanString(_nomeController),
      "telefone": _cleanString(_telefoneController),
      "endereco":
          (enderecoLine == null || enderecoLine.isEmpty) ? null : enderecoLine,
      "modalidade": _cleanString(_modalidadeController),
      "graduacao": () {
        final g = _graduacaoSelecionada.trim();
        final c = canonicalGraduacaoBjj(g);
        return c ?? (g.isEmpty ? graduacaoInicialAluno : g);
      }(),
      "status": _cleanString(_statusController),
      "e_atleta": _eAtleta,
      "tempo_de_treino": _cleanInt(_tempoTreinoController),
      "cartel_mma": _cleanString(_cartelMmaController),
      "cartel_jiu": _cleanString(_cartelJiuController),
      "cartel_k1": _cleanString(_cartelK1Controller),
      "nivel_competicao": _cleanNivelCompeticao(_nivelCompeticaoController),
      "link_tapology": _cleanString(_linkTapologyController),
      "data_nascimento": _normalizeDate(_dataNascimentoController),
      "ultima_luta_em": _normalizeDate(_ultimaLutaEmController),
      "ultima_luta_modalidade": _cleanString(_ultimaLutaModalidadeController),
    };
    map.removeWhere((_, v) => v == null);
    return map;
  }

  Future<void> _save() async {
    final id = _studentId;
    if (id == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
      _blockingLabel = 'Salvando dados do aluno...';
    });
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      final addressState = _addressKey.currentState;
      if (addressState != null) {
        final enderecoErr = addressState.validateEnderecoParaSalvar();
        if (enderecoErr != null) {
          setState(() {
            _isSaving = false;
            _error = enderecoErr;
          });
          return;
        }
      }
      await widget.service.updateStudent(id, _buildPayload());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final id = _studentId;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Excluir aluno"),
          content: const Text("Isso remove o aluno e também o usuário dele."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() {
      _isSaving = true;
      _error = null;
      _blockingLabel = 'Excluindo aluno...';
    });
    try {
      await widget.service.deleteStudent(id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = (widget.student["nome"] ?? "Aluno").toString();

    return Scaffold(
      appBar: AppBar(
        title: Text("Editar: $nome"),
      ),
      body: LoadingOverlay(
        visible: _isSaving,
        message: _blockingLabel,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const Text(
              "Dados do aluno",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      helperText:
                          "Não é alterado ao salvar aluno (rota PUT não aceita email).",
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: "Nome"),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _telefoneController,
                    decoration: const InputDecoration(labelText: "Telefone"),
                  ),
                ),
                SizedBox(
                  width: 520,
                  child: BrAddressEditor(
                    key: _addressKey,
                    studentSnapshot: Map<String, dynamic>.from(widget.student),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _modalidadeController,
                    decoration: const InputDecoration(labelText: "Modalidade"),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: DropdownButtonFormField<String>(
                    value: _graduacaoDropdownValue(),
                    decoration: const InputDecoration(labelText: "Graduação"),
                    items: graduacoesDropdownItens(valorAtual: _graduacaoSelecionada)
                        .map(
                          (g) => DropdownMenuItem<String>(
                            value: g,
                            child: Text(formatGraduacaoDisplay(g)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _graduacaoSelecionada = v);
                    },
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _statusController,
                    decoration: const InputDecoration(labelText: "Status"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _eAtleta,
              onChanged: (v) => setState(() => _eAtleta = v),
              title: const Text("É atleta"),
            ),
            const SizedBox(height: 8),
            Text(
              "Foto do cartão (aba Atletas)",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              "Independente da foto de perfil. Só aparece nos cartões se o aluno for atleta.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: (_isSaving || _studentId == null)
                  ? null
                  : () async {
                      final id = _studentId!;
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (image == null || !mounted) return;
                      setState(() {
                        _isSaving = true;
                        _blockingLabel = 'Enviando foto do cartão...';
                        _error = null;
                      });
                      try {
                        await widget.service.uploadStudentAthleteCardPhoto(
                          id,
                          image.path,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Foto do cartão enviada."),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        setState(() {
                          _error =
                              e.toString().replaceFirst("Exception: ", "");
                        });
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              icon: const Icon(Icons.photo_camera_back_outlined),
              label: const Text("Enviar foto do cartão"),
            ),
            const Divider(height: 24),
            const Text(
              "Competição / Lutas",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _tempoTreinoController,
                    decoration: const InputDecoration(
                      labelText: "Tempo de treino (meses)",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _cartelMmaController,
                    decoration: const InputDecoration(labelText: "Cartel MMA"),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _cartelJiuController,
                    decoration: const InputDecoration(labelText: "Cartel Jiu"),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _cartelK1Controller,
                    decoration: const InputDecoration(labelText: "Cartel K1"),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _nivelCompeticaoController,
                    decoration: const InputDecoration(labelText: "Nivel competição"),
                  ),
                ),
                SizedBox(
                  width: 440,
                  child: TextField(
                    controller: _linkTapologyController,
                    decoration: const InputDecoration(labelText: "Link Tapology"),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _dataNascimentoController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Nascimento",
                      hintText: "YYYY-MM-DD",
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    onTap: () async {
                      final parsed = _parseDate(_dataNascimentoController.text);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: parsed ?? DateTime(2000, 1, 1),
                        firstDate: DateTime(1930, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked == null) return;
                      _dataNascimentoController.text = _dateToIso(picked);
                    },
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _ultimaLutaEmController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Ultima luta",
                      hintText: "YYYY-MM-DD",
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    onTap: () async {
                      final parsed = _parseDate(_ultimaLutaEmController.text);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: parsed ?? DateTime.now(),
                        firstDate: DateTime(1930, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked == null) return;
                      _ultimaLutaEmController.text = _dateToIso(picked);
                    },
                  ),
                ),
                SizedBox(
                  width: 440,
                  child: TextField(
                    controller: _ultimaLutaModalidadeController,
                    decoration: const InputDecoration(labelText: "Ultima luta modalidade"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(_isSaving ? "Salvando..." : "Salvar"),
                ),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Excluir"),
                ),
                OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() => _eAtleta = true);
                        },
                  icon: const Icon(Icons.star),
                  label: const Text("Atleta"),
                ),
                OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() => _eAtleta = false);
                        },
                  icon: const Icon(Icons.star_border),
                  label: const Text("Nao atleta"),
                ),
                OutlinedButton.icon(
                  onPressed: (_isSaving || _emailController.text.trim().isEmpty)
                      ? null
                      : () async {
                          setState(() {
                            _isSaving = true;
                            _blockingLabel = 'Promovendo a administrador...';
                          });
                          try {
                            await widget.service.setUserRoleByEmail(
                              email: _emailController.text.trim(),
                              role: "ADMIN",
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Usuário promovido a ADMIN.")),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {
                              _error = e.toString().replaceFirst("Exception: ", "");
                            });
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  icon: const Icon(Icons.shield),
                  label: const Text("Tornar admin"),
                ),
                OutlinedButton.icon(
                  onPressed: (_isSaving || _emailController.text.trim().isEmpty)
                      ? null
                      : () async {
                          setState(() {
                            _isSaving = true;
                            _blockingLabel = 'Atualizando permissão...';
                          });
                          try {
                            await widget.service.setUserRoleByEmail(
                              email: _emailController.text.trim(),
                              role: "ALUNO",
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Usuário definido como ALUNO.")),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {
                              _error = e.toString().replaceFirst("Exception: ", "");
                            });
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text("Remover admin"),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

