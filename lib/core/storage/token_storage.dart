import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kAccess = "token";
  static const _kRefresh = "refresh_token";

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Persiste apenas o JWT de acesso (legado / testes).
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _kAccess, value: token);
    } catch (e, st) {
      debugPrint('TokenStorage.saveToken failed: $e\n$st');
      rethrow;
    }
  }

  /// Access + refresh conforme `/auth/login` da API.
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    try {
      await _storage.write(key: _kAccess, value: access);
      await _storage.write(key: _kRefresh, value: refresh);
    } catch (e, st) {
      debugPrint('TokenStorage.saveTokens failed: $e\n$st');
      rethrow;
    }
  }

  /// Em release, falha de keystore/backup Android aqui quebrava o interceptor do Dio.
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _kAccess);
    } catch (e, st) {
      debugPrint('TokenStorage.getToken failed: $e\n$st');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _kRefresh);
    } catch (e, st) {
      debugPrint('TokenStorage.getRefreshToken failed: $e\n$st');
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _kAccess);
      await _storage.delete(key: _kRefresh);
    } catch (e, st) {
      debugPrint('TokenStorage.clearToken failed: $e\n$st');
    }
  }
}
