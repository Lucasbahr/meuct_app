import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste o tenant (`gym_id`) para o header `X-Gym-Id`, alinhado à API
/// (`app/core/tenant.py`). Sincronizado a partir do JWT no login.
class GymContextStorage {
  GymContextStorage._();
  static final GymContextStorage instance = GymContextStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _key = "gym_context_id";

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (e, st) {
      debugPrint('GymContextStorage.clear failed: $e\n$st');
    }
  }

  Future<int?> getGymId() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      return int.tryParse(raw);
    } catch (e, st) {
      debugPrint('GymContextStorage.getGymId failed: $e\n$st');
      return null;
    }
  }

  Future<void> setGymId(int? id) async {
    try {
      if (id == null) {
        await clear();
        return;
      }
      await _storage.write(key: _key, value: id.toString());
    } catch (e, st) {
      debugPrint('GymContextStorage.setGymId failed: $e\n$st');
    }
  }

  /// Extrai `gym_id` do access token e grava (ou limpa se ausente).
  Future<void> syncFromAccessToken(String token) async {
    final parts = token.split(".");
    if (parts.length < 2) {
      await clear();
      return;
    }
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payload);
      if (map is! Map<String, dynamic>) {
        await clear();
        return;
      }
      int? parse(dynamic v) {
        if (v is int) return v;
        if (v is String) return int.tryParse(v);
        return null;
      }

      final gid = parse(map["gym_id"]);
      await setGymId(gid);
    } catch (e, st) {
      debugPrint('GymContextStorage.syncFromAccessToken failed: $e\n$st');
    }
  }
}
