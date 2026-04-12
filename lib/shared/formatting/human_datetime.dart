/// Formatação legível (sem dependência `intl`).
String formatBrazilDateTime(DateTime? dt) {
  if (dt == null) return '';
  final d = dt.toLocal();
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year} · $hh:$min';
}

String formatBrazilDate(DateTime? dt) {
  if (dt == null) return '';
  final d = dt.toLocal();
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

DateTime? tryParseIso(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// "joao.silva@mail.com" → "Joao Silva"
String friendlyNameFromEmail(String? email) {
  if (email == null || email.isEmpty) return 'Aluno';
  final at = email.indexOf('@');
  final local = (at > 0 ? email.substring(0, at) : email).trim();
  if (local.isEmpty) return 'Aluno';
  return local
      .replaceAll(RegExp(r'[._-]+'), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) {
        if (w.isEmpty) return w;
        return '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}';
      })
      .join(' ');
}
