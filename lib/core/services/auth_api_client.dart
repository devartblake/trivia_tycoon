import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_token_store.dart';
import 'device_id_service.dart';
import '../security/secure_session_store.dart';
import 'package:synaptix/core/manager/log_manager.dart';

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
  final SecureSessionStore? _secureSessionStore;

  AuthApiClient(this._http,
      {required String apiBaseUrl,
      required DeviceIdService deviceId,
      SecureSessionStore? secureSessionStore})
      : _apiBaseUrl = apiBaseUrl.endsWith('/')
            ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
            : apiBaseUrl,
        _deviceId = deviceId,
        _secureSessionStore = secureSessionStore;

  Uri _u(String path) => Uri.parse('$_apiBaseUrl$path');

  /// Adjust these paths to match your backend:
  static const String loginPath = '/auth/login';
  static const String signupPath = '/auth/signup';
  static const String refreshPath = '/auth/refresh';
  static const String logoutPath = '/auth/logout';
  static const String deviceBootstrapPath = '/auth/device/bootstrap';
  static const String accountUpgradePath = '/auth/account/upgrade';

  void _logRequest(String method, String path, {Object? body}) {
    if (!kDebugMode) return;
    LogManager.debug('[AuthApiClient] $method ${_u(path)}');
    if (body != null) {
      LogManager.debug('[AuthApiClient] body=${_redactSensitive(body)}');
    }
  }

  void _logResponse(String method, String path, http.Response response) {
    if (!kDebugMode) return;
    LogManager.debug(
      '[AuthApiClient] $method ${_u(path)} -> ${response.statusCode} ${_redactResponseBody(response.body)}',
    );
  }

  Object? _redactSensitive(Object? value) {
    const sensitiveKeys = {
      'password',
      'accessToken',
      'access_token',
      'refreshToken',
      'refresh_token',
      'idToken',
      'id_token',
      'token',
      'authorization',
    };

    if (value is Map) {
      return value.map((key, entry) {
        final keyText = key.toString();
        return MapEntry(
          key,
          sensitiveKeys.contains(keyText)
              ? '<redacted>'
              : _redactSensitive(entry),
        );
      });
    }
    if (value is Iterable && value is! String) {
      return value.map(_redactSensitive).toList();
    }
    return value;
  }

  String _redactResponseBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return trimmed;
    try {
      return jsonEncode(_redactSensitive(jsonDecode(trimmed)));
    } catch (_) {
      return trimmed;
    }
  }

  Future<Map<String, String>> _jsonHeaders({
    bool includeSecureSession = false,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    final secureSessionStore = _secureSessionStore;
    if (includeSecureSession && secureSessionStore != null) {
      final session = await secureSessionStore.load();
      if (session != null &&
          !session.isExpired &&
          session.sessionId.isNotEmpty) {
        headers['X-Syn-Sec-Session'] = session.sessionId.replaceAll('-', '');
        headers['X-Syn-Sec-Version'] = session.protocolVersion;
      }
    }

    return headers;
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
        headers: await _jsonHeaders(),
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
    // COPPA/CCPA requirement: collect DOB at signup so the compliance service
    // can gate prize and crypto features. Format: YYYY-MM-DD.
    String? dateOfBirth,
  }) async {
    final deviceIdentity = await _deviceId.getDeviceIdentityPayload();
    final payload = {
      'email': email,
      'password': password,
      ...deviceIdentity,
      if (username != null && username.isNotEmpty) 'username': username,
      if (username != null && username.isNotEmpty) 'handle': username,
      if (country != null && country.isNotEmpty) 'country': country,
      if (dateOfBirth != null && dateOfBirth.isNotEmpty)
        'dateOfBirth': dateOfBirth,
    };

    _logRequest('POST', signupPath, body: payload);

    final http.Response response;
    try {
      response = await _http.post(
        _u(signupPath),
        headers: await _jsonHeaders(),
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

  /// Upgrade a device/platform session into a full email account.
  ///
  /// Backend: `POST /auth/account/upgrade`
  /// body: `{ email, password, username?, country?, deviceId, deviceType }`
  /// returns the same session JSON as login/signup.
  Future<AuthSession> upgradeAccount({
    required String email,
    required String password,
    String? username,
    String? country,
    String? accessToken,
  }) async {
    final deviceIdentity = await _deviceId.getDeviceIdentityPayload();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    final payload = {
      'email': email,
      'password': password,
      ...deviceIdentity,
      if (username != null && username.isNotEmpty) 'username': username,
      if (username != null && username.isNotEmpty) 'handle': username,
      if (country != null && country.isNotEmpty) 'country': country,
    };

    _logRequest('POST', accountUpgradePath, body: payload);

    final http.Response response;
    try {
      response = await _http.post(
        _u(accountUpgradePath),
        headers: headers,
        body: jsonEncode(payload),
      );
    } catch (e) {
      throw AuthApiException(
        message: 'Account upgrade failed before receiving a response.',
        path: accountUpgradePath,
        method: 'POST',
        innerError: e,
      );
    }

    _logResponse('POST', accountUpgradePath, response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _decodeBodyMap(response.body, context: 'account-upgrade');
      final session = _parseSession(data);
      final metadata = _extractMetadata(data);
      return session.copyWith(metadata: metadata);
    }

    throw AuthApiException(
      message: _extractErrorMessage(
        response,
        fallback: 'Account upgrade failed (HTTP ${response.statusCode})',
      ),
      statusCode: response.statusCode,
      path: accountUpgradePath,
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
      if (user.containsKey('isPremium')) {
        metadata['isPremium'] = user['isPremium'];
      }
      if (user.containsKey('is_premium')) {
        metadata['is_premium'] = user['is_premium'];
      }
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
    if (response.containsKey('isPremium')) {
      metadata['isPremium'] = response['isPremium'];
    }
    if (response.containsKey('is_premium')) {
      metadata['is_premium'] = response['is_premium'];
    }
    if (response.containsKey('premium')) {
      metadata['premium'] = response['premium'];
    }
    if (response.containsKey('subscriptionStatus')) {
      metadata['subscriptionStatus'] = response['subscriptionStatus'];
    }

    return metadata;
  }

  Future<AuthSession> refresh({
    required String refreshToken,
    required String deviceId,
    String? deviceType,
  }) async {
    final resolvedDeviceType = deviceType ?? _deviceId.getDeviceType();
    final payload = {
      'refreshToken': refreshToken,
      'deviceId': deviceId,
      'deviceType': resolvedDeviceType,
    };

    _logRequest('POST', refreshPath, body: payload);

    final http.Response res;
    try {
      res = await _http.post(
        _u(refreshPath),
        headers: await _jsonHeaders(includeSecureSession: true),
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

  // -------------------------------------------------------------------------
  // Mobile game platform auth
  // -------------------------------------------------------------------------

  /// Bootstrap a lightweight device-first session.
  ///
  /// Backend contract:
  /// `POST /auth/device/bootstrap`
  /// body: `{ deviceId, deviceType, platform?, platformPlayerId?, displayName? }`
  /// returns the same session JSON as login/signup when the backend is ready.
  Future<AuthSession> bootstrapDevice({
    String? platform,
    String? platformPlayerId,
    String? displayName,
  }) async {
    final deviceIdentity = await _deviceId.getDeviceIdentityPayload();
    final payload = {
      ...deviceIdentity,
      if (platform != null) 'platform': platform,
      if (platformPlayerId != null) 'platformPlayerId': platformPlayerId,
      if (displayName != null) 'displayName': displayName,
    };

    _logRequest('POST', deviceBootstrapPath, body: payload);

    final http.Response response;
    try {
      response = await _http.post(
        _u(deviceBootstrapPath),
        headers: await _jsonHeaders(),
        body: jsonEncode(payload),
      );
    } catch (e) {
      throw AuthApiException(
        message: 'Device bootstrap failed before receiving a response.',
        path: deviceBootstrapPath,
        method: 'POST',
        innerError: e,
      );
    }

    _logResponse('POST', deviceBootstrapPath, response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _decodeBodyMap(response.body, context: 'device-bootstrap');
      final session = _parseSession(data);
      final metadata = _extractMetadata(data);
      return session.copyWith(metadata: metadata);
    }

    throw AuthApiException(
      message: _extractErrorMessage(
        response,
        fallback: 'Device bootstrap failed (HTTP ${response.statusCode})',
      ),
      statusCode: response.statusCode,
      path: deviceBootstrapPath,
      method: 'POST',
      responseBody: response.body,
    );
  }

  static const String mobileGameLoginPath = '/auth/mobile-game-login';
  static const String linkGameAccountPath = '/auth/link-game-account';

  /// Authenticate using a native game platform identity (Game Center / Play Games).
  ///
  /// The backend must implement `POST /auth/mobile-game-login` which accepts:
  /// `{ platform, playerId, displayName }` and returns the same session JSON
  /// as the regular login endpoint.
  Future<AuthSession> loginWithGamePlatform({
    required String platform,
    required String playerId,
    required String displayName,
  }) async {
    final deviceIdentity = await _deviceId.getDeviceIdentityPayload();
    final payload = {
      'platform': platform,
      'playerId': playerId,
      'displayName': displayName,
      ...deviceIdentity,
    };

    _logRequest('POST', mobileGameLoginPath, body: payload);

    final http.Response response;
    try {
      response = await _http.post(
        _u(mobileGameLoginPath),
        headers: await _jsonHeaders(),
        body: jsonEncode(payload),
      );
    } catch (e) {
      throw AuthApiException(
        message:
            'Mobile game login request failed before receiving a response.',
        path: mobileGameLoginPath,
        method: 'POST',
        innerError: e,
      );
    }

    _logResponse('POST', mobileGameLoginPath, response);

    if (response.statusCode == 200) {
      final data = _decodeBodyMap(response.body, context: 'mobile-game-login');
      final session = _parseSession(data);
      final metadata = _extractMetadata(data);
      return session.copyWith(metadata: metadata);
    }

    throw AuthApiException(
      message: _extractErrorMessage(
        response,
        fallback: 'Mobile game login failed (HTTP ${response.statusCode})',
      ),
      statusCode: response.statusCode,
      path: mobileGameLoginPath,
      method: 'POST',
      responseBody: response.body,
    );
  }

  /// Link a game platform identity to the currently authenticated account.
  ///
  /// Requires the caller to supply a valid Bearer access token in the request.
  /// The backend must implement `POST /auth/link-game-account`.
  Future<void> linkGameAccount({
    required String platform,
    required String playerId,
    required String accessToken,
  }) async {
    final payload = {
      'platform': platform,
      'playerId': playerId,
    };

    _logRequest('POST', linkGameAccountPath, body: payload);

    final http.Response response;
    try {
      response = await _http.post(
        _u(linkGameAccountPath),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );
    } catch (e) {
      throw AuthApiException(
        message:
            'Link game account request failed before receiving a response.',
        path: linkGameAccountPath,
        method: 'POST',
        innerError: e,
      );
    }

    _logResponse('POST', linkGameAccountPath, response);

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw AuthApiException(
      message: _extractErrorMessage(
        response,
        fallback: 'Link game account failed (HTTP ${response.statusCode})',
      ),
      statusCode: response.statusCode,
      path: linkGameAccountPath,
      method: 'POST',
      responseBody: response.body,
    );
  }

  Future<String?> getOAuthUrl(String provider) async {
    final path = '/auth/oauth/$provider';
    _logRequest('GET', path);

    final http.Response response;
    try {
      response = await _http.get(
        _u(path),
        headers: await _jsonHeaders(),
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
    // { ..., user: { id, handle, ... } }   ← device/bootstrap + login shape
    final access = _asString(json['accessToken'] ?? json['access_token']);
    final refresh = _asString(json['refreshToken'] ?? json['refresh_token']);

    // The device-bootstrap/login payloads carry the id nested under `user.id`
    // rather than a top-level `userId`; without this fallback session.userId is
    // null, auth_user_id is never persisted, and the app falls back to a
    // generated local_<guid> identity (404s on personalization/rewards, tier
    // and weekly clients log "Missing user ID").
    final nestedUser = json['user'];
    final nestedUserId =
        nestedUser is Map ? (nestedUser['id'] ?? nestedUser['userId']) : null;
    final userId =
        _asNullableString(json['userId'] ?? json['user_id'] ?? nestedUserId);

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
