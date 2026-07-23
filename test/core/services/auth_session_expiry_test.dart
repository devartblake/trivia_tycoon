import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/auth_token_store.dart';

AuthSession _session(DateTime? expiresAtUtc) => AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      expiresAtUtc: expiresAtUtc,
    );

void main() {
  group('AuthSession.isExpiringSoon (proactive-refresh threshold)', () {
    final now = DateTime.utc(2026, 1, 1, 12, 0, 0);

    test('false when the token has plenty of life left', () {
      // 15-min token, 15 min remaining → not soon (default 3-min lead).
      final s = _session(now.add(const Duration(minutes: 15)));
      expect(s.isExpiringSoon(now: now), isFalse);
    });

    test('true once inside the lead window (still valid → proactive)', () {
      // 2 min left, 3-min lead → refresh now, while token is still valid.
      final s = _session(now.add(const Duration(minutes: 2)));
      expect(s.isExpiringSoon(now: now), isTrue);
      // And it is genuinely still valid (not yet expired) at this point.
      expect(now.toUtc().isAfter(s.expiresAtUtc!), isFalse);
    });

    test('true when already expired', () {
      final s = _session(now.subtract(const Duration(minutes: 1)));
      expect(s.isExpiringSoon(now: now), isTrue);
    });

    test('respects a custom lead', () {
      final s = _session(now.add(const Duration(minutes: 5)));
      expect(s.isExpiringSoon(lead: const Duration(minutes: 3), now: now),
          isFalse);
      expect(s.isExpiringSoon(lead: const Duration(minutes: 6), now: now),
          isTrue);
    });

    test('false when expiry is unknown', () {
      expect(_session(null).isExpiringSoon(now: now), isFalse);
    });
  });
}
