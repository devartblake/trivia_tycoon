import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_token_store.dart';

/// API client for authentication endpoints
class AuthApiClient {
  final http.Client _http;
  final String _apiBaseUrl;

  AuthApiClient(this._http, {required String apiBaseUrl})
      : _apiBaseUrl = apiBaseUrl.endsWith('/')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
      : apiBaseUrl;

  Uri _u(String path) => Uri.parse('$_apiBaseUrl$path');

  /// Adjust these paths to match your backend:
  static const String loginPath = '/auth/login';
  static const String signupPath = '/auth/signup';
  static const String refreshPath = '/auth/refresh';
  static const String logoutPath = '/auth/logout';

  Future<AuthSession> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    final res = await _http.post(
      _u(loginPath),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'deviceId': deviceId,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Login failed: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return _parseSession(json);
  }

  /// Signup endpoint (register + auto-login)
  Future<AuthSession> signup({
    required String email,
    required String password,
    required String deviceId,
    String? username,
    String? country,
  }) async {
    final res = await _http.post(
      _u(signupPath),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'deviceId': deviceId,
        if (username != null) 'username': username,
        if (country != null) 'country': country,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      // Parse error message if available
      try {
        final errorJson = jsonDecode(res.body) as Map<String, dynamic>;
        final errorMsg = errorJson['error'] ?? errorJson['message'] ?? res.body;
        throw Exception('Signup failed: $errorMsg');
      } catch (_) {
        throw Exception('Signup failed: ${res.statusCode} ${res.body}');
      }
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return _parseSession(json);
  }

  Future<AuthSession> refresh({
    required String refreshToken,
    required String deviceId,
  }) async {
    final res = await _http.post(
      _u(refreshPath),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refreshToken': refreshToken,
        'deviceId': deviceId,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Refresh failed: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return _parseSession(json);
  }

  Future<void> logout({
    required String deviceId,
    String? userId,
    String? accessToken,
  }) async {
    // Backend contract varies. This version supports either:
    // - Bearer access token + deviceId in body
    // - deviceId only
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final res = await _http.post(
      _u(logoutPath),
      headers: headers,
      body: jsonEncode({
        'deviceId': deviceId,
        if (userId != null) 'userId': userId,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Logout failed: ${res.statusCode} ${res.body}');
    }
  }

  AuthSession _parseSession(Map<String, dynamic> json) {
    // Try common shapes:
    // { accessToken, refreshToken, expiresAtUtc, userId }
    // { access_token, refresh_token, expires_at, user_id }
    final access = (json['accessToken'] ?? json['access_token'] ?? '') as String;
    final refresh = (json['refreshToken'] ?? json['refresh_token'] ?? '') as String;

    final userId = (json['userId'] ?? json['user_id']) as String?;

    // Parse expiration
    DateTime? expiresAtUtc;

    // Backend returns expiresIn (seconds)
    final expiresIn = json['expiresIn'];
    if (expiresIn is int) {
      expiresAtUtc = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
    }

    // Or expiresAtUtc as ISO string
    final expiresRaw = json['expiresAtUtc'] ?? json['expires_at'] ?? json['expiresAt'];
    if (expiresRaw is String && expiresRaw.isNotEmpty) {
      expiresAtUtc = DateTime.tryParse(expiresRaw)?.toUtc();
    } else if (expiresRaw is int) {
      // If backend returns epoch seconds or ms, adapt here if needed.
      // Assuming ms:
      expiresAtUtc = DateTime.fromMillisecondsSinceEpoch(expiresRaw, isUtc: true);
    }

    if (access.isEmpty || refresh.isEmpty) {
      throw Exception('Invalid auth payload: missing access/refresh token');
    }

    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      expiresAtUtc: expiresAtUtc,
      userId: userId,
    );
  }
}
