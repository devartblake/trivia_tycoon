import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/navigation/canonical_routes.dart';
import 'package:trivia_tycoon/core/navigation/navigation_redirect_service.dart';
import 'package:trivia_tycoon/game/providers/auth_providers.dart';
import 'package:trivia_tycoon/game/providers/onboarding_providers.dart'
    show onboardingCompleteProvider;

void main() {
  group('NavigationRedirectService', () {
    test('first-run app routes redirect to login', () {
      final container = _container(
        identity: const PlayerIdentityState(isReady: false),
        onboardingComplete: false,
      );
      addTearDown(container.dispose);

      expect(
        container
            .read(navigationRedirectServiceProvider)
            .determineRedirect(canonicalHomeRoute),
        canonicalLoginRoute,
      );
    });

    test('login, register, and explicit onboarding are allowed on first run',
        () {
      final container = _container(
        identity: const PlayerIdentityState(isReady: false),
        onboardingComplete: false,
      );
      addTearDown(container.dispose);

      final service = container.read(navigationRedirectServiceProvider);

      expect(service.determineRedirect(canonicalLoginRoute), isNull);
      expect(service.determineRedirect(canonicalRegisterRoute), isNull);
      expect(service.determineRedirect('/auth'), isNull);
      expect(service.determineRedirect('/signup'), isNull);
      expect(service.determineRedirect(canonicalOnboardingRoute), isNull);
    });

    test(
        'anonymous incomplete users return to login unless entering onboarding',
        () {
      final container = _container(
        identity: _anonymousIdentity,
        onboardingComplete: false,
      );
      addTearDown(container.dispose);

      final service = container.read(navigationRedirectServiceProvider);

      expect(
        service.determineRedirect(canonicalSettingsRoute),
        canonicalLoginRoute,
      );
      expect(service.determineRedirect(canonicalOnboardingRoute), isNull);
    });

    test('anonymous device tokens do not bypass the login choice', () {
      final container = _container(
        isLoggedIn: true,
        identity: _anonymousIdentity,
        onboardingComplete: false,
      );
      addTearDown(container.dispose);

      expect(
        container
            .read(navigationRedirectServiceProvider)
            .determineRedirect(canonicalHomeRoute),
        canonicalLoginRoute,
      );
    });

    test('logged-in incomplete users route to onboarding', () {
      final container = _container(
        isLoggedIn: true,
        identity: _fullAccountIdentity,
        onboardingComplete: false,
      );
      addTearDown(container.dispose);

      expect(
        container
            .read(navigationRedirectServiceProvider)
            .determineRedirect(canonicalHomeRoute),
        canonicalOnboardingRoute,
      );
    });

    test('completed anonymous users can open home and settings', () {
      final container = _container(
        identity: _anonymousIdentity,
        onboardingComplete: true,
      );
      addTearDown(container.dispose);

      final service = container.read(navigationRedirectServiceProvider);

      expect(service.determineRedirect(canonicalHomeRoute), isNull);
      expect(service.determineRedirect(canonicalSettingsRoute), isNull);
    });

    test('completed users do not remain on onboarding', () {
      final container = _container(
        identity: _anonymousIdentity,
        onboardingComplete: true,
      );
      addTearDown(container.dispose);

      expect(
        container
            .read(navigationRedirectServiceProvider)
            .determineRedirect(canonicalOnboardingRoute),
        canonicalHomeRoute,
      );
    });

    test('logged-in multi-profile users route to profile selection', () {
      final container = _container(
        isLoggedIn: true,
        profileSelected: false,
        identity: _fullAccountIdentity,
        onboardingComplete: true,
      );
      addTearDown(container.dispose);

      expect(
        container
            .read(navigationRedirectServiceProvider)
            .determineRedirect(canonicalHomeRoute),
        '/profile-selection',
      );
    });
  });
}

const _anonymousIdentity = PlayerIdentityState(
  isReady: true,
  kind: PlayerIdentityKind.anonymousDevice,
  deviceId: 'device-1',
  deviceType: 'test',
);

const _fullAccountIdentity = PlayerIdentityState(
  isReady: true,
  kind: PlayerIdentityKind.fullAccount,
  deviceId: 'device-1',
  deviceType: 'test',
);

ProviderContainer _container({
  bool isLoggedIn = false,
  bool profileSelected = true,
  required bool onboardingComplete,
  required PlayerIdentityState identity,
}) {
  return ProviderContainer(
    overrides: [
      isLoggedInSyncProvider.overrideWith((ref) => isLoggedIn),
      profileSelectedProvider.overrideWith((ref) => profileSelected),
      onboardingCompleteProvider.overrideWith((ref) => onboardingComplete),
      playerIdentityProvider.overrideWith(
        (ref) => _FakePlayerIdentityNotifier(ref, identity),
      ),
    ],
  );
}

class _FakePlayerIdentityNotifier extends PlayerIdentityNotifier {
  _FakePlayerIdentityNotifier(super.ref, PlayerIdentityState initial) {
    state = initial;
  }

  @override
  Future<void> initialize() async {}
}
