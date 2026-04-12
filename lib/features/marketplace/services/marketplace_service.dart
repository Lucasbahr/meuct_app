import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';

class MarketplaceService {
  final Dio dio = ApiClient().dio;

  /// API devolve `images[].image_url` ou legado `image_urls`.
  static String? productPrimaryImageUrl(Map<String, dynamic> product) {
    final list = productImageUrlList(product);
    if (list.isEmpty) return null;
    return resolveImageUrl(list.first);
  }

  static List<String> productImageUrlList(Map<String, dynamic> product) {
    final out = <String>[];
    final imgs = product["images"];
    if (imgs is List) {
      for (final e in imgs) {
        if (e is Map && e["image_url"] != null) {
          out.add(e["image_url"].toString());
        }
      }
    }
    if (out.isEmpty) {
      final legacy = product["image_urls"];
      if (legacy is List) {
        for (final e in legacy) {
          out.add(e.toString());
        }
      }
    }
    return out;
  }

  static String? resolveImageUrl(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    if (raw.startsWith("http")) return raw;
    if (raw.startsWith("/")) return "${ApiClient.baseUrl}$raw";
    return "${ApiClient.baseUrl}/$raw";
  }

  Future<List<Map<String, dynamic>>> listProducts({
    int? categoryId,
    int? subcategoryId,
    String sort = "created_at",
    String order = "desc",
  }) async {
    try {
      final response = await dio.get(
        "/products",
        queryParameters: {
          if (categoryId != null) "category_id": categoryId,
          if (subcategoryId != null) "subcategory_id": subcategoryId,
          "sort": sort,
          "order": order,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is List) {
        return (data["data"] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao carregar produtos.");
    }
  }

  Future<Map<String, dynamic>> getProduct(int productId) async {
    try {
      final response = await dio.get("/products/$productId");
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao carregar produto.");
    }
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    String? description,
    required double price,
    required int stock,
    bool trackStock = true,
    bool isActive = true,
    int? categoryId,
    int? subcategoryId,
    List<String> imageUrls = const [],
  }) async {
    try {
      final response = await dio.post(
        "/products",
        data: {
          "name": name,
          if (description != null && description.isNotEmpty) "description": description,
          "price": price,
          "stock": stock,
          "track_stock": trackStock,
          "is_active": isActive,
          if (categoryId != null) "category_id": categoryId,
          if (subcategoryId != null) "subcategory_id": subcategoryId,
          "image_urls": imageUrls,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao criar produto.");
    }
  }

  Future<Map<String, dynamic>> updateProduct(
    int productId, {
    String? name,
    String? description,
    double? price,
    int? stock,
    bool? isActive,
    int? categoryId,
    int? subcategoryId,
    List<String>? imageUrls,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body["name"] = name;
      if (description != null) body["description"] = description;
      if (price != null) body["price"] = price;
      if (stock != null) body["stock"] = stock;
      if (isActive != null) body["is_active"] = isActive;
      if (categoryId != null) body["category_id"] = categoryId;
      if (subcategoryId != null) body["subcategory_id"] = subcategoryId;
      if (imageUrls != null) body["image_urls"] = imageUrls;

      final response = await dio.put("/products/$productId", data: body);
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao atualizar produto.");
    }
  }

  Future<Map<String, dynamic>> createCategory(String name) async {
    try {
      final response = await dio.post("/categories", data: {"name": name});
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao criar categoria.");
    }
  }

  Future<Map<String, dynamic>> createSubcategory({
    required int categoryId,
    required String name,
  }) async {
    try {
      final response = await dio.post(
        "/subcategories",
        data: {"category_id": categoryId, "name": name},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao criar subcategoria.");
    }
  }

  /// Extrai URL de autorização OAuth devolvida pela API (vários formatos / chaves).
  ///
  /// Aceita: string URL, mapa na raiz ou em `data`, chaves como [authorization_url],
  /// [oauth_url], [auth_url], [connect_url], [url], ou objeto aninhado.
  static String? mercadoPagoOAuthUrlFromResponse(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final s = raw.trim();
      if (s.startsWith('http://') || s.startsWith('https://')) return s;
      return null;
    }
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      const keys = <String>[
        'authorization_url',
        'oauth_url',
        'auth_url',
        'connect_url',
        'login_url',
        'redirect_to',
        'url',
      ];
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.trim().isNotEmpty) {
          final s = v.trim();
          if (s.startsWith('http://') || s.startsWith('https://')) return s;
        }
      }
      for (final nestKey in ['data', 'oauth', 'mercado_pago', 'payload']) {
        final nested = m[nestKey];
        if (nested != null && nested != raw) {
          final inner = mercadoPagoOAuthUrlFromResponse(nested);
          if (inner != null) return inner;
        }
      }
    }
    return null;
  }

  /// Lê status (sem expor segredos). `GET /payment/config`.
  Future<Map<String, dynamic>?> getPaymentConfig({
    String provider = "mercado_pago",
  }) async {
    try {
      final response = await dio.get(
        "/payment/config",
        queryParameters: {"provider": provider},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return null;
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao carregar configuração de pagamento.");
    }
  }

  /// Inicia OAuth Mercado Pago da **academia** (admin). Abre a URL no navegador / app do MP.
  ///
  /// `POST /payment/mercado-pago/oauth/start` com body opcional `next_url` (primeiro não vazio
  /// entre [nextUrl], [returnUrl], [redirectUri]). O callback da API é
  /// `/payment/mercado-pago/oauth/callback` (cadastrar no app MP + `MERCADOPAGO_OAUTH_REDIRECT_URI`).
  Future<String> startMercadoPagoOAuth({
    String? nextUrl,
    String? returnUrl,
    String? redirectUri,
  }) async {
    try {
      String? picked;
      for (final s in [nextUrl, returnUrl, redirectUri]) {
        final t = s?.trim();
        if (t != null && t.isNotEmpty) {
          picked = t;
          break;
        }
      }

      final body = <String, dynamic>{
        if (picked != null) 'next_url': picked,
      };
      final response = await dio.post(
        '/payment/mercado-pago/oauth/start',
        data: body.isEmpty ? {} : body,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw AppException(
            data['message']?.toString().trim().isNotEmpty == true
                ? data['message'].toString()
                : 'Não foi possível iniciar o vínculo.',
          );
        }
        final url = mercadoPagoOAuthUrlFromResponse(data);
        if (url != null) return url;
      } else if (data is String) {
        final url = mercadoPagoOAuthUrlFromResponse(data);
        if (url != null) return url;
      }
      throw const AppException('Resposta inválida ao iniciar OAuth (sem URL).');
    } on DioException catch (e) {
      throw _mapError(e, 'Falha ao iniciar vínculo Mercado Pago.');
    }
  }

  Future<Map<String, dynamic>> savePaymentConfig({
    required String provider,
    String? clientId,
    String? clientSecret,
    String? accessToken,
    String? refreshToken,
  }) async {
    try {
      final body = <String, dynamic>{"provider": provider};
      if (clientId != null && clientId.isNotEmpty) body["client_id"] = clientId;
      if (clientSecret != null && clientSecret.isNotEmpty) {
        body["client_secret"] = clientSecret;
      }
      if (accessToken != null && accessToken.isNotEmpty) {
        body["access_token"] = accessToken;
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        body["refresh_token"] = refreshToken;
      }

      final response = await dio.post("/payment/config", data: body);
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao salvar pagamento.");
    }
  }

  Future<Map<String, dynamic>> createOrder(
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await dio.post(
        "/orders",
        data: {"items": items},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao criar pedido.");
    }
  }

  /// Retorna corpo `data` da API; URL de redirecionamento varia por provedor.
  Future<Map<String, dynamic>> checkout(
    int orderId, {
    required String provider,
    required String returnUrl,
    required String cancelUrl,
  }) async {
    try {
      final response = await dio.post(
        "/orders/$orderId/checkout",
        data: {
          "provider": provider,
          "return_url": returnUrl,
          "cancel_url": cancelUrl,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data["data"] is Map) {
        return Map<String, dynamic>.from(data["data"] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw _mapError(e, "Falha ao iniciar checkout.");
    }
  }

  /// Extrai URL de pagamento quando a API devolve em campos conhecidos.
  static String? extractPaymentUrl(Map<String, dynamic> data) {
    for (final key in [
      "redirect_url",
      "approval_url",
      "checkout_url",
      "init_point",
      "sandbox_init_point",
      "url",
      "payment_url",
    ]) {
      final v = data[key];
      if (v is String &&
          v.isNotEmpty &&
          (v.startsWith("http://") || v.startsWith("https://"))) {
        return v;
      }
    }
    final links = data["links"];
    if (links is List) {
      for (final rel in ["payer-action", "approve"]) {
        for (final link in links) {
          if (link is Map &&
              link["rel"] == rel &&
              link["href"] is String) {
            final href = link["href"] as String;
            if (href.startsWith("http://") || href.startsWith("https://")) {
              return href;
            }
          }
        }
      }
      for (final link in links) {
        if (link is Map && link["href"] is String) {
          final href = link["href"] as String;
          if (href.startsWith("http://") || href.startsWith("https://")) {
            return href;
          }
        }
      }
    }
    return null;
  }

  static String formatPrice(dynamic price) {
    if (price == null) return "-";
    if (price is num) return price.toStringAsFixed(2);
    return price.toString();
  }

  AppException _mapError(DioException e, String fallback) {
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      final detail = body["detail"];
      final message = body["message"];
      if (detail is String && detail.isNotEmpty) return AppException(detail);
      if (message is String && message.isNotEmpty) return AppException(message);
    }
    return AppException(fallback);
  }
}
