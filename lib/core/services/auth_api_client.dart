import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_token_store.dart';
import 'device_id_service.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class AuthApiException implements Exception {
  final String message;
  final int? statusCode;
  final String path;
  final String method;
  final String? responseBody;
  final Object? innerError;

  const AuthApiException({
    required this.message,
    required this.path,
    required this.method,
    this.statusCode,
    this.responseBody,
    this.innerError,
  });

  @override
  String toString() {
    final status = statusCode != null ? ' status=$statusCode' : '';
    final body = responseBody != null && responseBody!.trim().isNotEmpty
        ? ' body=${responseBody!.trim()}'
        : '';
    final inner = innerError != null ? ' inner=$innerError' : '';
    return 'AuthApiException($method $path$status): $message$body$inner';
  }
}

/// API client for authentication endpoints
class AuthApiClient {
  final http.Client _http;
  final String _apiBaseUrl;
  final DeviceIdService _deviceId;

  AuthApiClient(this._http,
      {required String apiBaseUrl, required DeviceIdService deviceId})
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

  void _logRequest(String method, String path, {Object? body}) {
    if (!kDebugMode) return;
    LogManager.debug('[AuthApiClient] $method ${_u(path)}');
    if (body != null) {
      LogManager.debug('[AuthApiClient] body=$body');
    }
  }

  void _logResponse(String method, String path, http.Response response) {
    if (!kDebugMode) return;
    LogManager.debug(
      '[AuthApiClient] $method ${_u(path)} -> ${response.statusCode} ${response.body}',
    );
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final deviceIdentity = await _deviceId.getDeviceIdentityPayload();
    final payload = {
      'email': email,
      'password': password,
      ...deviceIdentity,
    };

    _logRequest('POST', loginPath, body: payload);

    final http.Response response;
    try {
      response = await _http.post(
        _u(loginPath),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (e) {
      throw AuthApiException(
        message: 'Login request failed before receiving a response.',
        path: loginPath,
        method: 'POST',
        innerError: e,
      );
    }

    _logResponse('POST', loginPath, response);

    if (response.statusCode == 200) {
      final data = _decodeBodyMap(response.body, context: 'login');
      final session = _parseSession(data);

      // Extract user metadata for role/premium info
      final metadata = _extractMetadata(data);
      return session.copyWith(metadata: metadata);
    }

    if (response.statusCode == 401) {
      throw AuthApiException(
        message:
            _extractErrorMessage(response, fallback: 'Invalid credentials'),
        statusCode: response.statusCode,
        path: loginPath,
        method: 'POST',
        responseBody: response.body,
      );
    }

    throw AuthApiException(
      message: _extractErrorMessage(
        response,
        fallback: 'Login failed (HTTP ${response.statusCode})',
      ),
      statusCode: response.statusCode,
      path: loginPath,
      method: 'POST',
      responseBody: response.body,
    );
  }

  /// Signup endpoint (register + auto-login)
  Future<AuthSession> signup({
    required String email,
    required String password,
    String? username,
    String? country,
  }) async {
    final deviceIdentity = await _deviceId.getDeviceIdentityPayload();
    final payload = {
      'email': email,
      'password': password,
      ...deviceIdentity,
      if (username != null && username.isNotEmpty) 'username': username,
      if (username != null && username.isNotEmpty) 'handle': username,
      if (country != null && country.isNotEmpty) 'country': country,
    };

    _logRequest('POST', signupPath, body: payload);

    final http.Response response;
    try {
      response = await _http.post(
        _u(signupPath),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (e) {
      throw AuthApiException(
        message: 'Signup request failed before receiving a response.',
        path: signupPath,
        method: 'POST',
        innerError: e,
      );
    }

    _logResponse('POST', signupPath, response);

    if (response.statusCode == 200) {
      final data = _decodeBodyMap(response.body, context: 'signup');
      final session = _parseSession(data);

      // Extract user metadata for role/premium info
      final metadata = _extractMetadata(data);
      return session.copyWith(metadata: metadata);
    }

    if (response.statusCode == 409) {
      throw AuthApiException(
        message: _extractErrorMessage(
          response,
          fallback: 'Email already registered',
        ),
        statusCode: response.statusCode,
        path: signupPath,
        method: 'POST',
        responseBody: response.body,
      );
    }

    if (response.statusCode == 400) {
      throw AuthApiException(
        message: _extractErrorMessage(
          response,
          fallback: 'Invalid signup data',
        ),
        statusCode: response.statusCode,
        path: signupPath,
        method: 'POST',
        responseBody: response.body,
      );
    }

    throw AuthApiException(
      message: _extractErrorMessage(
        response,
        fallback: 'Signup failed (HTTP ${response.statusCode})',
      ),
      statusCode: response.statusCode,
      path: signupPath,
      method: 'POST',
      responseBody: response.body,
    );
  }

  /// Extract metadata from backend response
  /// This includes user info, role, premium status, tier, etc.
  Map<String, dynamic> _extractMetadata(Map<String, dynamic> response) {
    final metadata = <String, dynamic>{};

    // Extract user object if present
    if (response.containsKey('user') && response['user'] is Map) {
      final user = _asJsonMap(response['user']) ?? <String, dynamic>{};

      // Add all user fields to metadata
      metadata.addAll(user);

      // Specific fields we care about:
      if (user.containsKey('role')) metadata['role'] = user['role'];
      if (user.containsKey('roles')) metadata['roles'] = user['roles'];
      if (user.containsKey('tier')) metadata['tier'] = user['tier'];
      if (user.containsKey('isPremium'))
        metadata['isPremium'] = user['isPremium'];
      if (user.containsKey('is_premium'))
        metadata['is_premium'] = user['is_premium'];
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
    if (response.containsKey('isPremium'))
      metadata['isPremium'] = response['isPremium'];
    if (response.containsKey('is_premium'))
      metadata['is_premium'] = response['is_premium'];

    return metadata;
  }

  Future<AuthSession> refresh({
    required String refreshToken,
    required String deviceId,
    String? deviceType,
  }) async {
    final resolvedDeviceType = deviceType ?? _deviceId.getDeviceType();
    final payload = {
      'refresh_token': refreshToken,
      'refreshToken': refreshToken,
      'device_id': deviceId,
      'deviceId': deviceId,
      'device_type': resolvedDeviceType,
      'deviceType': resolvedDeviceType,
    };

    _logRequest('POST', refreshPath, body: payload);

    final http.Response res;
    try {
      res = await _http.post(
        _u(refreshPath),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (e) {
      throw AuthApiException(
        message: 'Refresh request failed before receiving a response.',
        path: refreshPath,
        method: 'POST',
        innerError: e,
      );
    }

    _logResponse('POST', refreshPath, res);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        message: 'Refresh failed.',
        statusCode: res.statusCode,
        path: refreshPath,
        method: 'POST',
        responseBody: res.body,
      );
    }

    final json = _decodeBodyMap(res.body, context: 'refresh');
    return _parseSession(json);
  }

  Future<void> logout({
    required String deviceId,
    String? deviceType,
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

    final payload = {
      'device_id': deviceId,
      'deviceId': deviceId,
      'device_type': deviceType ?? _deviceId.getDeviceType(),
      'deviceType': deviceType ?? _deviceId.getDeviceType(),
      if (userId != null) 'user_id': userId,
      if (userId != null) 'userId': userId,
    };

    _logRequest('POST', logoutPath, body: payload);

    final http.Response res;
    try {
      res = await _http.post(
        _u(logoutPath),
        headers: headers,
        body: jsonEncode(payload),
      );
    } catch (e) {
      throw AuthApiException(
        message: 'Logout request failed before receiving a response.',
        path: logoutPath,
        method: 'POST',
        innerError: e,
      );
    }

    _logResponse('POST', logoutPath, res);

    // Best-effort logout: token may already be expired/revoked on server.
    if (res.statusCode == 401 || res.statusCode == 404) {
      return;
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        message: 'Logout failed.',
        statusCode: res.statusCode,
        path: logoutPath,
        method: 'POST',
        responseBody: res.body,
      );
    }
  }

  Future<String?> getOAuthUrl(String provider) async {
    final path = '/auth/oauth/$provider';
    _logRequest('GET', path);

    final http.Response response;
    try {
      response = await _http.get(
        _u(path),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      throw AuthApiException(
        message: 'OAuth URL request failed before receiving a response.',
        path: path,
        method: 'GET',
        innerError: e,
      );
    }

    _logResponse('GET', path, response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        message: _extractErrorMessage(
          response,
          fallback: 'Failed to fetch OAuth URL for $provider.',
        ),
        statusCode: response.statusCode,
        path: path,
        method: 'GET',
        responseBody: response.body,
      );
    }

    final parsed = _tryDecodeBodyMap(response.body);
    if (parsed != null) {
      return (parsed['url'] ?? parsed['authUrl'] ?? parsed['redirectUrl'])
          ?.toString();
    }

    final raw = response.body.trim();
    return raw.isEmpty ? null : raw;
  }

  Map<String, dynamic> _decodeBodyMap(String body, {required String context}) {
    final parsed = _tryDecodeBodyMap(body);
    if (parsed != null) return parsed;

    throw Exception('Invalid $context response from server');
  }

  Map<String, dynamic>? _tryDecodeBodyMap(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      return _asJsonMap(decoded);
    } catch (_) {
      return null;
    }
  }

  String _extractErrorMessage(http.Response response,
      {required String fallback}) {
    final parsed = _tryDecodeBodyMap(response.body);
    if (parsed != null) {
      final nestedError = _asJsonMap(parsed['error']);
      final nestedMessage = _asNullableString(nestedError?['message']);
      if (nestedMessage != null) {
        return nestedMessage;
      }

      final dynamic message = parsed['message'] ??
          parsed['error'] ??
          parsed['detail'] ??
          parsed['title'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return fallback;
  }

  Map<String, dynamic>? _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return null;
  }

  String _asString(Object? value) {
    if (value == null) return '';
    final raw = value.toString().trim();
    return raw;
  }

  String? _asNullableString(Object? value) {
    final raw = _asString(value);
    if (raw.isEmpty) return null;
    return raw;
  }

  AuthSession _parseSession(Map<String, dynamic> json) {
    // Try common shapes:
    // { accessToken, refreshToken, expiresAtUtc, userId }
    // { access_token, refresh_token, expires_at, user_id }
    final access = _asString(json['accessToken'] ?? json['access_token']);
    final refresh = _asString(json['refreshToken'] ?? json['refresh_token']);

    final userId = _asNullableString(json['userId'] ?? json['user_id']);

    // Parse expiration
    DateTime? expiresAtUtc;

    // Backend returns expiresIn (seconds)
    final expiresIn = json['expiresIn'];
    if (expiresIn is int) {
      expiresAtUtc = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
    }

    // Or expiresAtUtc as ISO string
    final expiresRaw =
        json['expiresAtUtc'] ?? json['expires_at'] ?? json['expiresAt'];
    if (expiresRaw is String && expiresRaw.isNotEmpty) {
      expiresAtUtc = DateTime.tryParse(expiresRaw)?.toUtc();
    } else if (expiresRaw is int) {
      // If backend returns epoch seconds or ms, adapt here if needed.
      // Assuming ms:
      expiresAtUtc =
          DateTime.fromMillisecondsSinceEpoch(expiresRaw, isUtc: true);
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
