import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../../../core/api/api_client.dart';

class StudentService {
  final Dio dio = ApiClient().dio;

  Future<Map<String, dynamic>> getMe() async {
    final response = await dio.get("/students/me");
    return response.data["data"];
  }

  static List<Map<String, dynamic>> _parseDataList(dynamic responseBody) {
    if (responseBody is Map<String, dynamic> && responseBody["data"] is List) {
      return (responseBody["data"] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  static String _dioDetail(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final d = data["detail"];
      final m = data["message"];
      if (d is String && d.isNotEmpty) return d;
      if (m is String && m.isNotEmpty) return m;
    }
    return e.message ?? "Falha na requisição.";
  }

  /// Atletas para a aba pública: tenta `GET /students/athletes`, senão `GET /students/` + `e_atleta`.
  Future<List<Map<String, dynamic>>> listAthletes() async {
    try {
      final response = await dio.get("/students/athletes");
      return _parseDataList(response.data);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code != 404 && code != 403) {
        throw Exception(_dioDetail(e));
      }
    }

    try {
      final response = await dio.get("/students/");
      final list = _parseDataList(response.data);
      return list
          .where((s) => (s["e_atleta"] ?? false) == true)
          .toList();
    } on DioException catch (e) {
      throw Exception(
        "${_dioDetail(e)} "
        "Peça ao administrador para liberar a lista de atletas para alunos.",
      );
    }
  }

  /// Foto do aluno (mesmo endpoint do admin; falha silenciosa se não autorizado).
  Future<Uint8List?> getStudentPhotoBytes(int studentId) async {
    try {
      final response = await dio.get<List<int>>(
        "/students/$studentId/photo",
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      return Uint8List.fromList(bytes);
    } on DioException {
      return null;
    }
  }

  /// Foto só do cartão na aba Atletas (admin envia na API). 404 → null.
  Future<Uint8List?> getStudentAthleteCardPhotoBytes(int studentId) async {
    try {
      final response = await dio.get<List<int>>(
        "/students/$studentId/athlete-card/photo",
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      return Uint8List.fromList(bytes);
    } on DioException {
      return null;
    }
  }

  /// Cartão: prioriza foto do atleta; senão foto de perfil.
  Future<Uint8List?> getAthleteCardOrProfilePhotoBytes(int studentId) async {
    final card = await getStudentAthleteCardPhotoBytes(studentId);
    if (card != null && card.isNotEmpty) return card;
    return getStudentPhotoBytes(studentId);
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
