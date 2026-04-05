/// Faixas na ordem de progressão. Para incluir novas opções, adicione à lista.
const List<String> kGraduacoesBjjOrdenadas = [
  'branca',
  'ponta vermelha',
  'vermelha',
  'ponta azul claro',
  'azul claro',
  'ponta azul escuro',
  'azul escuro',
  'ponta preta',
  'preta',
];

/// Todo aluno começa nesta faixa até a equipe alterar no painel admin.
String get graduacaoInicialAluno => kGraduacoesBjjOrdenadas.first;

/// Corresponde texto da API a uma entrada canônica da lista (ignora maiúsculas).
String? canonicalGraduacaoBjj(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  for (final g in kGraduacoesBjjOrdenadas) {
    if (g.toLowerCase() == t.toLowerCase()) return g;
  }
  return null;
}

/// Valor inicial para formulários (API vazia ou desconhecida → branca).
String graduacaoSelecionavelInicial(String? apiRaw) {
  final c = canonicalGraduacaoBjj(apiRaw);
  if (c != null) return c;
  final raw = apiRaw?.trim() ?? '';
  if (raw.isNotEmpty) return raw;
  return graduacaoInicialAluno;
}

/// Opções do dropdown: lista padrão + valor legado que não está na lista.
List<String> graduacoesDropdownItens({required String valorAtual}) {
  final out = List<String>.from(kGraduacoesBjjOrdenadas);
  final sel = valorAtual.trim();
  if (sel.isEmpty) return out;
  if (canonicalGraduacaoBjj(sel) != null) return out;
  final dup = out.any((e) => e.toLowerCase() == sel.toLowerCase());
  if (!dup) out.add(sel);
  return out;
}

/// Garante que [DropdownButtonFormField.value] exista em [itens] (mesma grafia).
String alignGraduacaoDropdownValue(String selecionada, List<String> itens) {
  final want = selecionada.trim();
  for (final g in itens) {
    if (g.toLowerCase() == want.toLowerCase()) return g;
  }
  return itens.isNotEmpty ? itens.first : graduacaoInicialAluno;
}

/// Texto amigável para UI (título por palavra).
String formatGraduacaoDisplay(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  return raw
      .trim()
      .split(RegExp(r'\s+'))
      .map((w) {
        if (w.isEmpty) return w;
        return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
      })
      .join(' ');
}
