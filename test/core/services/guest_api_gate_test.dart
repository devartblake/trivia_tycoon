import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/guest_api_gate.dart';

void main() {
  group('GuestApiGate', () {
    setUp(() {
      GuestApiGate.isGuestSession = false;
    });

    test('allowlists auth endpoints', () {
      expect(
        GuestApiGate.isAllowlisted(
            Uri.parse('https://api.synaptixplay.com/api/v1/auth/signup')),
        isTrue,
      );
      expect(
        GuestApiGate.isAllowlisted(
            Uri.parse('https://api.synaptixplay.com/api/v1/auth/login')),
        isTrue,
      );
      expect(
        GuestApiGate.isAllowlisted(
            Uri.parse('https://host/auth/device/bootstrap')),
        isTrue,
      );
    });

    test('does not allowlist unrelated paths that share a prefix', () {
      expect(
        GuestApiGate.isAllowlisted(
            Uri.parse('https://api.synaptixplay.com/api/v1/authority')),
        isFalse,
      );
    });

    test('blocks guest traffic for protected endpoints', () {
      GuestApiGate.isGuestSession = true;
      final blocked = GuestApiGate.shouldBlockNetworkRequest(
        Uri.parse('https://api.synaptixplay.com/api/v1/questions'),
        hasAuthTokens: true,
      );
      expect(blocked, isTrue);
    });

    test('allows guest traffic for auth even without tokens', () {
      GuestApiGate.isGuestSession = true;
      final blocked = GuestApiGate.shouldBlockNetworkRequest(
        Uri.parse('https://api.synaptixplay.com/api/v1/auth/signup'),
        hasAuthTokens: false,
      );
      expect(blocked, isFalse);
    });

    test('blocks unauthenticated non-guest protected traffic', () {
      GuestApiGate.isGuestSession = false;
      final blocked = GuestApiGate.shouldBlockNetworkRequest(
        Uri.parse('https://api.synaptixplay.com/api/v1/leaderboard'),
        hasAuthTokens: false,
      );
      expect(blocked, isTrue);
    });

    test('allows authenticated non-guest protected traffic', () {
      GuestApiGate.isGuestSession = false;
      final blocked = GuestApiGate.shouldBlockNetworkRequest(
        Uri.parse('https://api.synaptixplay.com/api/v1/leaderboard'),
        hasAuthTokens: true,
      );
      expect(blocked, isFalse);
    });
  });
}
