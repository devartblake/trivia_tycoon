import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_tokens.dart';

class TokenStore {
  static const _kAccess = 'auth.access_token';
  static const _kRefresh = 'auth.refresh_token';
  static const _kExpiresAt = 'auth.expires_at_utc';

  final FlutterSecureStorage _storage;

  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    if (access == null || refresh == null) return null;

    final expiresRaw = await _storage.read(key: _kExpiresAt);
    final expiresAt = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

    return AuthTokens(accessToken: access, refreshToken: refresh, expiresAtUtc: expiresAt);
  }

  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
    if (tokens.expiresAtUtc != null) {
      await _storage.write(key: _kExpiresAt, value: tokens.expiresAtUtc!.toIso8601String());
    } else {
      await _storage.delete(key: _kExpiresAt);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kExpiresAt);
  }
}
