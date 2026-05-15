import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/game_platform_auth_service.dart';

void main() {
  // -------------------------------------------------------------------------
  // GamePlatformIdentity
  // -------------------------------------------------------------------------

  group('GamePlatformIdentity', () {
    test('stores all fields correctly', () {
      const identity = GamePlatformIdentity(
        platform: 'ios',
        playerId: 'player-001',
        displayName: 'Alice',
      );
      expect(identity.platform, 'ios');
      expect(identity.playerId, 'player-001');
      expect(identity.displayName, 'Alice');
    });

    test('toJson returns correct map', () {
      const identity = GamePlatformIdentity(
        platform: 'android',
        playerId: 'g-12345',
        displayName: 'Bob',
      );
      final json = identity.toJson();
      expect(json['platform'], 'android');
      expect(json['playerId'], 'g-12345');
      expect(json['displayName'], 'Bob');
    });

    test('toJson contains exactly three keys', () {
      const identity = GamePlatformIdentity(
        platform: 'ios',
        playerId: 'p',
        displayName: 'd',
      );
      expect(identity.toJson().keys.toSet(), {'platform', 'playerId', 'displayName'});
    });

    test('two identical identities have equal toJson output', () {
      const a = GamePlatformIdentity(platform: 'ios', playerId: 'x', displayName: 'X');
      const b = GamePlatformIdentity(platform: 'ios', playerId: 'x', displayName: 'X');
      expect(a.toJson(), b.toJson());
    });
  });

  // -------------------------------------------------------------------------
  // GamePlatformAuthService — signInSilently
  // -------------------------------------------------------------------------

  group('GamePlatformAuthService.signInSilently()', () {
    test('returns null in test environment (GamesServices throws)', () async {
      // In the unit-test environment the games_services plugin is not registered,
      // so GamesServices.signIn() throws MissingPluginException.
      // The service must swallow that and return null.
      final svc = GamePlatformAuthService();
      final result = await svc.signInSilently();
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // GamePlatformAuthService — isSignedIn
  // -------------------------------------------------------------------------

  group('GamePlatformAuthService.isSignedIn()', () {
    test('returns false in test environment (GamesServices throws)', () async {
      final svc = GamePlatformAuthService();
      final result = await svc.isSignedIn();
      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // GamePlatformAuthService — currentPlatform
  // -------------------------------------------------------------------------

  group('GamePlatformAuthService.currentPlatform', () {
    test('returns a non-empty string', () {
      final svc = GamePlatformAuthService();
      expect(svc.currentPlatform, isNotEmpty);
    });

    test('returns one of the two known platform labels', () {
      final svc = GamePlatformAuthService();
      expect(svc.currentPlatform, anyOf('ios', 'android'));
    });
  });
}
