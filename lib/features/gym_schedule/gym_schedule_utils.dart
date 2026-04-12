/// API: segunda = 0 … domingo = 6 (alinhado a `datetime.weekday` em Python).
/// Dart: `weekday` é 1=seg … 7=dom.
int apiScheduleWeekday(DateTime d) => (d.weekday + 6) % 7;

/// Slots da grade para o dia da semana [apiWd] (0–6), ordenados por horário.
List<Map<String, dynamic>> slotsForApiWeekday(
  List<Map<String, dynamic>> grouped,
  int apiWd,
) {
  final out = <Map<String, dynamic>>[];
  for (final day in grouped) {
    final wd = day["weekday"];
    final w = wd is int ? wd : int.tryParse("$wd");
    if (w != apiWd) continue;
    final slots = day["slots"];
    if (slots is! List) continue;
    for (final raw in slots) {
      if (raw is Map) {
        out.add(Map<String, dynamic>.from(raw));
      }
    }
  }
  out.sort((a, b) {
    final sa = (a["start_time"] ?? "").toString();
    final sb = (b["start_time"] ?? "").toString();
    return sa.compareTo(sb);
  });
  return out;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Dias do mês em grade 7 colunas (segunda primeira coluna). `null` = célula vazia.
List<DateTime?> monthCalendarGrid(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  final lead = apiScheduleWeekday(first);
  final out = <DateTime?>[];
  for (var i = 0; i < lead; i++) {
    out.add(null);
  }
  for (var d = 1; d <= lastDay; d++) {
    out.add(DateTime(month.year, month.month, d));
  }
  while (out.length % 7 != 0) {
    out.add(null);
  }
  return out;
}
