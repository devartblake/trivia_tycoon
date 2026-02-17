import 'package:hive/hive.dart';

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAtUtc; // optional if you refresh on 401
  final String? userId;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAtUtc,
    this.userId,
  });

  bool get hasTokens => accessToken.isNotEmpty && refreshToken.isNotEmpty;
}

class AuthTokenStore {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kExpiresAt = 'auth_expires_at_utc';
  static const _kUserId = 'auth_user_id';

  final Box _box;
  AuthTokenStore(this._box);

  AuthSession load() {
    final access = _box.get(_kAccess) ?? '';
    final refresh = _box.get(_kRefresh) ?? '';
    final expiresMs = _box.get(_kExpiresAt);
    final userId = _box.get(_kUserId);

    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      expiresAtUtc: expiresMs == null ? null : DateTime.fromMillisecondsSinceEpoch(expiresMs, isUtc: true),
      userId: userId?.isEmpty == true ? null : userId,
    );
  }

  Future<void> save(AuthSession session) async {
    await _box.put(_kAccess, session.accessToken);
    await _box.put(_kRefresh, session.refreshToken);
    if (session.userId != null) {
      await _box.put(_kUserId, session.userId!);
    }
    if (session.expiresAtUtc != null) {
      await _box.put(_kExpiresAt, session.expiresAtUtc!.millisecondsSinceEpoch);
    } else {
      await _box.delete(_kExpiresAt);
    }
  }

  Future<void> clear() async {
    await _box.delete(_kAccess);
    await _box.delete(_kRefresh);
    await _box.delete(_kExpiresAt);
    await _box.delete(_kUserId);
  }
}
