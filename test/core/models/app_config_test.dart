import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/app_config.dart';

void main() {
  group('FeatureFlags defaults (features open, crypto/dev gated)', () {
    test('defaultAlpha enables all user features except crypto and dev tester',
        () {
      const f = FeatureFlags.defaultAlpha;

      // Available to everyone by default.
      expect(f.socialEnabled, isTrue);
      expect(f.realtimeMultiplayerEnabled, isTrue);
      expect(f.matchmakingEnabled, isTrue);
      expect(f.tournamentsEnabled, isTrue);
      expect(f.skillTreeEnabled, isTrue);
      expect(f.notificationsEnabled, isTrue);
      expect(f.territoryEnabled, isTrue);
      expect(f.guardiansEnabled, isTrue);
      expect(f.experimentsEnabled, isTrue);

      // Deliberately gated.
      expect(f.cryptoEnabled, isFalse);
      expect(f.devTesterEnabled, isFalse);
    });

    test('fromJson defaults missing keys open, but crypto/dev stay closed', () {
      final f = FeatureFlags.fromJson(const {}); // backend returned no flags

      expect(f.socialEnabled, isTrue);
      expect(f.matchmakingEnabled, isTrue);
      expect(f.skillTreeEnabled, isTrue);
      expect(f.cryptoEnabled, isFalse);
      expect(f.devTesterEnabled, isFalse);
    });

    test(
        'backend can still force a flag off (e.g. crypto stays off, social on)',
        () {
      final f = FeatureFlags.fromJson(const {
        'socialEnabled': true,
        'cryptoEnabled': false,
        'realtimeMultiplayerEnabled': false, // backend override wins
      });

      expect(f.socialEnabled, isTrue);
      expect(f.cryptoEnabled, isFalse);
      expect(f.realtimeMultiplayerEnabled, isFalse);
    });
  });
}
