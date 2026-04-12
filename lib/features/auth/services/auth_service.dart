import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/api_response.dart';
import '../../../core/api/api_client.dart';

class AuthService {
  final Dio dio = ApiClient().dio;

  Future<String> login(String email, String password) async {
    try {
      final response = await dio.post(
        "/auth/login",
        data: {
          "email": email,
          "password": password,
        },
      );

      final apiResponse = _parseResponse(response.data);
      final data = apiResponse.data;

      if (data is Map<String, dynamic>) {
        final token = data["access_token"];
        if (token is String && token.isNotEmpty) return token;
      }

      throw const AppException(
        "Token de acesso nao encontrado na resposta do login.",
      );
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: "Falha ao autenticar no servidor.");
    }
  }

  Future<void> register(
    String email,
    String password, {
    int? gymId,
  }) async {
    try {
      final body = <String, dynamic>{
        "email": email,
        "password": password,
      };
      if (gymId != null) {
        body["gym_id"] = gymId;
      }
      await dio.post(
        "/auth/register",
        data: body,
      );
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: "Falha ao registrar usuario.");
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await dio.post(
        "/auth/resend-verification",
        queryParameters: {"email": email},
      );
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: "Falha ao reenviar verificacao.");
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await dio.post(
        "/auth/forgot-password",
        queryParameters: {"email": email},
      );
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: "Falha ao solicitar redefinicao de senha.");
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await dio.post(
        "/auth/reset-password",
        queryParameters: {
          "token": token,
          "new_password": newPassword,
        },
      );
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: "Falha ao redefinir senha.");
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await dio.put(
        "/auth/change-password",
        queryParameters: {
          "current_password": currentPassword,
          "new_password": newPassword,
        },
      );
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: "Falha ao alterar senha.");
    }
  }

  ApiResponse<dynamic> _parseResponse(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return ApiResponse<dynamic>.fromJson(raw);
    }
    throw const AppException("Resposta invalida do servidor.");
  }

  AppException _mapDioError(DioException e, {required String fallback}) {
    final errorData = e.response?.data;
    if (errorData is Map<String, dynamic>) {
      final detail = errorData["detail"];
      final message = errorData["message"];

      if (detail is String && detail.isNotEmpty) {
        return AppException(detail);
      }
      if (message is String && message.isNotEmpty) {
        return AppException(message);
      }
    }

    return AppException(fallback);
  }
}
