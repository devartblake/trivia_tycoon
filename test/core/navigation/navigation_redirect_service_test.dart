import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/navigation/canonical_routes.dart';
import 'package:synaptix/core/navigation/navigation_redirect_service.dart';
import 'package:synaptix/game/providers/auth_providers.dart';
import 'package:synaptix/game/providers/onboarding_providers.dart'
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
        'anonymous incomplete users resume onboarding (guests may play), '
        'and onboarding itself is allowed', () {
      final container = _container(
        identity: _anonymousIdentity,
        onboardingComplete: false,
      );
      addTearDown(container.dispose);

      final service = container.read(navigationRedirectServiceProvider);

      // A playable (anonymous/guest) identity with incomplete onboarding is
      // routed into onboarding rather than bounced to login.
      expect(
        service.determineRedirect(canonicalSettingsRoute),
        canonicalOnboardingRoute,
      );
      expect(service.determineRedirect(canonicalOnboardingRoute), isNull);
    });

    test('anonymous device with a session resumes onboarding, not home', () {
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
        canonicalOnboardingRoute,
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
