import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/navigation/canonical_routes.dart';
import 'package:synaptix/screens/login_screen.dart';
import 'package:synaptix/screens/login_screen_mobile.dart';

void main() {
  group('canonical navigation routes', () {
    test('primary destinations use the home dashboard flow', () {
      expect(
        canonicalPrimaryNavRoutes.map((item) => item.route),
        [
          canonicalHomeRoute,
          canonicalPlayRoute,
          canonicalArenaRoute,
          canonicalLabsRoute,
          canonicalJourneyRoute,
        ],
      );
    });

    test('legacy and prototype route aliases point at registered routes', () {
      expect(canonicalRouteAliases['/main'], canonicalHomeRoute);
      expect(canonicalRouteAliases['/auth'], canonicalLoginRoute);
      expect(canonicalRouteAliases['/signup'], canonicalRegisterRoute);
      expect(canonicalRouteAliases['/profile-setup'], canonicalOnboardingRoute);
      expect(canonicalRouteAliases['/play'], '/quiz/start/classic');
      expect(canonicalRouteAliases['/2048'], '/game-2048');
      expect(canonicalRouteAliases['/sudoku'], '/sudoku-puzzle');
      expect(canonicalRouteAliases['/quiz/daily'], '/daily-quiz');
      expect(canonicalRouteAliases['/quiz/create'], '/create-quiz');
    });

    test('dashboard utility destinations are explicit', () {
      expect(canonicalLoginRoute, '/login');
      expect(canonicalRegisterRoute, '/register');
      expect(canonicalOnboardingRoute, '/onboarding');
      expect(canonicalAccountLinkRoute, '/account-link');
      expect(canonicalRewardsRoute, '/rewards');
      expect(canonicalStoreRoute, '/store-hub');
      expect(canonicalMessagesRoute, '/messages');
      expect(canonicalSettingsRoute, '/settings');
    });

    test('login screens advertise the canonical login route', () {
      expect(LoginScreen.routeName, canonicalLoginRoute);
      expect(LoginScreenMobile.routeName, canonicalLoginRoute);
    });
  });
}
