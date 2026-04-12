import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';

class GymService {
  final Dio dio = ApiClient().dio;

  static List<Map<String, dynamic>> _parseDataList(dynamic responseBody) {
    if (responseBody is Map<String, dynamic> && responseBody["data"] is List) {
      return (responseBody["data"] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  /// Lista academias (tenant). Na API atual, `GET /gyms` não exige autenticação.
  Future<List<Map<String, dynamic>>> listGyms() async {
    try {
      final response = await dio.get("/gyms");
      return _parseDataList(response.data);
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao carregar academias.");
    }
  }

  static int? parseGymId(Map<String, dynamic> row) {
    final v = row["id"] ?? row["gym_id"];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Nome amigável para exibição (sem expor id como “nome”).
  static String parseGymName(Map<String, dynamic> row) {
    for (final key in [
      "name",
      "nome",
      "gym_name",
      "tenant_name",
      "title",
      "label",
    ]) {
      final v = row[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    final tenant = row["tenant"];
    if (tenant is Map) {
      final t = Map<String, dynamic>.from(tenant);
      for (final key in ["nome", "name"]) {
        final v = t[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return "Academia";
  }

  AppException _mapError(DioException e, String fallback) {
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
