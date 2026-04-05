/// Monta uma única linha de endereço para o campo `endereco` da API.
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
