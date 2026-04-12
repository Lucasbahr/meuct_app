import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class TenantService {
  final Dio dio = ApiClient().dio;

  static Map<String, dynamic> _parseDataMap(dynamic body) {
    if (body is Map<String, dynamic> && body["data"] is Map) {
      return Map<String, dynamic>.from(body["data"] as Map);
    }
    return {};
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

  /// Config agregada (tenant, flags, modalidades, etc.).
  Future<Map<String, dynamic>> getTenantConfig() async {
    try {
      final response = await dio.get("/tenant/config");
      final m = _parseDataMap(response.data);
      if (m.isEmpty) {
        throw Exception("Resposta inválida do servidor.");
      }
      return m;
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  /// Admin sistema: cria nova academia (tenant). `POST /tenants`.
  Future<Map<String, dynamic>> createTenant({
    required String nome,
    String? slug,
    String? corPrimaria,
    String? corSecundaria,
    String? corBackground,
    String? logoUrl,
  }) async {
    final body = <String, dynamic>{"nome": nome.trim()};
    final s = slug?.trim();
    if (s != null && s.isNotEmpty) body["slug"] = s;
    if (corPrimaria != null && corPrimaria.trim().isNotEmpty) {
      body["cor_primaria"] = corPrimaria.trim();
    }
    if (corSecundaria != null && corSecundaria.trim().isNotEmpty) {
      body["cor_secundaria"] = corSecundaria.trim();
    }
    if (corBackground != null && corBackground.trim().isNotEmpty) {
      body["cor_background"] = corBackground.trim();
    }
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      body["logo_url"] = logoUrl.trim();
    }
    try {
      final response = await dio.post("/tenants", data: body);
      final data = response.data;
      if (data is Map<String, dynamic> && data["success"] == false) {
        throw Exception(
          data["message"]?.toString() ?? "Não foi possível criar a academia.",
        );
      }
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      throw Exception("Resposta inválida.");
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }

  /// Admin academia: atualiza texto público, cores e logo.
  Future<Map<String, dynamic>> patchTenantBranding({
    required String publicDescription,
    String? corPrimaria,
    String? corSecundaria,
    String? corBackground,
    String? logoUrl,
  }) async {
    final body = <String, dynamic>{
      "public_description": publicDescription,
    };
    if (corPrimaria != null) body["cor_primaria"] = corPrimaria;
    if (corSecundaria != null) body["cor_secundaria"] = corSecundaria;
    if (corBackground != null) body["cor_background"] = corBackground;
    if (logoUrl != null) body["logo_url"] = logoUrl;

    try {
      final response = await dio.patch("/tenant/branding", data: body);
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      throw Exception("Resposta inválida.");
    } on DioException catch (e) {
      throw Exception(_dioDetail(e));
    }
  }
}
