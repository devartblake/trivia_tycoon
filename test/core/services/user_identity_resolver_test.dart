import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/user_identity_resolver.dart';

void main() {
  group('UserIdentityResolver.resolveUserIdFromSources', () {
    late Map<String, String> secure;
    late String? profileUserId;

    setUp(() {
      secure = <String, String>{};
      profileUserId = null;
      UserIdentityResolver.resetWarningForTests();
    });

    Future<String> resolve({
      String? tokenStoreUserId,
      Future<void> Function(String previousId, String canonicalId)? onCanonicalPromotion,
    }) {
      return UserIdentityResolver.resolveUserIdFromSources(
        getProfileUserId: () async => profileUserId,
        saveProfileUserId: (id) async {
          profileUserId = id;
        },
        getSecureSecret: (key) async => secure[key],
        setSecureSecret: (key, value) async {
          secure[key] = value;
        },
        readAuthTokenStoreUserId: () => tokenStoreUserId,
        seedNowIso: () => '2026-01-01T00:00:00.000Z',
        onCanonicalPromotion: onCanonicalPromotion,
      );
    }

    test('returns profile id when available', () async {
      profileUserId = 'profile-123';

      final resolved = await resolve(tokenStoreUserId: 'token-1');

      expect(resolved, 'profile-123');
    });

    test('promotes canonical secure id over generated local profile id', () async {
      profileUserId = 'local_generated_profile';
      secure['user_id'] = 'backend-123';

      String? previousId;
      String? canonicalId;

      final resolved = await resolve(
        onCanonicalPromotion: (previous, canonical) async {
          previousId = previous;
          canonicalId = canonical;
        },
      );

      expect(resolved, 'backend-123');
      expect(profileUserId, 'backend-123');
      expect(previousId, 'local_generated_profile');
      expect(canonicalId, 'backend-123');
    });

    test('promotes canonical token id over generated local ids', () async {
      profileUserId = 'local_profile';
      secure['user_id'] = 'local_secure';

      final resolved = await resolve(tokenStoreUserId: 'backend-token-9');

      expect(resolved, 'backend-token-9');
      expect(profileUserId, 'backend-token-9');
      expect(secure['user_id'], 'backend-token-9');
    });

    test('falls back to secure user_id and backfills profile', () async {
      secure['user_id'] = 'secure-456';

      final resolved = await resolve();

      expect(resolved, 'secure-456');
      expect(profileUserId, 'secure-456');
    });

    test('falls back to token store id and persists to secure/profile', () async {
      final resolved = await resolve(tokenStoreUserId: 'token-789');

      expect(resolved, 'token-789');
      expect(secure['user_id'], 'token-789');
      expect(profileUserId, 'token-789');
    });

    test('uses existing generated local id when present', () async {
      secure['generated_local_user_id'] = 'local_existing';

      final resolved = await resolve();

      expect(resolved, 'local_existing');
      expect(profileUserId, 'local_existing');
    });

    test('generates deterministic local fallback from email seed', () async {
      secure['user_email'] = 'PlayerOne@Example.com';

      final resolved = await resolve();

      expect(resolved.startsWith('local_'), isTrue);
      expect(secure['generated_local_user_id'], resolved);
      expect(profileUserId, resolved);
    });
  });

  group('UserIdentityResolver.resolveUserNameFromValues', () {
    test('prefers explicit username and lowercases it', () {
      final resolved = UserIdentityResolver.resolveUserNameFromValues(
        username: 'My_User',
        playerName: 'Display Name',
      );

      expect(resolved, 'my_user');
    });

    test('falls back to non-default player name', () {
      final resolved = UserIdentityResolver.resolveUserNameFromValues(
        username: null,
        playerName: 'Display Name',
      );

      expect(resolved, 'Display Name');
    });

    test('generates fallback when only default Player exists', () {
      final resolved = UserIdentityResolver.resolveUserNameFromValues(
        username: null,
        playerName: 'Player',
      );

      expect(resolved, 'player');
    });
  });
}
