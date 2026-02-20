import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_token_store.dart';
import 'device_id_service.dart';

/// API client for authentication endpoints
class AuthApiClient {
  final http.Client _http;
  final String _apiBaseUrl;
  final DeviceIdService _deviceId;

  AuthApiClient(this._http, {required String apiBaseUrl, required DeviceIdService deviceId})
      : _apiBaseUrl = apiBaseUrl.endsWith('/')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
      : apiBaseUrl,
        _deviceId = deviceId;

  Uri _u(String path) => Uri.parse('$_apiBaseUrl$path');

  /// Adjust these paths to match your backend:
  static const String loginPath = '/auth/login';
  static const String signupPath = '/auth/signup';
  static const String refreshPath = '/auth/refresh';
  static const String logoutPath = '/auth/logout';

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await _deviceId.getOrCreate();

    final response = await http.post(
      Uri.parse('$_apiBaseUrl$loginPath'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'deviceId': deviceId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Parse tokens
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final expiresIn = data['expiresIn'] as int;
      final expiresAtUtc = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
      final userId = data['userId'] as String?;

      // Extract user metadata for role/premium info
      final metadata = _extractMetadata(data);

      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAtUtc: expiresAtUtc,
        userId: userId,
        metadata: metadata,
      );
    } else if (response.statusCode == 401) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Invalid credentials');
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  /// Signup endpoint (register + auto-login)
  Future<AuthSession> signup({
    required String email,
    required String password,
    String? username,
    String? country,
  }) async {
    final deviceId = await _deviceId.getOrCreate();

    final response = await http.post(
      Uri.parse('$_apiBaseUrl$signupPath'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'deviceId': deviceId,
        if (username != null) 'username': username,
        if (username != null) 'handle': username, // Backend might use 'handle'
        if (country != null) 'country': country,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Parse tokens
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final expiresIn = data['expiresIn'] as int;
      final expiresAtUtc = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
      final userId = data['userId'] as String?;

      // Extract user metadata for role/premium info
      final metadata = _extractMetadata(data);

      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAtUtc: expiresAtUtc,
        userId: userId,
        metadata: metadata,
      );
    } else if (response.statusCode == 409) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Email already registered');
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Invalid signup data');
    } else {
      throw Exception('Signup failed: ${response.statusCode}');
    }
  }

  /// Extract metadata from backend response
  /// This includes user info, role, premium status, tier, etc.
  Map<String, dynamic> _extractMetadata(Map<String, dynamic> response) {
    final metadata = <String, dynamic>{};

    // Extract user object if present
    if (response.containsKey('user') && response['user'] is Map) {
      final user = response['user'] as Map<String, dynamic>;

      // Add all user fields to metadata
      metadata.addAll(user);

      // Specific fields we care about:
      if (user.containsKey('role')) metadata['role'] = user['role'];
      if (user.containsKey('roles')) metadata['roles'] = user['roles'];
      if (user.containsKey('tier')) metadata['tier'] = user['tier'];
      if (user.containsKey('isPremium')) metadata['isPremium'] = user['isPremium'];
      if (user.containsKey('is_premium')) metadata['is_premium'] = user['is_premium'];
      if (user.containsKey('premium')) metadata['premium'] = user['premium'];
      if (user.containsKey('subscriptionStatus')) {
        metadata['subscriptionStatus'] = user['subscriptionStatus'];
      }
      if (user.containsKey('handle')) metadata['handle'] = user['handle'];
      if (user.containsKey('email')) metadata['email'] = user['email'];
      if (user.containsKey('mmr')) metadata['mmr'] = user['mmr'];
    }

    // Also check top-level fields (in case backend doesn't nest under 'user')
    if (response.containsKey('role')) metadata['role'] = response['role'];
    if (response.containsKey('roles')) metadata['roles'] = response['roles'];
    if (response.containsKey('tier')) metadata['tier'] = response['tier'];
    if (response.containsKey('isPremium')) metadata['isPremium'] = response['isPremium'];
    if (response.containsKey('is_premium')) metadata['is_premium'] = response['is_premium'];

    return metadata;
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
