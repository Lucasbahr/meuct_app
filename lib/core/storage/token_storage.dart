import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: "token", value: token);
    } catch (e, st) {
      debugPrint('TokenStorage.saveToken failed: $e\n$st');
      rethrow;
    }
  }

  /// Em release, falha de keystore/backup Android aqui quebrava o interceptor do Dio.
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: "token");
    } catch (e, st) {
      debugPrint('TokenStorage.getToken failed: $e\n$st');
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: "token");
    } catch (e, st) {
      debugPrint('TokenStorage.clearToken failed: $e\n$st');
    }
  }
}
