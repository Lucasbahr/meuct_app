import 'package:dio/dio.dart';
import '../storage/gym_context_storage.dart';
import '../storage/token_storage.dart';

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
            await TokenStorage().clearToken();
            await GymContextStorage.instance.clear();
          }
          handler.next(err);
        },
      ),
    );
  }
}
