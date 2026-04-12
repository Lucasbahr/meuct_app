import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/dio_unauthorized.dart';
import '../../../core/errors/app_exception.dart';

/// Planos e assinaturas (`/plans`, `/subscriptions`, `/payments/.../pay`).
class MembershipService {
  final Dio dio = ApiClient().dio;

  Future<List<Map<String, dynamic>>> listPlans({bool activeOnly = false}) async {
    try {
      final response = await dio.get(
        "/plans",
        queryParameters: {"active_only": activeOnly},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return [];
      if (data["success"] == false) {
        throw AppException(
          data["message"]?.toString() ?? "Falha ao carregar planos.",
        );
      }
      if (data["data"] is List) {
        return (data["data"] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar planos.");
    }
  }

  Future<Map<String, dynamic>> createPlan({
    required String name,
    required double price,
    required int durationDays,
    bool isActive = true,
  }) async {
    try {
      final response = await dio.post(
        "/plans",
        data: {
          "name": name,
          "price": price,
          "duration_days": durationDays,
          "is_active": isActive,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException("Resposta inválida do servidor.");
      }
      if (data["success"] == false) {
        throw AppException(
          data["message"]?.toString().trim().isNotEmpty == true
              ? data["message"].toString()
              : "Não foi possível criar o plano.",
        );
      }
      if (data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      throw const AppException("Resposta sem dados do plano.");
    } on DioException catch (e) {
      throw _map(e, "Falha ao criar plano.");
    }
  }

  Future<Map<String, dynamic>> createSubscription({
    required int studentId,
    required int planId,
    String? startDate,
  }) async {
    try {
      final body = <String, dynamic>{
        "student_id": studentId,
        "plan_id": planId,
      };
      if (startDate != null && startDate.isNotEmpty) {
        body["start_date"] = startDate;
      }
      final response = await dio.post("/subscriptions", data: body);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException("Resposta inválida do servidor.");
      }
      if (data["success"] == false) {
        throw AppException(
          data["message"]?.toString().trim().isNotEmpty == true
              ? data["message"].toString()
              : "Não foi possível criar a assinatura.",
        );
      }
      if (data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      throw const AppException("Resposta sem dados da assinatura.");
    } on DioException catch (e) {
      throw _map(e, "Falha ao criar assinatura.");
    }
  }

  Future<Map<String, dynamic>> markPaymentPaid(int paymentId) async {
    try {
      final response = await dio.post("/payments/$paymentId/pay");
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException("Resposta inválida do servidor.");
      }
      if (data["success"] == false) {
        throw AppException(
          data["message"]?.toString() ?? "Não foi possível registrar o pagamento.",
        );
      }
      if (data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      throw const AppException("Resposta sem dados do pagamento.");
    } on DioException catch (e) {
      throw _map(e, "Falha ao registrar pagamento.");
    }
  }

  static String formatMoney(dynamic v) {
    if (v == null) return "—";
    if (v is num) return v.toStringAsFixed(2);
    return v.toString();
  }

  AppException _map(DioException e, String fallback) {
    return AppException(dioErrorUserMessage(e, fallback: fallback));
  }
}
