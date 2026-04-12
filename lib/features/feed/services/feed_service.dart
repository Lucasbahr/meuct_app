import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';

class FeedService {
  final Dio dio = ApiClient().dio;

  Future<List<Map<String, dynamic>>> listFeed({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        "/feed/",
        queryParameters: {
          "limit": limit,
          "offset": offset,
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
      throw _mapError(e, "Falha ao carregar feed.");
    }
  }

  Future<Map<String, dynamic>> createItem(Map<String, dynamic> payload) async {
    try {
      final response = await dio.post("/feed/", data: payload);
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao criar item do feed.");
    }
  }

  Future<Map<String, dynamic>> getItem(int itemId) async {
    try {
      final response = await dio.get("/feed/$itemId");
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao carregar post.");
    }
  }

  Future<Map<String, dynamic>> updateItem(
    int itemId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await dio.put("/feed/$itemId", data: payload);
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao atualizar item do feed.");
    }
  }

  Future<void> uploadPhoto(int itemId, String filePath) async {
    try {
      final fileName = filePath.split("\\").last;
      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
      });
      await dio.post("/feed/$itemId/photo", data: formData);
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao enviar foto do feed.");
    }
  }

  Future<void> like(int itemId) async {
    try {
      await dio.post("/feed/$itemId/likes");
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao curtir.");
    }
  }

  Future<void> unlike(int itemId) async {
    try {
      await dio.delete("/feed/$itemId/likes");
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao remover curtida.");
    }
  }

  Future<List<Map<String, dynamic>>> listComments(int itemId) async {
    try {
      final response = await dio.get("/feed/$itemId/comments");
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is List) {
        return (data["data"] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao carregar comentários.");
    }
  }

  Future<void> addComment(int itemId, String content) async {
    try {
      await dio.post(
        "/feed/$itemId/comments",
        data: {"conteudo": content},
      );
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao comentar.");
    }
  }

  Future<void> deleteItem(int itemId) async {
    try {
      await dio.delete("/feed/$itemId");
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao excluir post.");
    }
  }

  /// Tenta vários paths comuns (a OpenAPI nem sempre lista DELETE).
  Future<void> deleteComment(int itemId, Object commentId) async {
    final idStr = commentId.toString();
    final enc = Uri.encodeComponent(idStr);

    Future<void> tryDelete(
      String path, {
      Map<String, dynamic>? query,
    }) async {
      await dio.delete(path, queryParameters: query);
    }

    final attempts = <Future<void> Function()>[
      () => tryDelete("/feed/$itemId/comments", query: {"comment_id": idStr}),
      () => tryDelete("/feed/$itemId/comments", query: {"id": idStr}),
      () => tryDelete("/feed/$itemId/comments/$enc"),
      () => tryDelete("/feed/$itemId/comments/$enc/"),
      () => tryDelete("/feed/comments/$enc"),
      () => tryDelete("/feed/comments/$enc/"),
    ];

    DioException? last;
    for (final run in attempts) {
      try {
        await run();
        return;
      } on DioException catch (e) {
        last = e;
        final code = e.response?.statusCode;
        if (code != null && code != 404 && code != 405) {
          throw _mapError(e, "Falha ao excluir comentário.");
        }
      }
    }
    if (last != null) {
      throw _mapError(
        last,
        "Não foi possível excluir o comentário. "
        "Confirme no servidor um endpoint DELETE (ex.: /feed/{id}/comments/{id}).",
      );
    }
    throw AppException(
      "Não foi possível excluir o comentário.",
    );
  }

  String? resolveImageUrl(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    if (raw.startsWith("http")) return raw;
    if (raw.startsWith("/")) return "${ApiClient.baseUrl}$raw";
    return "${ApiClient.baseUrl}/$raw";
  }

  AppException _mapError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data["detail"];
      final message = data["message"];
      if (detail is String && detail.isNotEmpty) return AppException(detail);
      if (message is String && message.isNotEmpty) return AppException(message);
    }
    final code = e.response?.statusCode;
    if (code == 500) {
      return AppException(
        "$fallback O servidor falhou (500). "
        "Se a API foi atualizada, falta migração no banco (alembic upgrade head ou novo deploy da API com Docker).",
      );
    }
    return AppException(fallback);
  }
}

