import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';

class AdminStockService {
  final Dio dio = ApiClient().dio;

  Future<void> addStock(int productId, int quantity) async {
    try {
      await dio.post(
        "/stock/add",
        data: {"product_id": productId, "quantity": quantity},
      );
    } on DioException catch (e) {
      throw _map(e, "Falha na entrada de estoque.");
    }
  }

  Future<void> removeStock(
    int productId,
    int quantity, {
    String reason = "manual",
  }) async {
    try {
      await dio.post(
        "/stock/remove",
        data: {
          "product_id": productId,
          "quantity": quantity,
          "reason": reason,
        },
      );
    } on DioException catch (e) {
      throw _map(e, "Falha na saída de estoque.");
    }
  }

  Future<List<Map<String, dynamic>>> listMovements({
    int? productId,
    int limit = 80,
  }) async {
    try {
      final response = await dio.get(
        "/stock/movements",
        queryParameters: {
          if (productId != null) "product_id": productId,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is List) {
        return (data["data"] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .take(limit)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar movimentos.");
    }
  }

  Future<Map<String, dynamic>> getProductStock(int productId) async {
    try {
      final response = await dio.get("/stock/$productId");
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _map(e, "Falha ao carregar estoque do produto.");
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
