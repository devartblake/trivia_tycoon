import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_tokens.dart';

class AuthApi {
  final String apiBaseUrl;
  final http.Client _http;

  // Adjust these if your backend routes differ
  final String loginPath;
  final String refreshPath;
  final String logoutPath;

  AuthApi({
    required this.apiBaseUrl,
    http.Client? httpClient,
    this.loginPath = '/auth/login',
    this.refreshPath = '/auth/refresh',
    this.logoutPath = '/auth/logout',
  }) : _http = httpClient ?? http.Client();

  Future<AuthTokens> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$loginPath');

    final resp = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'deviceId': deviceId,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('Login failed: ${resp.statusCode} ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;

    // ✅ Map backend fields here
    final access = (json['accessToken'] ?? json['access_token']) as String;
    final refresh = (json['refreshToken'] ?? json['refresh_token']) as String;

    DateTime? expiresAt;
    if (json['expiresAtUtc'] != null) {
      expiresAt = DateTime.tryParse(json['expiresAtUtc'].toString())?.toUtc();
    } else if (json['expiresAt'] != null) {
      expiresAt = DateTime.tryParse(json['expiresAt'].toString())?.toUtc();
    } else if (json['expiresIn'] != null) {
      final seconds = int.tryParse(json['expiresIn'].toString());
      if (seconds != null) expiresAt = DateTime.now().toUtc().add(Duration(seconds: seconds));
    }

    return AuthTokens(accessToken: access, refreshToken: refresh, expiresAtUtc: expiresAt);
  }

  Future<AuthTokens> refresh({
    required String refreshToken,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$refreshPath');

    final resp = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Refresh failed: ${resp.statusCode} ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final access = (json['accessToken'] ?? json['access_token']) as String;
    final refresh = (json['refreshToken'] ?? json['refresh_token']) as String;

    DateTime? expiresAt;
    if (json['expiresAtUtc'] != null) {
      expiresAt = DateTime.tryParse(json['expiresAtUtc'].toString())?.toUtc();
    } else if (json['expiresIn'] != null) {
      final seconds = int.tryParse(json['expiresIn'].toString());
      if (seconds != null) expiresAt = DateTime.now().toUtc().add(Duration(seconds: seconds));
    }

    return AuthTokens(accessToken: access, refreshToken: refresh, expiresAtUtc: expiresAt);
  }

  Future<void> logout({
    required String accessToken,
    required String deviceId,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$logoutPath');

    // logout may be optional on backend; safe to ignore errors if you want
    final resp = await _http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'deviceId': deviceId}),
    );

    if (resp.statusCode >= 400) {
      // don’t hard-fail logout; local clear still matters
      // throw Exception('Logout failed: ${resp.statusCode} ${resp.body}');
    }
  }
}
