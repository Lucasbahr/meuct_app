import 'package:dio/dio.dart';

/// Resposta 401: sessão inválida ou token expirado.
bool dioIsUnauthorized(Object? error) {
  return error is DioException && error.response?.statusCode == 401;
}
