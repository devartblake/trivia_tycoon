import 'package:flutter/material.dart';

const canonicalHomeRoute = '/home';
const canonicalLoginRoute = '/login';
const canonicalRegisterRoute = '/register';
const canonicalOnboardingRoute = '/onboarding';
const canonicalAccountLinkRoute = '/account-link';
const canonicalPlayRoute = '/quiz';
const canonicalArenaRoute = '/leaderboard';
const canonicalLabsRoute = '/arcade';
const canonicalJourneyRoute = '/profile';
const canonicalRewardsRoute = '/rewards';
const canonicalStoreRoute = '/store-hub';
const canonicalMessagesRoute = '/messages';
const canonicalSettingsRoute = '/settings';

const canonicalPrimaryNavRoutes = <CanonicalNavDestination>[
  CanonicalNavDestination(
    label: 'Home',
    icon: Icons.home_rounded,
    route: canonicalHomeRoute,
  ),
  CanonicalNavDestination(
    label: 'Play',
    icon: Icons.quiz_rounded,
    route: canonicalPlayRoute,
  ),
  CanonicalNavDestination(
    label: 'Arena',
    icon: Icons.leaderboard_rounded,
    route: canonicalArenaRoute,
  ),
  CanonicalNavDestination(
    label: 'Labs',
    icon: Icons.science_rounded,
    route: canonicalLabsRoute,
  ),
  CanonicalNavDestination(
    label: 'Journey',
    icon: Icons.person_rounded,
    route: canonicalJourneyRoute,
  ),
];

const canonicalRouteAliases = <String, String>{
  '/main': canonicalHomeRoute,
  '/auth': canonicalLoginRoute,
  '/signup': canonicalRegisterRoute,
  '/profile-setup': canonicalOnboardingRoute,
  '/play': '/quiz/start/classic',
  '/2048': '/game-2048',
  '/sudoku': '/sudoku-puzzle',
  '/nonogram': '/mini-games',
  '/anagram': '/mini-games',
  '/simon-says': '/mini-games',
  '/chess-puzzle': '/mini-games',
  '/avatar-select': '/avatar-selection',
  '/quiz/random': '/quiz/start/classic',
  '/quiz/daily': '/daily-quiz',
  '/quiz/create': '/create-quiz',
};

class CanonicalNavDestination {
  final String label;
  final IconData icon;
  final String route;

  const CanonicalNavDestination({
    required this.label,
    required this.icon,
    required this.route,
  });
}
