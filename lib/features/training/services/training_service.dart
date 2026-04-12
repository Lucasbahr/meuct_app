import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';

/// Progresso, gamificação e ranking (`training_routes` na API).
class TrainingService {
  final Dio dio = ApiClient().dio;

  Future<List<Map<String, dynamic>>> getStudentProgress(
    int studentId, {
    int? modalityId,
  }) async {
    try {
      final response = await dio.get(
        "/students/$studentId/progress",
        queryParameters: {
          if (modalityId != null) "modality_id": modalityId,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is List) {
        return (data["data"] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar progresso.");
    }
  }

  Future<Map<String, dynamic>> getStudentGamification(int studentId) async {
    try {
      final response = await dio.get("/students/$studentId/gamification");
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar gamificação.");
    }
  }

  Future<List<Map<String, dynamic>>> getMyGraduationEligibility() async {
    try {
      final response = await dio.get("/training/me/graduation-eligibility");
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is List) {
        return (data["data"] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar elegibilidade para graduação.");
    }
  }

  Future<void> requestGraduation({
    required int modalityId,
    String? preferredDateIso,
    String? note,
  }) async {
    try {
      await dio.post(
        "/training/me/graduation-request",
        data: {
          "modality_id": modalityId,
          if (preferredDateIso != null && preferredDateIso.isNotEmpty)
            "preferred_date": preferredDateIso,
          if (note != null && note.isNotEmpty) "note": note,
        },
      );
    } on DioException catch (e) {
      throw _map(e, "Falha ao enviar solicitação de graduação.");
    }
  }

  Future<List<Map<String, dynamic>>> getRanking({int limit = 20}) async {
    try {
      final response = await dio.get(
        "/ranking",
        queryParameters: {"limit": limit},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is List) {
        return (data["data"] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar ranking.");
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
