import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../../../core/api/api_client.dart';

class StudentService {
  final Dio dio = ApiClient().dio;

  Future<Map<String, dynamic>> getMe() async {
    final response = await dio.get("/students/me");
    return response.data["data"];
  }

  /// Lista alunos (admin). Retorna vazio se não autorizado — usado para exibir nomes em comentários.
  Future<List<Map<String, dynamic>>> listStudentsForNameLookup() async {
    try {
      final response = await dio.get("/students/");
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is List) {
        return (data["data"] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(String filePath) async {
    final fileName = filePath.split("\\").last;
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await dio.post(
      "/students/me/photo",
      data: formData,
    );

    return response.data["data"] as Map<String, dynamic>;
  }

  Future<Uint8List?> getMyProfilePhotoBytes() async {
    try {
      final response = await dio.get<List<int>>(
        "/students/me/photo",
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      return Uint8List.fromList(bytes);
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateMyProfile({
    String? nome,
    String? telefone,
    String? endereco,
    String? dataNascimento,
  }) async {
    final payload = <String, dynamic>{};
    if (nome != null) payload["nome"] = nome;
    if (telefone != null) payload["telefone"] = telefone;
    if (endereco != null) payload["endereco"] = endereco;
    if (dataNascimento != null) payload["data_nascimento"] = dataNascimento;

    final response = await dio.put(
      "/students/me",
      data: payload,
    );
    return response.data["data"] as Map<String, dynamic>;
  }
}
