import 'dart:convert';

import 'package:http/http.dart' as http;

/// Central policy for blocking backend traffic during guest / unauthenticated
/// sessions so the app does not spam `api.synaptixplay.com`.
///
/// Auth, health, and a few public bootstrap endpoints remain allowlisted so
/// guests can still sign up / log in / upgrade an account.
class GuestApiGate {
  GuestApiGate._();

  static const String blockedErrorCode = 'guest_mode_blocked';
  static const String blockedHeader = 'x-synaptix-guest-gate';

  /// In-memory guest flag (synced from [GuestSessionStore]).
  /// Read by [AuthHttpClient] without Riverpod.
  static bool isGuestSession = false;

  /// Paths (and path prefixes) that may hit the network without a full account.
  ///
  /// Covers both absolute API paths (`/api/v1/...`) and Dio-relative paths
  /// when the client base URL already includes `/api/v1`.
  static const List<String> allowlistedPathPrefixes = <String>[
    '/api/v1/auth',
    '/auth',
    '/api/v1/health',
    '/health',
    '/api/v1/assets/manifest',
    '/assets/manifest',
    '/api/v1/app/config',
    '/app/config',
    '/api/v1/security/sessions',
    '/security/sessions',
  ];

  /// Returns true when the request must not leave the client.
  static bool shouldBlockNetworkRequest(
    Uri uri, {
    required bool hasAuthTokens,
    bool? isGuestSession,
  }) {
    final guest = isGuestSession ?? GuestApiGate.isGuestSession;
    if (isAllowlisted(uri)) return false;

    // Explicit guest play: local-only for all non-auth traffic.
    if (guest) return true;

    // Unauthenticated non-guest: also block protected calls (no token spam).
    if (!hasAuthTokens) return true;

    return false;
  }

  static bool isAllowlisted(Uri uri) {
    final path = _normalizedPath(uri);
    for (final prefix in allowlistedPathPrefixes) {
      if (path == prefix || path.startsWith('$prefix/')) {
        return true;
      }
    }
    return false;
  }

  static String _normalizedPath(Uri uri) {
    var path = uri.path.isEmpty ? '/' : uri.path;
    if (!path.startsWith('/')) path = '/$path';
    // Collapse trailing slash except root.
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  static Map<String, dynamic> blockedBody({String? path}) => <String, dynamic>{
        'error': blockedErrorCode,
        'message':
            'Backend API is disabled for guest / unauthenticated sessions. Sign up to enable online features.',
        if (path != null) 'path': path,
      };

  /// Synthetic HTTP response used by [AuthHttpClient] — no network I/O.
  static http.StreamedResponse blockedStreamedResponse(Uri uri) {
    final bytes = utf8.encode(jsonEncode(blockedBody(path: uri.path)));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      401,
      contentLength: bytes.length,
      headers: <String, String>{
        'content-type': 'application/json',
        blockedHeader: 'blocked',
      },
      reasonPhrase: 'Guest mode — network blocked',
      request: http.Request('GET', uri),
    );
  }
}
