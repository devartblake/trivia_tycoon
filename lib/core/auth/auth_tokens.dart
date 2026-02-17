class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAtUtc;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAtUtc,
  });

  bool get isExpired {
    if (expiresAtUtc == null) return false;
    // small skew to refresh early
    return DateTime.now().toUtc().isAfter(expiresAtUtc!.subtract(const Duration(seconds: 20)));
  }

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAtUtc,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAtUtc: expiresAtUtc ?? this.expiresAtUtc,
    );
  }
}
