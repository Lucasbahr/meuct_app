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

  Future<Map<String, dynamic>> dashboardSales({
    int? days,
    int topProductsLimit = 10,
  }) async {
    try {
      final response = await dio.get(
        "/dashboard/sales",
        queryParameters: {
          if (days != null) "days": days,
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
