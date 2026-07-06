import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_api_client.dart' show AuthApiException;
import 'auth_token_store.dart';
import 'auth_service.dart' show BackendAuthService;
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// HTTP client that automatically adds auth headers and refreshes expired tokens
///
/// Usage:
/// ```dart
/// final client = AuthHttpClient(authService, tokenStore);
/// final response = await client.get(Uri.parse('https://api.example.com/data'));
/// ```
class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final BackendAuthService _authService;
  final AuthTokenStore _tokenStore;

  /// Whether to automatically refresh expired tokens
  final bool autoRefresh;

  /// Optional callback when token is refreshed
  final void Function()? onTokenRefreshed;

  /// Optional callback when refresh fails (user needs to re-login)
  final void Function(Exception error)? onRefreshFailed;

  // Serializes concurrent refresh attempts — all callers await the same future.
  Future<void>? _pendingRefresh;

  AuthHttpClient(
    this._authService,
    this._tokenStore, {
    http.Client? innerClient,
    this.autoRefresh = true,
    this.onTokenRefreshed,
    this.onRefreshFailed,
  }) : _inner = innerClient ?? http.Client();

  Future<void> _refreshOnce() {
    _pendingRefresh ??=
        _authService.refresh().whenComplete(() => _pendingRefresh = null);
    return _pendingRefresh!;
  }

  Exception _asException(Object error) =>
      error is Exception ? error : Exception(error.toString());

  bool _isSecureSessionRequired(Object error) {
    return error is AuthApiException &&
        (error.responseBody?.contains('secure_session_required') ?? false);
  }

  Future<void> _clearUnrefreshableSession(Object error) async {
    if (!_isSecureSessionRequired(error)) return;
    LogManager.debug(
        '[AuthHttpClient] Clearing auth tokens because refresh requires a missing secure session');
    await _tokenStore.clear();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Load current session
    final session = _tokenStore.load();

    // Check if token is expired and auto-refresh is enabled.
    // _pendingRefresh serializes concurrent requests so only one refresh
    // call is issued even when multiple requests detect expiry simultaneously.
    if (autoRefresh && session.hasTokens && session.isExpired) {
      try {
        LogManager.debug('[AuthHttpClient] Token expired, refreshing...');
        await _refreshOnce();
        onTokenRefreshed?.call();
        LogManager.debug('[AuthHttpClient] Token refreshed successfully');
      } catch (e) {
        _pendingRefresh = null;
        LogManager.debug('[AuthHttpClient] Token refresh failed: $e');
        await _clearUnrefreshableSession(e);
        onRefreshFailed?.call(_asException(e));
        // Continue with expired token - backend will reject and user will need to re-login
      }
    }

    // Add auth header if we have a token
    final currentSession = _tokenStore.load();
    if (currentSession.hasTokens && currentSession.accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${currentSession.accessToken}';
    }

    // Add common headers
    request.headers['Content-Type'] ??= 'application/json';
    request.headers['Accept'] = 'application/json';

    try {
      // Send request
      final response = await _inner.send(request);

      // If we get 401, token might be invalid - try refresh once
      if (response.statusCode == 401 &&
          autoRefresh &&
          currentSession.hasTokens) {
        LogManager.debug(
            '[AuthHttpClient] Got 401, attempting token refresh...');

        try {
          await _refreshOnce();
          onTokenRefreshed?.call();

          // Retry request with new token
          final retryRequest = _copyRequest(request);
          final newSession = _tokenStore.load();
          retryRequest.headers['Authorization'] =
              'Bearer ${newSession.accessToken}';

          return await _inner.send(retryRequest);
        } catch (e) {
          LogManager.debug('[AuthHttpClient] Retry failed: $e');
          await _clearUnrefreshableSession(e);
          onRefreshFailed?.call(_asException(e));
          // Return original 401 response
          return response;
        }
      }

      return response;
    } catch (e) {
      LogManager.debug('[AuthHttpClient] Request error: $e');
      rethrow;
    }
  }

  /// Copy a request for retry (http.BaseRequest can't be reused)
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    http.BaseRequest newRequest;

    if (request is http.Request) {
      newRequest = http.Request(request.method, request.url)
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding;
    } else if (request is http.MultipartRequest) {
      newRequest = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw Exception('Cannot retry StreamedRequest');
    } else {
      throw Exception('Unknown request type');
    }

    newRequest.headers.addAll(request.headers);
    return newRequest;
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Extension methods for easier usage
extension AuthHttpClientExtensions on AuthHttpClient {
  /// GET request with automatic auth and refresh
  Future<http.Response> getAuth(Uri url, {Map<String, String>? headers}) {
    return get(url, headers: headers);
  }

  /// POST request with automatic auth and refresh
  Future<http.Response> postAuth(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return post(url, headers: headers, body: body, encoding: encoding);
  }

  /// PUT request with automatic auth and refresh
  Future<http.Response> putAuth(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return put(url, headers: headers, body: body, encoding: encoding);
  }

  /// DELETE request with automatic auth and refresh
  Future<http.Response> deleteAuth(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return delete(url, headers: headers, body: body, encoding: encoding);
  }
}
