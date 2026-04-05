import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';

class CheckinService {
  final Dio dio = ApiClient().dio;

  /// Quantidade de dias distintos com pelo menos um check-in (útil para evolução / graduação).
  static int countDistinctTrainingDays(List<Map<String, dynamic>> history) {
    var days = 0;
    for (final item in history) {
      final total = (item['total'] as num?)?.toInt() ?? 0;
      if (total > 0) days++;
    }
    return days;
  }

  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await dio.get("/checkin/me/summary");
      return response.data["data"] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e, fallback: "Falha ao carregar resumo.");
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await dio.get("/checkin/me/history");
      final data = response.data["data"];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapError(e, fallback: "Falha ao carregar histórico.");
    }
  }

  Future<void> doCheckin() async {
    try {
      await dio.post("/checkin/");
    } on DioException catch (e) {
      throw _mapError(e, fallback: "Falha ao realizar check-in.");
    }
  }

  AppException _mapError(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data["detail"];
      final message = data["message"];
      if (detail is String && detail.isNotEmpty) return AppException(detail);
      if (message is String && message.isNotEmpty) return AppException(message);
    }
    return AppException(fallback);
  }
}

