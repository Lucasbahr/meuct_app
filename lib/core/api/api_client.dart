import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static const String baseUrl =
      "https://meuct-api-hml-301033312521.us-central1.run.app";
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
          }

          handler.next(options);
        },
        onError: (err, handler) async {
          if (err.response?.statusCode == 401) {
            await TokenStorage().clearToken();
          }
          handler.next(err);
        },
      ),
    );
  }
}
