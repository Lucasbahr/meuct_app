/// Contagem a partir da lista retornada por `GET /students/` (mesma base do admin).
class StudentListMetrics {
  StudentListMetrics._();

  static int countTotal(List<Map<String, dynamic>> students) => students.length;

  /// Considera ativo quem não está marcado como cancelado/inativo.
  static int countActive(List<Map<String, dynamic>> students) {
    return students.where(_isActiveRoster).length;
  }

  static bool _isActiveRoster(Map<String, dynamic> s) {
    if (s['cancelado'] == true || s['canceled'] == true) return false;
    if (s['ativo'] == false || s['active'] == false) return false;
    final st = (s['status'] ?? '').toString().toLowerCase().trim();
    if (st.isEmpty) return true;
    if (st.contains('cancel')) return false;
    if (st == 'inativo' || st == 'inactive') return false;
    return true;
  }
}
