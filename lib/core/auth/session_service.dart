import 'dart:convert';
import '../storage/token_storage.dart';

class SessionService {
  final TokenStorage _tokenStorage = TokenStorage();

  Future<String?> getUserRole() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return null;

    final parts = token.split(".");
    if (parts.length < 2) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payload);
      if (map is Map<String, dynamic>) {
        final role = map["role"];
        if (role is String && role.isNotEmpty) {
          return role;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role?.toUpperCase() == "ADMIN";
  }

  /// Identificador do usuário no token (ex.: JWT `sub` / `user_id`), quando presente.
  Future<int?> getTokenUserId() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return null;

    final parts = token.split(".");
    if (parts.length < 2) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payload);
      if (map is! Map<String, dynamic>) return null;

      int? parse(dynamic v) {
        if (v is int) return v;
        if (v is String) return int.tryParse(v);
        return null;
      }

      for (final key in ['user_id', 'sub', 'uid', 'id']) {
        final n = parse(map[key]);
        if (n != null) return n;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
