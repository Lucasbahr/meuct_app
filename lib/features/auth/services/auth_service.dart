import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/api_response.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/dio_unauthorized.dart';
import '../models/auth_tokens.dart';

class AuthService {
  final Dio dio = ApiClient().dio;

  static Dio _bareDio() => Dio(
        BaseOptions(
          baseUrl: ApiClient.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          headers: const {
            "Content-Type": "application/json",
          },
        ),
      );

  Future<AuthTokens> login(String email, String password) async {
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
        final access = data["access_token"];
        final refresh = data["refresh_token"];
        if (access is String &&
            access.isNotEmpty &&
            refresh is String &&
            refresh.isNotEmpty) {
          return AuthTokens(access: access, refresh: refresh);
        }
      }

      throw const AppException(
        "Token de acesso nao encontrado na resposta do login.",
      );
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: "Falha ao autenticar no servidor.");
    }
  }

  /// Revoga refresh no servidor (`/auth/logout`); falhas são ignoradas.
  Future<void> logoutRemote(String refreshToken) async {
    try {
      await _bareDio().post(
        "/auth/logout",
        queryParameters: {"refresh_token": refreshToken},
      );
    } on DioException {
      // melhor esforço
    }
  }

  Future<void> register(
    String email,
    String password, {
    int? gymId,
    String? registrationSecret,
  }) async {
    try {
      final body = <String, dynamic>{
        "email": email,
        "password": password,
      };
      if (gymId != null) {
        body["gym_id"] = gymId;
      }
      final secret = registrationSecret?.trim();
      if (secret != null && secret.isNotEmpty) {
        body["registration_secret"] = secret;
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
    return AppException(dioErrorUserMessage(e, fallback: fallback));
  }
}
