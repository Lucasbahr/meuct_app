// Modelo de leitura defensiva do payload de analytics da academia.
// Aceita chaves em inglês ou português; séries com revenue/total/valor e
// período em month, year_month, mes, period ou year+month.

typedef MonthlyPoint = ({String label, double value});

class DashboardAnalyticsViewModel {
  const DashboardAnalyticsViewModel({
    required this.productRevenueTotal,
    required this.productRevenueByMonth,
    required this.subscriptionByMonth,
    required this.studentsThisMonth,
    required this.studentsByMonth,
    required this.revenueMomPct,
    required this.subscriptionMomPct,
    required this.studentsMomPct,
  });

  final double? productRevenueTotal;
  final List<MonthlyPoint> productRevenueByMonth;
  final List<MonthlyPoint> subscriptionByMonth;
  final int? studentsThisMonth;
  final List<MonthlyPoint> studentsByMonth;
  final double? revenueMomPct;
  final double? subscriptionMomPct;
  final double? studentsMomPct;

  static DashboardAnalyticsViewModel fromPayload(Map<String, dynamic> raw) {
    final root = _flattenPayload(raw);

    final productTotal = _firstDouble(root, const [
      'product_revenue_total',
      'total_product_revenue',
      'store_revenue_total',
      'vendas_produtos_total',
      'renda_produtos',
      'receita_loja_total',
    ]);

    final productSeries = _mergeSeries([
      _parseSeries(root['product_revenue_by_month']),
      _parseSeries(root['product_sales_by_month']),
      _parseSeries(root['vendas_produtos_por_mes']),
      _parseSeries(root['loja_receita_mensal']),
      _parseSeries(root['store_revenue_by_month']),
      _parseNestedSeries(root['product_sales'], 'by_month'),
      _parseNestedSeries(root['vendas_loja'], 'por_mes'),
    ]);

    final subSeries = _mergeSeries([
      _parseSeries(root['subscription_revenue_by_month']),
      _parseSeries(root['mensalidade_por_mes']),
      _parseSeries(root['assinaturas_receita_mensal']),
      _parseSeries(root['receita_mensalidades_mes']),
      _parseNestedSeries(root['subscription'], 'revenue_by_month'),
      _parseNestedSeries(root['mensalidades'], 'por_mes'),
    ]);

    final studentsMonth = _firstInt(root, const [
      'students_this_month',
      'students_active_this_month',
      'alunos_mes',
      'alunos_este_mes',
      'novos_alunos_mes',
      'active_students_month',
    ]);

    final studentsSeries = _mergeSeries([
      _parseSeries(root['students_by_month']),
      _parseSeries(root['new_students_by_month']),
      _parseSeries(root['alunos_novos_por_mes']),
      _parseSeries(root['matriculas_por_mes']),
      _parseNestedSeries(root['students'], 'by_month'),
      _parseNestedSeries(root['alunos'], 'por_mes'),
    ]);

    final revMom = _firstDouble(root, const [
      'revenue_mom_pct',
      'revenue_growth_mom_pct',
      'evolucao_receita_pct',
      'crescimento_receita_mes',
    ]);
    final subMom = _firstDouble(root, const [
      'subscription_mom_pct',
      'mensalidade_mom_pct',
      'evolucao_mensalidade_pct',
    ]);
    final stMom = _firstDouble(root, const [
      'students_mom_pct',
      'alunos_mom_pct',
      'evolucao_alunos_pct',
    ]);

    return DashboardAnalyticsViewModel(
      productRevenueTotal: productTotal ?? _sumSeries(productSeries),
      productRevenueByMonth: productSeries,
      subscriptionByMonth: subSeries,
      studentsThisMonth: studentsMonth,
      studentsByMonth: studentsSeries,
      revenueMomPct: revMom ?? _momPctFromSeries(productSeries),
      subscriptionMomPct: subMom ?? _momPctFromSeries(subSeries),
      studentsMomPct: stMom ?? _momPctFromSeries(studentsSeries),
    );
  }

  static Map<String, dynamic> _flattenPayload(Map<String, dynamic> raw) {
    final m = Map<String, dynamic>.from(raw);
    for (final key in ['analytics', 'analitico', 'insights', 'indicadores']) {
      final inner = m[key];
      if (inner is Map) {
        m.addAll(Map<String, dynamic>.from(inner));
      }
    }
    return m;
  }

  static List<MonthlyPoint> _parseNestedSeries(dynamic parent, String childKey) {
    if (parent is! Map) return [];
    return _parseSeries(parent[childKey]);
  }

  static List<MonthlyPoint> _parseSeries(dynamic raw) {
    if (raw is! List) return [];
    final out = <MonthlyPoint>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final row = Map<String, dynamic>.from(e);
      final label = _labelForRow(row);
      final v = _rowValue(row);
      if (label == null || v == null) continue;
      out.add((label: label, value: v));
    }
    return out;
  }

  static List<MonthlyPoint> _mergeSeries(List<List<MonthlyPoint>> parts) {
    final merged = <String, double>{};
    for (final list in parts) {
      for (final p in list) {
        merged[p.label] = p.value;
      }
    }
    final keys = merged.keys.toList()..sort(_compareMonthLabels);
    return [for (final k in keys) (label: k, value: merged[k]!)];
  }

  static int _compareMonthLabels(String a, String b) {
    final da = _tryParseMonthKey(a);
    final db = _tryParseMonthKey(b);
    if (da != null && db != null) return da.compareTo(db);
    return a.compareTo(b);
  }

  static DateTime? _tryParseMonthKey(String s) {
    final t = s.trim();
    final iso = RegExp(r'^(\d{4})-(\d{1,2})');
    final m = iso.firstMatch(t);
    if (m != null) {
      final y = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      if (y != null && mo != null) return DateTime(y, mo);
    }
    final slash = RegExp(r'^(\d{1,2})/(\d{2,4})$').firstMatch(t);
    if (slash != null) {
      final mo = int.tryParse(slash.group(1)!);
      var y = int.tryParse(slash.group(2)!);
      if (y != null && y < 100) y += 2000;
      if (mo != null && y != null) return DateTime(y, mo);
    }
    return null;
  }

  static String? _labelForRow(Map<String, dynamic> row) {
    for (final k in const [
      'label',
      'month_label',
      'mes_label',
    ]) {
      final v = row[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    for (final k in const [
      'year_month',
      'month',
      'mes',
      'period',
      'reference',
      'ref',
    ]) {
      final v = row[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isEmpty) continue;
      final pretty = _prettyMonthLabel(s);
      if (pretty != null) return pretty;
    }
    final y = _firstInt(row, const ['year', 'ano']);
    final mo = _firstInt(row, const ['month', 'mes', 'mes_num']);
    if (y != null && mo != null) {
      return '${_mesAbbr(mo)}/${(y % 100).toString().padLeft(2, '0')}';
    }
    return null;
  }

  static String? _prettyMonthLabel(String raw) {
    final iso = RegExp(r'^(\d{4})-(\d{1,2})(?:-(\d{1,2}))?').firstMatch(raw);
    if (iso != null) {
      final y = int.tryParse(iso.group(1)!);
      final mo = int.tryParse(iso.group(2)!);
      if (y != null && mo != null) {
        return '${_mesAbbr(mo)}/${(y % 100).toString().padLeft(2, '0')}';
      }
    }
    return raw.length > 12 ? raw.substring(0, 12) : raw;
  }

  static String _mesAbbr(int m) {
    const abbr = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    if (m < 1 || m > 12) return m.toString();
    return abbr[m - 1];
  }

  static double? _rowValue(Map<String, dynamic> row) {
    return _firstDouble(row, const [
      'revenue',
      'total_revenue',
      'total',
      'valor',
      'amount',
      'receita',
      'value',
      'count',
      'total_alunos',
      'novos',
      'students',
    ]);
  }

  static double? _firstDouble(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is num) return v.toDouble();
      final d = double.tryParse(v.toString().replaceAll(',', '.'));
      if (d != null) return d;
    }
    return null;
  }

  static int? _firstInt(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is int) return v;
      if (v is num) return v.toInt();
      final i = int.tryParse(v.toString());
      if (i != null) return i;
    }
    return null;
  }

  static double? _sumSeries(List<MonthlyPoint> s) {
    if (s.isEmpty) return null;
    var t = 0.0;
    for (final p in s) {
      t += p.value;
    }
    return t;
  }

  static double? _momPctFromSeries(List<MonthlyPoint> s) {
    if (s.length < 2) return null;
    final prev = s[s.length - 2].value;
    final last = s[s.length - 1].value;
    if (prev == 0) return null;
    return ((last - prev) / prev) * 100;
  }
}
