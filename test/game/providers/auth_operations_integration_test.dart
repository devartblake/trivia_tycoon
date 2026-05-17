import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/game_platform_auth_service.dart';
import 'package:trivia_tycoon/game/providers/auth_providers.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _NullGamePlatformService extends GamePlatformAuthService {
  @override
  Future<GamePlatformIdentity?> signInSilently() async => null;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Provider initial state
  // -------------------------------------------------------------------------

  group('AuthOperations — provider initial state', () {
    test('isLoggedInSyncProvider starts as false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(isLoggedInSyncProvider), isFalse);
    });

    test('profileSelectedProvider starts as false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(profileSelectedProvider), isFalse);
    });

    test('isLoggedInSyncProvider can be set to true via notifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(isLoggedInSyncProvider.notifier).state = true;
      expect(container.read(isLoggedInSyncProvider), isTrue);
    });

    test('profileSelectedProvider can be set to true via notifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(profileSelectedProvider.notifier).state = true;
      expect(container.read(profileSelectedProvider), isTrue);
    });

    test('two containers have independent isLoggedInSyncProvider state', () {
      final c1 = ProviderContainer();
      final c2 = ProviderContainer();
      addTearDown(c1.dispose);
      addTearDown(c2.dispose);
      c1.read(isLoggedInSyncProvider.notifier).state = true;
      expect(c2.read(isLoggedInSyncProvider), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // trySilentGameLogin
  // -------------------------------------------------------------------------

  group('AuthOperations.trySilentGameLogin', () {
    test('returns false when game platform silent sign-in returns null', () async {
      final container = ProviderContainer(
        overrides: [
          gamePlatformAuthServiceProvider
              .overrideWithValue(_NullGamePlatformService()),
        ],
      );
      addTearDown(container.dispose);

      final authOps = container.read(authOperationsProvider);
      final result = await authOps.trySilentGameLogin();
      expect(result, isFalse);
    });

    test('isLoggedInSyncProvider is still false after failed silent sign-in',
        () async {
      final container = ProviderContainer(
        overrides: [
          gamePlatformAuthServiceProvider
              .overrideWithValue(_NullGamePlatformService()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authOperationsProvider).trySilentGameLogin();
      expect(container.read(isLoggedInSyncProvider), isFalse);
    });
  });
}
