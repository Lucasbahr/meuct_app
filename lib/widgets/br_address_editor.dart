import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/address/br_address_compose.dart';
import '../core/address/viacep_service.dart';

/// Máscara simples 00000-000
class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 8; i++) {
      if (i == 5) buf.write('-');
      buf.write(digits[i]);
    }
    final t = buf.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// Campos CEP + endereço; ao salvar use [composeEndereco] (uma string para a API).
class BrAddressEditor extends StatefulWidget {
  const BrAddressEditor({
    super.key,
    required this.studentSnapshot,
  });

  /// Mapa do aluno (`endereco`, opcionalmente `cep`, `logradouro`, etc.).
  final Map<String, dynamic> studentSnapshot;

  @override
  BrAddressEditorState createState() => BrAddressEditorState();
}

class BrAddressEditorState extends State<BrAddressEditor> {
  final _viaCep = ViaCepService();
  final _cep = TextEditingController();
  final _logradouro = TextEditingController();
  final _numero = TextEditingController();
  final _complemento = TextEditingController();
  final _bairro = TextEditingController();
  final _cidade = TextEditingController();
  final _uf = TextEditingController();

  bool _loadingCep = false;
  String? _cepError;

  @override
  void initState() {
    super.initState();
    _hydrateFromMap(widget.studentSnapshot);
  }

  @override
  void didUpdateWidget(BrAddressEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.studentSnapshot['id'];
    final newId = widget.studentSnapshot['id'];
    final oldEnd = oldWidget.studentSnapshot['endereco']?.toString();
    final newEnd = widget.studentSnapshot['endereco']?.toString();
    if (oldId != newId || oldEnd != newEnd) {
      setState(() => _hydrateFromMap(widget.studentSnapshot));
    }
  }

  /// Restaura campos a partir do mapa (ex.: ao cancelar edição no perfil).
  void hydrateFrom(Map<String, dynamic> student) {
    setState(() {
      _hydrateFromMap(student);
    });
  }

  void _hydrateFromMap(Map<String, dynamic> m) {
    final end = (m['endereco'] ?? '').toString().trim();
    final logM = (m['logradouro'] ?? '').toString().trim();
    final numM = (m['numero'] ?? '').toString().trim();
    final compM = (m['complemento'] ?? '').toString();
    final bairroM = (m['bairro'] ?? '').toString();
    final cidadeM =
        (m['localidade'] ?? m['cidade'] ?? '').toString();
    final ufM = (m['uf'] ?? '').toString();

    var parseSource = end;
    if (parseSource.isEmpty && looksLikeComposedEnderecoLine(logM)) {
      parseSource = logM;
    }

    final cepRaw = (m['cep'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
    if (cepRaw.length == 8) {
      _cep.text = '${cepRaw.substring(0, 5)}-${cepRaw.substring(5)}';
    } else {
      final ex = extractCepFromEndereco(
        parseSource.isNotEmpty ? parseSource : (end.isNotEmpty ? end : logM),
      );
      _cep.text = ex ?? '';
    }

    if (parseSource.isNotEmpty) {
      final p = parseEnderecoComposto(parseSource);
      _logradouro.text = p.logradouro.isNotEmpty ? p.logradouro : logM;
      _numero.text = p.numero.isNotEmpty ? p.numero : numM;
      _complemento.text =
          p.complemento.isNotEmpty ? p.complemento : compM;
      _bairro.text = p.bairro.isNotEmpty ? p.bairro : bairroM;
      _cidade.text = p.cidade.isNotEmpty ? p.cidade : cidadeM;
      _uf.text = p.uf.isNotEmpty ? p.uf : ufM;
      if (p.cep.isNotEmpty) {
        _cep.text = p.cep;
      }
      return;
    }

    final hasStructured = logM.isNotEmpty ||
        numM.isNotEmpty ||
        bairroM.trim().isNotEmpty ||
        cidadeM.trim().isNotEmpty ||
        ufM.trim().isNotEmpty;

    if (hasStructured) {
      _logradouro.text = logM;
      _numero.text = numM;
      _complemento.text = compM;
      _bairro.text = bairroM;
      _cidade.text = cidadeM;
      _uf.text = ufM;
    } else {
      _logradouro.clear();
      _numero.clear();
      _complemento.clear();
      _bairro.clear();
      _cidade.clear();
      _uf.clear();
    }
  }

  @override
  void dispose() {
    _cep.dispose();
    _logradouro.dispose();
    _numero.dispose();
    _complemento.dispose();
    _bairro.dispose();
    _cidade.dispose();
    _uf.dispose();
    super.dispose();
  }

  bool _algumCampoEnderecoPreenchido() {
    return _logradouro.text.trim().isNotEmpty ||
        _numero.text.trim().isNotEmpty ||
        _complemento.text.trim().isNotEmpty ||
        _bairro.text.trim().isNotEmpty ||
        _cidade.text.trim().isNotEmpty ||
        _uf.text.trim().isNotEmpty ||
        _cep.text.replaceAll(RegExp(r'\D'), '').isNotEmpty;
  }

  /// Complemento opcional. Se qualquer parte do endereço estiver preenchida, exige o restante (com número e CEP).
  String? validateEnderecoParaSalvar() {
    if (!_algumCampoEnderecoPreenchido()) return null;
    if (_logradouro.text.trim().isEmpty) {
      return 'Informe o logradouro (rua, avenida…).';
    }
    if (_numero.text.trim().isEmpty) {
      return 'Informe o número. Só o complemento é opcional.';
    }
    if (_bairro.text.trim().isEmpty) return 'Informe o bairro.';
    if (_cidade.text.trim().isEmpty) return 'Informe a cidade.';
    if (_uf.text.trim().length != 2) {
      return 'Informe a UF com 2 letras.';
    }
    final cep = _cep.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) return 'Informe o CEP com 8 dígitos.';
    return null;
  }

  /// Valor para `endereco` na API (uma linha, formato brasileiro comum).
  String composeEndereco() {
    return composeEnderecoApiLine(
      logradouro: _logradouro.text,
      numero: _numero.text,
      complemento: _complemento.text,
      bairro: _bairro.text,
      localidade: _cidade.text,
      uf: _uf.text,
      cepDigits: _cep.text,
    );
  }

  Future<void> _buscarCep() async {
    final digits = _cep.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      setState(() => _cepError = 'Informe 8 dígitos do CEP.');
      return;
    }
    setState(() {
      _loadingCep = true;
      _cepError = null;
    });
    final r = await _viaCep.lookup(digits);
    if (!mounted) return;
    setState(() => _loadingCep = false);
    if (r == null) {
      setState(() => _cepError = 'CEP não encontrado.');
      return;
    }
    setState(() {
      _cep.text = r.cep.isNotEmpty ? r.cep : _cep.text;
      if (r.logradouro.isNotEmpty) _logradouro.text = r.logradouro;
      if (r.bairro.isNotEmpty) _bairro.text = r.bairro;
      if (r.localidade.isNotEmpty) _cidade.text = r.localidade;
      if (r.uf.isNotEmpty) _uf.text = r.uf;
      if (r.complemento.isNotEmpty && _complemento.text.isEmpty) {
        _complemento.text = r.complemento;
      }
      _cepError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Endereço',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _cep,
                keyboardType: TextInputType.number,
                inputFormatters: [_CepFormatter()],
                decoration: const InputDecoration(
                  labelText: 'CEP',
                  hintText: '00000-000',
                ),
                onSubmitted: (_) => _buscarCep(),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _loadingCep
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : OutlinedButton.icon(
                      onPressed: _buscarCep,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Buscar'),
                    ),
            ),
          ],
        ),
        if (_cepError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _cepError!,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _logradouro,
          decoration: const InputDecoration(
            labelText: 'Logradouro',
            hintText: 'Rua, avenida…',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _numero,
                decoration: const InputDecoration(
                  labelText: 'Número',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _complemento,
                decoration: const InputDecoration(
                  labelText: 'Complemento',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bairro,
          decoration: const InputDecoration(labelText: 'Bairro'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _cidade,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _uf,
                textCapitalization: TextCapitalization.characters,
                maxLength: 2,
                decoration: const InputDecoration(
                  labelText: 'UF',
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
