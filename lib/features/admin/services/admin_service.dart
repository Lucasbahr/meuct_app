import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';

class AdminService {
  final Dio dio = ApiClient().dio;

  Future<List<Map<String, dynamic>>> getStudents() async {
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
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao carregar alunos.");
    }
  }

  Future<List<Map<String, dynamic>>> getRanking() async {
    try {
      final response = await dio.get("/checkin/ranking");
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is List) {
        return (data["data"] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao carregar ranking.");
    }
  }

  Future<List<Map<String, dynamic>>> getAthletes() async {
    final students = await getStudents();
    return students.where((s) => (s["e_atleta"] ?? false) == true).toList();
  }

  Future<Map<String, dynamic>> updateStudent(
    int studentId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await dio.put(
        "/students/$studentId",
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }

      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao atualizar aluno.");
    }
  }

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

  Future<Map<String, dynamic>> uploadStudentAthleteCardPhoto(
    int studentId,
    String filePath,
  ) async {
    final baseName = filePath.replaceAll("\\", "/").split("/").last;
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(filePath, filename: baseName),
    });
    try {
      final response = await dio.post(
        "/students/$studentId/athlete-card/photo",
        data: formData,
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao enviar foto do cartão do atleta.");
    }
  }

  /// Registra presença (check-in) em nome do aluno — apenas ADMIN (POST `/checkin/` com `student_id`).
  Future<void> checkInForStudent(int studentId) async {
    try {
      await dio.post("/checkin/", data: {"student_id": studentId});
    } on DioException catch (e) {
      final c = e.response?.statusCode;
      if (c == 403) {
        throw _mapError(
          e,
          "Apenas administradores podem registrar presença para outro aluno.",
        );
      }
      if (c == 404) {
        throw _mapError(e, "Aluno não encontrado.");
      }
      if (c == 400) {
        throw _mapError(
          e,
          "Check-in já realizado hoje para este aluno.",
        );
      }
      throw _mapError(e, "Falha ao registrar check-in do aluno.");
    }
  }

  Future<void> deleteStudent(int studentId) async {
    try {
      await dio.delete("/students/$studentId");
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao excluir aluno.");
    }
  }

  Future<void> setUserRoleByEmail({
    required String email,
    required String role,
  }) async {
    try {
      await dio.put(
        "/admin/users/role",
        data: {
          "email": email,
          "role": role,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao atualizar role do usuário.");
    }
  }

  AppException _mapError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data["detail"];
      final message = data["message"];
      if (detail is String && detail.isNotEmpty) return AppException(detail);
      if (message is String && message.isNotEmpty) return AppException(message);
    }
    return AppException(fallback);
  }
}
