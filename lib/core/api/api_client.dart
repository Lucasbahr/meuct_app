import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../storage/gym_context_storage.dart';
import '../storage/token_storage.dart';

/// Renova access com refresh, sem passar pelo interceptor (evita loop em 401).
Future<String?> _trySilentRefreshAccess() async {
  final storage = TokenStorage();
  final refresh = await storage.getRefreshToken();
  if (refresh == null || refresh.isEmpty) return null;

  final d = Dio(
    BaseOptions(
      baseUrl: ApiClient.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {
        "Content-Type": "application/json",
      },
    ),
  );
  try {
    final response = await d.post(
      "/auth/refresh",
      queryParameters: {"refresh_token": refresh},
    );
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final apiResponse = ApiResponse<dynamic>.fromJson(raw);
      final data = apiResponse.data;
      if (data is Map<String, dynamic>) {
        final token = data["access_token"];
        if (token is String && token.isNotEmpty) {
          await storage.saveTokens(access: token, refresh: refresh);
          return token;
        }
      }
    }
  } catch (_) {}
  return null;
}

class ApiClient {
  /// Build: opcional `--dart-define=API_BASE_URL=https://seu-host` (CI / produção).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://meuct-api-hml-301033312521.us-central1.run.app',
  );
  final Dio dio;

  ApiClient()
      : dio = Dio(BaseOptions(
          baseUrl: ApiClient.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            "Content-Type": "application/json",
          },
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage().getToken();

          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
            if (await GymContextStorage.instance.getGymId() == null) {
              await GymContextStorage.instance.syncFromAccessToken(token);
            }
          }

          final gymId = await GymContextStorage.instance.getGymId();
          if (gymId != null) {
            options.headers["X-Gym-Id"] = gymId.toString();
          }

          handler.next(options);
        },
        onError: (err, handler) async {
          if (err.response?.statusCode == 401) {
            final opt = err.requestOptions;
            final path = opt.path;

            if (path == "/auth/login" ||
                path == "/auth/register" ||
                path == "/auth/refresh" ||
                path == "/auth/logout" ||
                opt.extra["skipAuthRefresh"] == true) {
              await TokenStorage().clearToken();
              await GymContextStorage.instance.clear();
              return handler.next(err);
            }

            if (opt.extra["_authRetry"] == true) {
              await TokenStorage().clearToken();
              await GymContextStorage.instance.clear();
              return handler.next(err);
            }

            final newAccess = await _trySilentRefreshAccess();
            if (newAccess != null && newAccess.isNotEmpty) {
              await GymContextStorage.instance.syncFromAccessToken(newAccess);
              opt.headers["Authorization"] = "Bearer $newAccess";
              opt.extra["_authRetry"] = true;
              try {
                final clone = await dio.fetch(opt);
                return handler.resolve(clone);
              } catch (_) {
                await TokenStorage().clearToken();
                await GymContextStorage.instance.clear();
                return handler.next(err);
              }
            }

            await TokenStorage().clearToken();
            await GymContextStorage.instance.clear();
          }
          handler.next(err);
        },
      ),
    );
  }
}
