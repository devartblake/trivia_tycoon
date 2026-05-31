import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/navigation/canonical_routes.dart';

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
      expect(canonicalRouteAliases['/profile-setup'], '/onboarding');
      expect(canonicalRouteAliases['/play'], '/quiz/start/classic');
      expect(canonicalRouteAliases['/2048'], '/game-2048');
      expect(canonicalRouteAliases['/sudoku'], '/sudoku-puzzle');
      expect(canonicalRouteAliases['/quiz/daily'], '/daily-quiz');
      expect(canonicalRouteAliases['/quiz/create'], '/create-quiz');
    });

    test('dashboard utility destinations are explicit', () {
      expect(canonicalRewardsRoute, '/rewards');
      expect(canonicalStoreRoute, '/store-hub');
      expect(canonicalMessagesRoute, '/messages');
      expect(canonicalSettingsRoute, '/settings');
    });
  });
}
