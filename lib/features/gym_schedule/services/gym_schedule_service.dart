import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class GymScheduleService {
  final Dio dio = ApiClient().dio;

  static Map<String, dynamic> _asStringKeyedMap(dynamic m) {
    if (m is Map<String, dynamic>) return Map<String, dynamic>.from(m);
    if (m is Map) {
      return m.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  static List<Map<String, dynamic>> _coerceMapList(dynamic raw) {
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(Map<String, dynamic>.from(e));
      } else if (e is Map) {
        out.add(_asStringKeyedMap(e));
      }
    }
    return out;
  }

  /// Aceita vários formatos de envelope JSON (lista direta, `data: []`, `data: { items: [] }`, etc.).
  static List<Map<String, dynamic>> parseFlexibleDataList(dynamic body) {
    if (body == null) return [];
    if (body is List) return _coerceMapList(body);

    final root = _asStringKeyedMap(body);

    for (final k in [
      'data',
      'modalidades',
      'modalities',
      'items',
      'results',
      'rows',
      'records',
      'list',
    ]) {
      final v = root[k];
      if (v is List) {
        final list = _coerceMapList(v);
        if (list.isNotEmpty) return list;
      }
    }

    final data = root['data'];
    if (data is Map) {
      final dm = _asStringKeyedMap(data);
      for (final k in [
        'modalidades',
        'modalities',
        'items',
        'results',
        'rows',
        'records',
        'list',
        'data',
      ]) {
        final v = dm[k];
        if (v is List) {
          final list = _coerceMapList(v);
          if (list.isNotEmpty) return list;
        }
      }
    }

    return [];
  }

  static List<Map<String, dynamic>> _parseDataList(dynamic body) {
    final flex = parseFlexibleDataList(body);
    if (flex.isNotEmpty) return flex;
    if (body is Map<String, dynamic> && body["data"] is List) {
      return (body["data"] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  String _dioDetail(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final d = data["detail"];
      final m = data["message"];
      if (d is String && d.isNotEmpty) return d;
      if (m is String && m.isNotEmpty) return m;
    }
    return e.message ?? "Falha na requisição.";
  }

  Future<List<Map<String, dynamic>>> listGymClasses({
    bool activeOnly = true,
  }) async {
    try {
      final response = await dio.get(
        "/gym-classes",
        queryParameters: {"active_only": activeOnly},
      );
      return _parseDataList(response.data);
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  Future<List<Map<String, dynamic>>> listScheduleGrouped({
    bool activeOnly = true,
  }) async {
    try {
      final response = await dio.get(
        "/gym-schedule",
        queryParameters: {
          "active_only": activeOnly,
          "grouped": true,
        },
      );
      return _parseDataList(response.data);
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  Future<Map<String, dynamic>> createGymClass({
    required String name,
    String? description,
    int? modalityId,
    String? instructorName,
    int? durationMinutes,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    try {
      final response = await dio.post(
        "/gym-classes",
        data: {
          "name": name,
          if (description != null && description.isNotEmpty)
            "description": description,
          if (modalityId != null) "modality_id": modalityId,
          if (instructorName != null && instructorName.isNotEmpty)
            "instructor_name": instructorName,
          if (durationMinutes != null) "duration_minutes": durationMinutes,
          "sort_order": sortOrder,
          "is_active": isActive,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      throw Exception("Resposta inválida.");
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  Future<Map<String, dynamic>> updateGymClass(
    int id, {
    String? name,
    String? description,
    int? modalityId,
    String? instructorName,
    int? durationMinutes,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      final patch = <String, dynamic>{};
      if (name != null) patch["name"] = name;
      if (description != null) patch["description"] = description;
      if (modalityId != null) patch["modality_id"] = modalityId;
      if (instructorName != null) patch["instructor_name"] = instructorName;
      if (durationMinutes != null) patch["duration_minutes"] = durationMinutes;
      if (sortOrder != null) patch["sort_order"] = sortOrder;
      if (isActive != null) patch["is_active"] = isActive;

      final response = await dio.patch("/gym-classes/$id", data: patch);
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      throw Exception("Resposta inválida.");
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  Future<void> deleteGymClass(int id) async {
    try {
      await dio.delete("/gym-classes/$id");
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  Future<Map<String, dynamic>> createScheduleSlot({
    required int gymClassId,
    required int weekday,
    required String startTimeHms,
    required String endTimeHms,
    String? room,
    String? notes,
    bool isActive = true,
  }) async {
    try {
      final response = await dio.post(
        "/gym-schedule/slots",
        data: {
          "gym_class_id": gymClassId,
          "weekday": weekday,
          "start_time": startTimeHms,
          "end_time": endTimeHms,
          if (room != null && room.isNotEmpty) "room": room,
          if (notes != null && notes.isNotEmpty) "notes": notes,
          "is_active": isActive,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      throw Exception("Resposta inválida.");
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  Future<Map<String, dynamic>> updateScheduleSlot(
    int slotId, {
    int? gymClassId,
    int? weekday,
    String? startTimeHms,
    String? endTimeHms,
    String? room,
    String? notes,
    bool? isActive,
  }) async {
    try {
      final patch = <String, dynamic>{};
      if (gymClassId != null) patch["gym_class_id"] = gymClassId;
      if (weekday != null) patch["weekday"] = weekday;
      if (startTimeHms != null) patch["start_time"] = startTimeHms;
      if (endTimeHms != null) patch["end_time"] = endTimeHms;
      if (room != null) patch["room"] = room;
      if (notes != null) patch["notes"] = notes;
      if (isActive != null) patch["is_active"] = isActive;

      final response =
          await dio.patch("/gym-schedule/slots/$slotId", data: patch);
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      throw Exception("Resposta inválida.");
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  Future<void> deleteScheduleSlot(int slotId) async {
    try {
      await dio.delete("/gym-schedule/slots/$slotId");
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  /// Lista modalidades do tenant (para vínculo opcional na aula).
  /// Interpreta `GET /modalidades` em vários formatos de resposta.
  Future<List<Map<String, dynamic>>> listModalidades() async {
    try {
      final response = await dio.get("/modalidades");
      return parseFlexibleDataList(response.data);
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  /// Admin academia: nova modalidade de luta. `POST /modalidades`.
  /// Campos extras (horas, faixas) são opcionais — a API pode ignorar o que não suportar.
  Future<Map<String, dynamic>> createModality({
    required String nome,
    String? descricao,
    int? sortOrder,
    int? hoursForNextGraduation,
    List<Map<String, dynamic>>? graduationRoles,
  }) async {
    try {
      final body = <String, dynamic>{
        "nome": nome.trim(),
        if (descricao != null && descricao.trim().isNotEmpty)
          "descricao": descricao.trim(),
        if (sortOrder != null) "sort_order": sortOrder,
        if (hoursForNextGraduation != null && hoursForNextGraduation > 0)
          "hours_for_next_graduation": hoursForNextGraduation,
        if (graduationRoles != null && graduationRoles.isNotEmpty)
          "graduation_roles": graduationRoles,
      };
      final response = await dio.post("/modalidades", data: body);
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      throw Exception("Resposta inválida.");
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  /// Admin academia: atualiza modalidade e regras de graduação. `PATCH /modalidades/{id}`.
  /// [clearHoursForNextGraduation] envia `null` para limpar horas no servidor (se a API aceitar).
  Future<Map<String, dynamic>> updateModality(
    int id, {
    String? nome,
    String? descricao,
    int? sortOrder,
    int? hoursForNextGraduation,
    bool clearHoursForNextGraduation = false,
    List<Map<String, dynamic>>? graduationRoles,
  }) async {
    try {
      final patch = <String, dynamic>{};
      if (nome != null) patch["nome"] = nome.trim();
      if (descricao != null) patch["descricao"] = descricao.trim();
      if (sortOrder != null) patch["sort_order"] = sortOrder;
      if (clearHoursForNextGraduation) {
        patch["hours_for_next_graduation"] = null;
      } else if (hoursForNextGraduation != null) {
        patch["hours_for_next_graduation"] = hoursForNextGraduation;
      }
      if (graduationRoles != null) patch["graduation_roles"] = graduationRoles;

      final response = await dio.patch("/modalidades/$id", data: patch);
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      throw Exception("Resposta inválida.");
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  /// Remove modalidade do tenant. `DELETE /modalidades/{id}`.
  Future<void> deleteModality(int id) async {
    try {
      await dio.delete("/modalidades/$id");
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }
}
