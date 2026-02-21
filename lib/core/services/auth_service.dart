import 'package:flutter/foundation.dart';
import 'auth_api_client.dart';
import 'auth_token_store.dart';
import 'device_id_service.dart';

/// Core authentication service that manages tokens and communicates with backend.
class AuthService {
  final DeviceIdService _deviceId;
  final AuthTokenStore _store;
  final AuthApiClient _api;

  /// Exposes token storage for callers that still rely on direct access.
  AuthTokenStore get tokenStore => _store;

  AuthService({
    required DeviceIdService deviceId,
    required AuthTokenStore tokenStore,
    required AuthApiClient api,
  })  : _deviceId = deviceId,
        _store = tokenStore,
        _api = api;

  /// Get current session from storage
  AuthSession get currentSession => _store.load();

  /// ensure device ID exists
  Future<String> ensureDeviceId() => _deviceId.getOrCreate();

  /// Login with email and password
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    // AuthApiClient gets device ID internally, don't pass it
    final session = await _api.login(
      email: email,
      password: password,
    );
    await _store.save(session);
    return session;
  }

  /// Signup (register + auto-login)
  /// Calls the /auth/signup endpoint which creates account and returns tokens
  Future<AuthSession> signup({
    required String email,
    required String password,
    String? username,
    String? country,
  }) async {
    // AuthApiClient gets device ID internally, don't pass it
    final session = await _api.signup(
      email: email,
      password: password,
      username: username,
      country: country,
    );
    await _store.save(session);
    return session;
  }

  /// Refresh access token using refresh token
  Future<AuthSession> refresh() async {
    final deviceId = await _deviceId.getOrCreate();
    final existing = _store.load();

    if (existing.refreshToken.isEmpty) {
      throw Exception('No refresh token present.');
    }

    final session = await _api.refresh(
      refreshToken: existing.refreshToken,
      deviceId: deviceId,
    );
    await _store.save(session);
    return session;
  }

  /// Logout and revoke refresh token
  Future<void> logout() async {
    final deviceId = await _deviceId.getOrCreate();
    final existing = _store.load();

    try {
      // Call backend logout to revoke token.
      // Some backends may return 401 for expired/rotated tokens; treat that as best-effort.
      await _api.logout(
        deviceId: deviceId,
        userId: existing.userId,
        accessToken: existing.accessToken,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] Logout request failed, proceeding with local clear: $e');
      }
    } finally {
      // Always clear local tokens, even if backend call fails
      await _store.clear();
    }
  }

  /// Get access token for API calls (returns empty if not logged in)
  String get accessToken => _store.load().accessToken;

  /// Check if user is logged in (has valid tokens)
  bool get isLoggedIn {
    final session = _store.load();
    return session.hasTokens;
  }
}
