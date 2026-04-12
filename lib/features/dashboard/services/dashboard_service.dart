import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';

class DashboardService {
  final Dio dio = ApiClient().dio;

  Future<Map<String, dynamic>> dashboardMe() async {
    try {
      final response = await dio.get("/dashboard/me");
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar seu painel.");
    }
  }

  /// Equipe da academia (admin sistema, admin academia, professor).
  Future<Map<String, dynamic>> dashboardAcademy({
    int auditLimit = 80,
    int loginsLimit = 30,
  }) async {
    try {
      final response = await dio.get(
        "/dashboard/academy",
        queryParameters: {
          "audit_limit": auditLimit,
          "logins_limit": loginsLimit,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar painel da academia.");
    }
  }

  /// Alertas de mensalidade: `due_soon` (vencendo) e `overdue` (atrasadas).
  /// `GET /students/alerts` — equipe (`require_staff`).
  Future<Map<String, dynamic>> studentsSubscriptionAlerts() async {
    try {
      final response = await dio.get("/students/alerts");
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {"due_soon": [], "overdue": []};
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar alertas de mensalidade.");
    }
  }

  /// Totais por status de assinatura. `GET /reports/students`.
  Future<Map<String, dynamic>> reportsStudents() async {
    try {
      final response = await dio.get("/reports/students");
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar relatório de alunos.");
    }
  }

  /// Indicadores agregados (receita loja, mensalidades, alunos, séries mensais).
  /// `GET /dashboard/analytics` — query `months` opcional (ex.: 6 ou 12).
  Future<Map<String, dynamic>> dashboardAnalytics({int? months}) async {
    try {
      final response = await dio.get(
        '/dashboard/analytics',
        queryParameters: {
          ...?months != null ? {'months': months} : null,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _map(e, 'Falha ao carregar indicadores da academia.');
    }
  }

  /// Registra contagem de alunos no dia (para série histórica no servidor).
  /// `POST /dashboard/analytics/headcount` — corpo JSON; falha silenciosa se 404/405.
  Future<bool> submitStudentHeadcountSnapshot({
    required int activeStudents,
    required int totalStudents,
    DateTime? capturedAt,
  }) async {
    try {
      final response = await dio.post(
        '/dashboard/analytics/headcount',
        data: {
          'active_students': activeStudents,
          'total_students': totalStudents,
          'captured_at': (capturedAt ?? DateTime.now()).toUtc().toIso8601String(),
        },
      );
      final code = response.statusCode ?? 0;
      return code >= 200 && code < 300;
    } on DioException catch (e) {
      final c = e.response?.statusCode ?? 0;
      if (c == 404 || c == 405 || c == 501) return false;
      return false;
    }
  }

  Future<Map<String, dynamic>> dashboardSales({
    int? days,
    int topProductsLimit = 10,
  }) async {
    try {
      final response = await dio.get(
        "/dashboard/sales",
        queryParameters: {
          ...?days != null ? {'days': days} : null,
          "top_products_limit": topProductsLimit,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar vendas.");
    }
  }

  AppException _map(DioException e, String fallback) {
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      final d = body["detail"];
      final m = body["message"];
      if (d is String && d.isNotEmpty) return AppException(d);
      if (m is String && m.isNotEmpty) return AppException(m);
    }
    return AppException(fallback);
  }
}
