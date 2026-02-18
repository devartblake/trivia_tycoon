import 'auth_api_client.dart';
import 'auth_token_store.dart';
import 'device_id_service.dart';

class AuthService {
  final DeviceIdService _deviceId;
  final AuthTokenStore _store;
  final AuthApiClient _api;

  AuthService({
    required DeviceIdService deviceId,
    required AuthTokenStore tokenStore,
    required AuthApiClient api,
  })  : _deviceId = deviceId,
        _store = tokenStore,
        _api = api;

  AuthSession get currentSession => _store.load();

  Future<String> ensureDeviceId() => _deviceId.getOrCreate();

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await _deviceId.getOrCreate();
    final session = await _api.login(email: email, password: password, deviceId: deviceId);
    await _store.save(session);
    return session;
  }

  Future<AuthSession> refresh() async {
    final deviceId = await _deviceId.getOrCreate();
    final existing = _store.load();
    if (existing.refreshToken.isEmpty) {
      throw Exception('No refresh token present.');
    }

    final session = await _api.refresh(refreshToken: existing.refreshToken, deviceId: deviceId);
    await _store.save(session);
    return session;
  }

  Future<void> logout() async {
    final deviceId = await _deviceId.getOrCreate();
    final existing = _store.load();

    try {
      await _api.logout(
        deviceId: deviceId,
        userId: existing.userId,
        accessToken: existing.accessToken,
      );
    } finally {
      await _store.clear();
    }
  }

  /// Handy for API calls; returns empty string if not logged in.
  String get accessToken => _store.load().accessToken;
}
