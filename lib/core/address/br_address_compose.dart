/// Monta **uma única string** para o campo `endereco` da API (sem campo `cep` separado).
///
/// Formato típico: `Rua X, 10 - Apto 2 - Centro - São Paulo/SP - CEP 01234-567`
/// (partes vazias são omitidas; separador ` - `).
String composeEnderecoApiLine({
  required String logradouro,
  required String numero,
  required String complemento,
  required String bairro,
  required String localidade,
  required String uf,
  required String cepDigits,
}) {
  final parts = <String>[];
  final l = logradouro.trim();
  final n = numero.trim();
  final comp = complemento.trim();
  final b = bairro.trim();
  final c = localidade.trim();
  final u = uf.trim().toUpperCase();

  if (l.isNotEmpty) {
    if (n.isNotEmpty) {
      parts.add('$l, $n');
    } else {
      parts.add(l);
    }
  } else if (n.isNotEmpty) {
    parts.add(n);
  }

  if (comp.isNotEmpty) {
    parts.add(comp);
  }
  if (b.isNotEmpty) parts.add(b);
  if (c.isNotEmpty && u.isNotEmpty) {
    parts.add('$c/$u');
  } else if (c.isNotEmpty) {
    parts.add(c);
  } else if (u.isNotEmpty) {
    parts.add(u);
  }

  final cepFmt = _formatCepMask(cepDigits);
  if (cepFmt != null) {
    parts.add('CEP $cepFmt');
  }

  return parts.join(' - ');
}

String? _formatCepMask(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length != 8) return null;
  return '${d.substring(0, 5)}-${d.substring(5)}';
}

/// Tenta extrair CEP de um texto de endereço já salvo.
String? extractCepFromEndereco(String? endereco) {
  if (endereco == null || endereco.isEmpty) return null;
  final m = RegExp(r'(\d{5})-?(\d{3})').firstMatch(endereco);
  if (m == null) return null;
  return '${m[1]}-${m[2]}';
}

/// Resultado de [parseEnderecoComposto] — espelha os campos do formulário.
class ParsedBrAddress {
  const ParsedBrAddress({
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.uf = '',
    this.cep = '',
  });

  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  /// `12345-678` ou vazio
  final String cep;
}

/// Heurística: linha no formato montado por [composeEnderecoApiLine] (vários ` - ` ou CEP no texto).
bool looksLikeComposedEnderecoLine(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  if (t.contains(' - ')) return true;
  return RegExp(r'\d{5}-?\d{3}').hasMatch(t);
}

/// Desmonta a string salva em `endereco` (mesmo formato de [composeEnderecoApiLine]).
///
/// Texto legado sem esse formato: devolve o restante em [logradouro] após tirar o CEP.
ParsedBrAddress parseEnderecoComposto(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return const ParsedBrAddress();

  String cep = '';
  final cepSuffix = RegExp(
    r'\s*-\s*CEP\s*(\d{5})-(\d{3})\s*$',
    caseSensitive: false,
  );
  var m = cepSuffix.firstMatch(s);
  if (m != null) {
    cep = '${m[1]}-${m[2]}';
    s = s.substring(0, m.start).trim();
  } else {
    final cepLoose = RegExp(r'(\d{5})-(\d{3})').firstMatch(s);
    if (cepLoose != null) {
      cep = '${cepLoose[1]}-${cepLoose[2]}';
      s = s.replaceFirst(cepLoose.group(0)!, '').trim();
      s = s.replaceAll(RegExp(r'\s*CEP\s*$', caseSensitive: false), '').trim();
      s = s.replaceAll(RegExp(r'^[\s-]+|[\s-]+$'), '').trim();
    }
  }

  final bodyForFallback = s;

  final segs = s
      .split(RegExp(r'\s*-\s*'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  if (segs.isEmpty) {
    return ParsedBrAddress(cep: cep);
  }

  var work = List<String>.from(segs);

  String cidade = '';
  String uf = '';
  if (work.isNotEmpty) {
    final last = work.last;
    final cityUf = RegExp(r'^(.+)/([A-Za-z]{2})$').firstMatch(last);
    if (cityUf != null) {
      cidade = cityUf.group(1)!.trim();
      uf = cityUf.group(2)!.toUpperCase();
      work.removeLast();
    } else if (last.length == 2 && RegExp(r'^[A-Za-z]{2}$').hasMatch(last)) {
      uf = last.toUpperCase();
      work.removeLast();
    }
  }

  String log = '';
  String num = '';
  if (work.isNotEmpty) {
    final first = work.removeAt(0);
    final commaIdx = first.indexOf(',');
    if (commaIdx >= 0) {
      log = first.substring(0, commaIdx).trim();
      num = first.substring(commaIdx + 1).trim();
    } else {
      final onlyDigits = RegExp(r'^\d[\d\w-]*$').hasMatch(first) && first.length <= 8;
      if (onlyDigits) {
        num = first;
      } else {
        log = first;
      }
    }
  }

  String comp = '';
  String bairro = '';
  if (work.length >= 2) {
    comp = work.first;
    bairro = work.sublist(1).join(' - ');
  } else if (work.length == 1) {
    bairro = work.first;
  }

  final parsedAny = log.isNotEmpty ||
      num.isNotEmpty ||
      comp.isNotEmpty ||
      bairro.isNotEmpty ||
      cidade.isNotEmpty ||
      uf.isNotEmpty;
  if (!parsedAny && bodyForFallback.isNotEmpty) {
    log = bodyForFallback;
  }

  return ParsedBrAddress(
    logradouro: log,
    numero: num,
    complemento: comp,
    bairro: bairro,
    cidade: cidade,
    uf: uf,
    cep: cep,
  );
}
