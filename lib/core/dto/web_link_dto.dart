/// DTO models for the three web account linking methods.
///
/// All three methods share a common goal: let a web browser session obtain an
/// authenticated session token that originated from a mobile identity.
///
/// **Method 1 — QR code**
/// Web generates a short-lived token → displays as QR → mobile scans and
/// consumes → web polls for a session token.
///
/// **Method 2 — Google Sign-In on web**
/// Web initiates Google Sign-In → obtains an ID token → backend verifies and
/// creates a session.
///
/// **Method 3 — One-time link code**
/// Mobile generates a 6-character alphanumeric code → user types it into the
/// web browser → backend validates and returns a session.

// ---------------------------------------------------------------------------
// QR linking
// ---------------------------------------------------------------------------

class QrTokenResponse {
  final String qrToken;
  final int expiresIn; // seconds

  const QrTokenResponse({required this.qrToken, required this.expiresIn});

  factory QrTokenResponse.fromJson(Map<String, dynamic> j) {
    return QrTokenResponse(
      qrToken: j['qrToken'] as String? ?? '',
      expiresIn: j['expiresIn'] as int? ?? 300,
    );
  }
}

enum QrLinkStatus { pending, consumed, expired }

class QrStatusResponse {
  final QrLinkStatus status;

  /// Set when [status] is [QrLinkStatus.consumed].
  final String? sessionToken;

  const QrStatusResponse({required this.status, this.sessionToken});

  factory QrStatusResponse.fromJson(Map<String, dynamic> j) {
    final raw = j['status'] as String? ?? 'pending';
    final status = switch (raw) {
      'consumed' => QrLinkStatus.consumed,
      'expired' => QrLinkStatus.expired,
      _ => QrLinkStatus.pending,
    };
    return QrStatusResponse(
      status: status,
      sessionToken: j['sessionToken'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// One-time link code
// ---------------------------------------------------------------------------

class LinkCodeResponse {
  final String code;
  final int expiresIn; // seconds

  const LinkCodeResponse({required this.code, required this.expiresIn});

  factory LinkCodeResponse.fromJson(Map<String, dynamic> j) {
    return LinkCodeResponse(
      code: j['code'] as String? ?? '',
      expiresIn: j['expiresIn'] as int? ?? 300,
    );
  }
}

// ---------------------------------------------------------------------------
// Google web auth
// ---------------------------------------------------------------------------

class GoogleWebAuthResponse {
  final String accessToken;
  final String refreshToken;
  final String? userId;

  const GoogleWebAuthResponse({
    required this.accessToken,
    required this.refreshToken,
    this.userId,
  });

  factory GoogleWebAuthResponse.fromJson(Map<String, dynamic> j) {
    return GoogleWebAuthResponse(
      accessToken:
          j['accessToken'] as String? ?? j['access_token'] as String? ?? '',
      refreshToken:
          j['refreshToken'] as String? ?? j['refresh_token'] as String? ?? '',
      userId: j['userId'] as String? ?? j['user_id'] as String?,
    );
  }
}
