import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/navigation/navigation_redirect_service.dart';
import 'package:trivia_tycoon/game/providers/onboarding_providers.dart';

void main() {
  group('NavigationRedirectService.resolveOnboardingRedirect', () {
    test('logged-out users are redirected to login from protected paths', () {
      final redirect = NavigationRedirectService.resolveOnboardingRedirect(
        currentPath: '/home',
        isLoggedIn: false,
        phase: OnboardingPhase.intro,
      );

      expect(redirect, '/login');
    });

    test('logged-out users can access login/signup', () {
      expect(
        NavigationRedirectService.resolveOnboardingRedirect(
          currentPath: '/login',
          isLoggedIn: false,
          phase: OnboardingPhase.intro,
        ),
        isNull,
      );

      expect(
        NavigationRedirectService.resolveOnboardingRedirect(
          currentPath: '/signup',
          isLoggedIn: false,
          phase: OnboardingPhase.intro,
        ),
        isNull,
      );
    });

    test('onboarding users are forced into onboarding routes', () {
      final redirect = NavigationRedirectService.resolveOnboardingRedirect(
        currentPath: '/home',
        isLoggedIn: true,
        phase: OnboardingPhase.profileSetup,
      );

      expect(redirect, '/onboarding');
    });

    test('completed users are redirected away from onboarding-only routes', () {
      final redirect = NavigationRedirectService.resolveOnboardingRedirect(
        currentPath: '/onboarding',
        isLoggedIn: true,
        phase: OnboardingPhase.done,
      );

      expect(redirect, '/home');
    });

    test('completed users can access non-onboarding routes', () {
      final redirect = NavigationRedirectService.resolveOnboardingRedirect(
        currentPath: '/leaderboard',
        isLoggedIn: true,
        phase: OnboardingPhase.done,
      );

      expect(redirect, isNull);
    });
  });
}
