import 'package:dio/dio.dart';

/// Resposta 401: sessão inválida ou token expirado.
bool dioIsUnauthorized(Object? error) {
  return error is DioException && error.response?.statusCode == 401;
}

/// Resposta 404 (ex.: admin de sistema sem ficha de aluno na academia ativa).
bool dioIsNotFound(Object? error) {
  return error is DioException && error.response?.statusCode == 404;
}

/// Extrai mensagem legível de [DioException] (API MeuCT / FastAPI).
String dioErrorUserMessage(DioException e, {String fallback = "Falha na requisição."}) {
  if (e.response?.statusCode == 429) {
    final ra = e.response?.headers.value('retry-after');
    if (ra != null && ra.trim().isNotEmpty) {
      final sec = int.tryParse(ra.trim());
      if (sec != null && sec > 0) {
        final min = (sec / 60).ceil();
        return min <= 1
            ? "Muitas tentativas. Aguarde cerca de $sec segundos e tente de novo."
            : "Muitas tentativas. Aguarde cerca de $min minutos e tente de novo.";
      }
    }
    return "Muitas tentativas. Aguarde um momento e tente de novo.";
  }

  final raw = e.response?.data;
  if (raw is Map) {
    final body = Map<String, dynamic>.from(raw);
    final msg = body["message"];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    final detail = body["detail"];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    if (detail is List) {
      final parts = <String>[];
      for (final item in detail) {
        if (item is Map && item["msg"] is String) {
          parts.add(item["msg"] as String);
        } else if (item is String) {
          parts.add(item);
        }
      }
      if (parts.isNotEmpty) return parts.join(" ");
    }
  }
  return fallback;
}
