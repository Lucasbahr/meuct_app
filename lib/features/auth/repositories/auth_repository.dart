import '../services/auth_service.dart';
import '../../../core/storage/gym_context_storage.dart';
import '../../../core/storage/token_storage.dart';
import '../../marketplace/marketplace_cart_store.dart';

class AuthRepository {
  final AuthService _service;
  final TokenStorage _storage;

  AuthRepository({
    AuthService? service,
    TokenStorage? storage,
  })  : _service = service ?? AuthService(),
        _storage = storage ?? TokenStorage();

  Future<void> login(String email, String password) async {
    final token = await _service.login(email, password);
    await _storage.saveToken(token);
    await GymContextStorage.instance.syncFromAccessToken(token);
  }

  Future<void> logout() async {
    MarketplaceCartStore.clear();
    await GymContextStorage.instance.clear();
    await _storage.clearToken();
  }

  Future<void> register(
    String email,
    String password, {
    int? gymId,
  }) async {
    await _service.register(email, password, gymId: gymId);
  }

  Future<void> resendVerification(String email) async {
    await _service.resendVerification(email);
  }

  Future<void> forgotPassword(String email) async {
    await _service.forgotPassword(email);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _service.resetPassword(token: token, newPassword: newPassword);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _service.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
