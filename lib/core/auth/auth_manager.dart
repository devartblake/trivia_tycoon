import 'dart:async';
import 'package:flutter/foundation.dart';
import 'auth_api.dart';
import 'auth_tokens.dart';
import 'token_store.dart';

class AuthManager {
  final AuthApi _api;
  final TokenStore _store;

  AuthTokens? _cached;
  Future<AuthTokens>? _refreshInFlight;

  AuthManager({
    required AuthApi api,
    required TokenStore store,
  })  : _api = api,
        _store = store;

  Future<void> init() async {
    _cached = await _store.read();
  }

  AuthTokens? get tokens => _cached;

  bool get isLoggedIn => _cached != null;

  Future<void> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    final t = await _api.login(email: email, password: password, deviceId: deviceId);
    _cached = t;
    await _store.write(t);
  }

  Future<void> logout({required String deviceId}) async {
    final t = _cached;
    _cached = null;
    await _store.clear();

    if (t != null) {
      try {
        await _api.logout(accessToken: t.accessToken, deviceId: deviceId);
      } catch (e) {
        debugPrint('Logout API failed (ignored): $e');
      }
    }
  }

  /// Returns a valid access token, refreshing if needed.
  Future<String?> getValidAccessToken() async {
    final t = _cached;
    if (t == null) return null;

    if (!t.isExpired) return t.accessToken;

    final refreshed = await _refreshTokens();
    return refreshed.accessToken;
  }

  /// Force refresh (used on 401)
  Future<AuthTokens> refreshNow() => _refreshTokens(force: true);

  Future<AuthTokens> _refreshTokens({bool force = false}) {
    final t = _cached;
    if (t == null) {
      return Future.error(StateError('No tokens to refresh'));
    }

    if (!force && !t.isExpired) {
      return Future.value(t);
    }

    // lock refresh so multiple calls share one refresh request
    final inflight = _refreshInFlight;
    if (inflight != null) return inflight;

    _refreshInFlight = _api.refresh(refreshToken: t.refreshToken).then((newTokens) async {
      _cached = newTokens;
      await _store.write(newTokens);
      return newTokens;
    }).whenComplete(() {
      _refreshInFlight = null;
    });

    return _refreshInFlight!;
  }
}
