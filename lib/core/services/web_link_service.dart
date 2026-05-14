import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../dto/web_link_dto.dart';

/// Handles all three web account linking methods.
///
/// Each method requires corresponding backend endpoints — see inline docs.
/// All methods throw [WebLinkException] on HTTP or parse errors.
class WebLinkService {
  final http.Client _http;
  final String _apiBaseUrl;

  /// Bearer token for authenticated requests (mobile → backend).
  final String Function() _accessTokenGetter;

  WebLinkService({
    required http.Client httpClient,
    required String apiBaseUrl,
    required String Function() accessTokenGetter,
  })  : _http = httpClient,
        _apiBaseUrl = apiBaseUrl.endsWith('/')
            ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
            : apiBaseUrl,
        _accessTokenGetter = accessTokenGetter;

  Uri _u(String path) => Uri.parse('$_apiBaseUrl$path');

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_accessTokenGetter()}',
      };

  Map<String, String> get _publicHeaders => {
        'Content-Type': 'application/json',
      };

  // -------------------------------------------------------------------------
  // Method 1 — QR code
  // -------------------------------------------------------------------------

  /// [Web] Generate a short-lived QR token.
  ///
  /// Backend: `POST /auth/link/qr/generate` (unauthenticated)
  /// → `{ qrToken: String, expiresIn: int }`
  Future<QrTokenResponse> generateQrToken() async {
    final response = await _http.post(
      _u('/auth/link/qr/generate'),
      headers: _publicHeaders,
    );
    _assertSuccess(response, '/auth/link/qr/generate');
    return QrTokenResponse.fromJson(_decode(response.body));
  }

  /// [Web] Poll status of a QR token.
  ///
  /// Backend: `GET /auth/link/qr/status/{qrToken}`
  /// → `{ status: 'pending'|'consumed'|'expired', sessionToken?: String }`
  Future<QrStatusResponse> pollQrStatus(String qrToken) async {
    final response = await _http.get(
      _u('/auth/link/qr/status/$qrToken'),
      headers: _publicHeaders,
    );
    _assertSuccess(response, '/auth/link/qr/status');
    return QrStatusResponse.fromJson(_decode(response.body));
  }

  /// [Mobile] Consume a QR token, linking the web session to the mobile account.
  ///
  /// Backend: `POST /auth/link/qr/consume` (requires Bearer token)
  /// body: `{ qrToken: String }`
  Future<void> consumeQrToken(String qrToken) async {
    final response = await _http.post(
      _u('/auth/link/qr/consume'),
      headers: _authHeaders,
      body: jsonEncode({'qrToken': qrToken}),
    );
    _assertSuccess(response, '/auth/link/qr/consume');
  }

  // -------------------------------------------------------------------------
  // Method 2 — Google Sign-In on web
  // -------------------------------------------------------------------------

  /// [Web] Exchange a Google ID token for a backend session.
  ///
  /// Backend: `POST /auth/google-web`
  /// body: `{ googleIdToken: String }`
  /// → same session JSON as regular login
  Future<GoogleWebAuthResponse> authenticateWithGoogleToken(
      String googleIdToken) async {
    final response = await _http.post(
      _u('/auth/google-web'),
      headers: _publicHeaders,
      body: jsonEncode({'googleIdToken': googleIdToken}),
    );
    _assertSuccess(response, '/auth/google-web');
    return GoogleWebAuthResponse.fromJson(_decode(response.body));
  }

  // -------------------------------------------------------------------------
  // Method 3 — One-time link code
  // -------------------------------------------------------------------------

  /// [Mobile] Generate a one-time link code for the currently logged-in user.
  ///
  /// Backend: `POST /auth/link/code/generate` (requires Bearer token)
  /// → `{ code: String, expiresIn: int }`
  Future<LinkCodeResponse> generateLinkCode() async {
    final response = await _http.post(
      _u('/auth/link/code/generate'),
      headers: _authHeaders,
    );
    _assertSuccess(response, '/auth/link/code/generate');
    return LinkCodeResponse.fromJson(_decode(response.body));
  }

  /// [Web] Consume a one-time link code to obtain a backend session.
  ///
  /// Backend: `POST /auth/link/code/consume` (unauthenticated)
  /// body: `{ code: String }`
  /// → same session JSON as regular login
  Future<GoogleWebAuthResponse> consumeLinkCode(String code) async {
    final response = await _http.post(
      _u('/auth/link/code/consume'),
      headers: _publicHeaders,
      body: jsonEncode({'code': code}),
    );
    _assertSuccess(response, '/auth/link/code/consume');
    return GoogleWebAuthResponse.fromJson(_decode(response.body));
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  void _assertSuccess(http.Response response, String path) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebLinkException(
        'HTTP ${response.statusCode} from $path',
        statusCode: response.statusCode,
        path: path,
      );
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
      throw FormatException('Expected JSON object');
    } catch (e) {
      throw WebLinkException('Invalid JSON response: $e', path: '?');
    }
  }
}

class WebLinkException implements Exception {
  final String message;
  final int? statusCode;
  final String path;

  const WebLinkException(this.message, {this.statusCode, required this.path});

  @override
  String toString() {
    final s = statusCode != null ? ' (HTTP $statusCode)' : '';
    return 'WebLinkException: $message$s at $path';
  }
}
