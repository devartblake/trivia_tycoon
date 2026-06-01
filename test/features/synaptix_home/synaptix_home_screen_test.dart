import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/navigation/canonical_routes.dart';
import 'package:trivia_tycoon/features/synaptix_home/models/synaptix_home_state.dart';
import 'package:trivia_tycoon/features/synaptix_home/providers/synaptix_home_provider.dart';
import 'package:trivia_tycoon/features/synaptix_home/screens/synaptix_home_screen.dart';
import 'package:trivia_tycoon/features/synaptix_home/theme/synaptix_home_theme.dart';

void main() {
  testWidgets('wide layout renders rail, main dashboard, and right panel',
      (tester) async {
    await _pumpHome(tester, const Size(1280, 900));

    expect(find.text('SYNAPTIX'), findsOneWidget);
    expect(find.text('CURRENT RANK'), findsOneWidget);
    expect(find.text('SYNAPTIX\nARENA CUP'), findsOneWidget);
    expect(find.text('DAILY MISSIONS'), findsOneWidget);
    expect(find.text('LEADERBOARD'), findsOneWidget);
    expect(find.text('FRIENDS ONLINE (2)'), findsOneWidget);
    expect(find.text('SYNAPTIX NEWS'), findsOneWidget);
    expect(find.text('DAILY REWARD'), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsNothing);
  });

  testWidgets('medium layout renders stacked dashboard sections',
      (tester) async {
    await _pumpHome(tester, const Size(900, 900));

    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
    expect(find.text('CURRENT RANK'), findsNothing);
    expect(find.text('FRIENDS ONLINE (2)'), findsOneWidget);
    expect(find.text('CHOOSE YOUR MODE'), findsOneWidget);
    expect(find.text('RECENT PLAY'), findsOneWidget);
    expect(find.text('LEADERBOARD'), findsOneWidget);
    expect(find.text('SYNAPTIX NEWS'), findsOneWidget);
    expect(find.text('DAILY REWARD'), findsOneWidget);
  });

  testWidgets('narrow layout renders compact single-column dashboard',
      (tester) async {
    await _pumpHome(tester, const Size(390, 900));

    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('SYNAPTIX\nARENA CUP'), findsOneWidget);
    expect(find.text('DAILY MISSIONS'), findsOneWidget);
    expect(find.text('SYNAPTIX NEWS'), findsOneWidget);
    expect(find.text('DAILY REWARD'), findsOneWidget);
  });

  testWidgets('medium drawer opens with Synaptix rail navigation',
      (tester) async {
    await _pumpHome(tester, const Size(900, 900));

    await _openHomeDrawer(tester);

    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('STORE'), findsOneWidget);
    expect(find.text('REWARDS'), findsOneWidget);
    expect(find.text('SKILL TREE'), findsOneWidget);
    expect(find.text('ARCADE'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('CURRENT RANK'), findsOneWidget);
  });

  testWidgets('narrow drawer opens while compact quick nav remains',
      (tester) async {
    await _pumpHome(tester, const Size(390, 900));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);

    await _openHomeDrawer(tester);

    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('CURRENT RANK'), findsOneWidget);
  });

  testWidgets('wide footer stays fixed while the dashboard scrolls',
      (tester) async {
    await _pumpHome(tester, const Size(1280, 900));

    final before = tester.getTopLeft(find.text('SYNAPTIX NEWS')).dy;
    await tester.drag(
      find.byKey(const Key('synaptix-main-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    final after = tester.getTopLeft(find.text('SYNAPTIX NEWS')).dy;
    expect(after, closeTo(before, 1));
  });

  testWidgets('primary CTAs navigate to canonical routes', (tester) async {
    final router = await _pumpHome(tester, const Size(1280, 900));

    await _expectTapRoute(tester, router, 'PLAY', '/quiz');
    await _expectTapRoute(tester, router, 'ARENA', canonicalArenaRoute);
    await _expectTapRoute(tester, router, 'LABS', canonicalLabsRoute);
    await _expectTapRoute(tester, router, 'JOURNEY', canonicalJourneyRoute);
    await _expectTapRoute(
      tester,
      router,
      'REWARDS',
      canonicalRewardsRoute,
      useLastMatch: true,
    );
    await _expectTapRoute(tester, router, 'STORE', canonicalStoreRoute);

    await _expectTooltipRoute(
      tester,
      router,
      'Messages',
      canonicalMessagesRoute,
    );
    await _expectTooltipRoute(
      tester,
      router,
      'Settings',
      canonicalSettingsRoute,
    );
    await _expectTapRoute(tester, router, 'SYNAPTIX NEWS', canonicalLabsRoute);
    await _expectTapRoute(
      tester,
      router,
      'DAILY REWARD',
      canonicalRewardsRoute,
    );
  });

  testWidgets('drawer CTAs navigate to canonical routes', (tester) async {
    final router = await _pumpHome(tester, const Size(900, 900));

    await _expectDrawerRoute(tester, router, 'DASHBOARD', canonicalHomeRoute);
    await _expectDrawerRoute(tester, router, 'PROFILE', canonicalJourneyRoute);
    await _expectDrawerRoute(tester, router, 'STORE', canonicalStoreRoute);
    await _expectDrawerRoute(tester, router, 'REWARDS', canonicalRewardsRoute);
    await _expectDrawerRoute(tester, router, 'SKILL TREE', '/skills');
    await _expectDrawerRoute(tester, router, 'ARCADE', canonicalLabsRoute);
    await _expectDrawerRoute(tester, router, 'SETTINGS', canonicalSettingsRoute);
  });
}

Future<GoRouter> _pumpHome(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = _router();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        synaptixHomeProvider.overrideWith((ref) async => _homeState),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

GoRouter _router() {
  Widget routeScreen(String route) => Scaffold(body: Text('route:$route'));

  return GoRouter(
    initialLocation: canonicalHomeRoute,
    routes: [
      GoRoute(
        path: canonicalHomeRoute,
        builder: (context, state) => const SynaptixHomeScreen(),
      ),
      GoRoute(
        path: '/quiz',
        builder: (context, state) => routeScreen('/quiz'),
      ),
      GoRoute(
        path: canonicalArenaRoute,
        builder: (context, state) => routeScreen(canonicalArenaRoute),
      ),
      GoRoute(
        path: canonicalLabsRoute,
        builder: (context, state) => routeScreen(canonicalLabsRoute),
      ),
      GoRoute(
        path: canonicalJourneyRoute,
        builder: (context, state) => routeScreen(canonicalJourneyRoute),
      ),
      GoRoute(
        path: canonicalRewardsRoute,
        builder: (context, state) => routeScreen(canonicalRewardsRoute),
      ),
      GoRoute(
        path: canonicalStoreRoute,
        builder: (context, state) => routeScreen(canonicalStoreRoute),
      ),
      GoRoute(
        path: canonicalMessagesRoute,
        builder: (context, state) => routeScreen(canonicalMessagesRoute),
      ),
      GoRoute(
        path: canonicalSettingsRoute,
        builder: (context, state) => routeScreen(canonicalSettingsRoute),
      ),
      GoRoute(
        path: '/skills',
        builder: (context, state) => routeScreen('/skills'),
      ),
      GoRoute(
        path: '/invite',
        builder: (context, state) => routeScreen('/invite'),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => routeScreen('/onboarding'),
      ),
      GoRoute(
        path: '/quiz/start/classic',
        builder: (context, state) => routeScreen('/quiz/start/classic'),
      ),
    ],
  );
}

Future<void> _expectTapRoute(
  WidgetTester tester,
  GoRouter router,
  String label,
  String route, {
  bool useLastMatch = false,
}) async {
  final finder = useLastMatch ? find.text(label).last : find.text(label).first;
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(find.text('route:$route'), findsOneWidget);
  router.go(canonicalHomeRoute);
  await tester.pumpAndSettle();
}

Future<void> _expectTooltipRoute(
  WidgetTester tester,
  GoRouter router,
  String tooltip,
  String route,
) async {
  await tester.tap(find.byTooltip(tooltip).first);
  await tester.pumpAndSettle();
  expect(find.text('route:$route'), findsOneWidget);
  router.go(canonicalHomeRoute);
  await tester.pumpAndSettle();
}

Future<void> _openHomeDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
}

Future<void> _expectDrawerRoute(
  WidgetTester tester,
  GoRouter router,
  String label,
  String route,
) async {
  await _openHomeDrawer(tester);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();

  if (route == canonicalHomeRoute) {
    expect(
      router.routeInformationProvider.value.uri.path,
      canonicalHomeRoute,
    );
  } else {
    expect(find.text('route:$route'), findsOneWidget);
    router.go(canonicalHomeRoute);
    await tester.pumpAndSettle();
  }
}

const _homeState = SynaptixHomeState(
  player: SynaptixHomePlayer(
    displayName: 'Hanzo',
    handle: 'hanzo',
    title: 'Trivia Strategist',
    level: 12,
    currentXp: 420,
    targetXp: 1000,
    coins: 1200,
    gems: 75,
    wins: 8,
    matches: 12,
    rank: 24,
    streak: 3,
    bestStreak: 7,
    rating: 1840,
    rankTier: 'Scholar III',
    preferredCategories: ['Science', 'History'],
  ),
  primaryActions: [
    SynaptixHomeAction(
      icon: Icons.flash_on_rounded,
      title: 'Quick Quiz',
      subtitle: 'Jump into a classic round.',
      route: '/quiz/start/classic',
      color: SynaptixHomeTheme.blue,
    ),
    SynaptixHomeAction(
      icon: Icons.leaderboard_rounded,
      title: 'Arena',
      subtitle: 'Check ranks and competition.',
      route: canonicalArenaRoute,
      color: SynaptixHomeTheme.purple,
    ),
    SynaptixHomeAction(
      icon: Icons.science_rounded,
      title: 'Labs',
      subtitle: 'Arcade challenges and bonuses.',
      route: canonicalLabsRoute,
      color: SynaptixHomeTheme.green,
    ),
    SynaptixHomeAction(
      icon: Icons.person_rounded,
      title: 'Journey',
      subtitle: 'Profile, progress, and identity.',
      route: canonicalJourneyRoute,
      color: SynaptixHomeTheme.amber,
    ),
  ],
  missions: [
    SynaptixHomeMission(
      title: 'Play 3 quiz rounds',
      current: 1,
      target: 3,
      rewardCoins: 150,
      icon: Icons.quiz_rounded,
    ),
    SynaptixHomeMission(
      title: 'Pick favorite categories',
      current: 2,
      target: 3,
      rewardCoins: 100,
      icon: Icons.category_rounded,
    ),
  ],
  leaderboard: [
    SynaptixHomeLeaderboardEntry(
        rank: 1, username: 'Daily Champion', score: 3200),
    SynaptixHomeLeaderboardEntry(
      rank: 24,
      username: 'hanzo',
      score: 1840,
      isCurrentUser: true,
    ),
  ],
  recentActivity: [
    SynaptixRecentActivity(
        title: 'Science Trivia', score: '85%', date: 'Today'),
  ],
  recommendations: [
    SynaptixRecommendation(
      icon: Icons.auto_awesome_rounded,
      title: 'Science practice',
      subtitle: 'Keep momentum in your focus area.',
      route: '/quiz/start/classic',
    ),
  ],
  achievements: [
    SynaptixAchievement(
      icon: Icons.workspace_premium_rounded,
      title: 'Level 12',
      subtitle: 'Current rank',
    ),
    SynaptixAchievement(
      icon: Icons.category_rounded,
      title: '2',
      subtitle: 'Focus areas',
    ),
  ],
  featuredEvent: SynaptixFeaturedEvent(
    icon: Icons.auto_awesome_rounded,
    title: 'Weekend Showdown',
    subtitle: 'Double XP and exclusive rewards this weekend only.',
    timeRemaining: '1d 14h left',
    route: canonicalArenaRoute,
  ),
  newsItem: SynaptixNewsItem(
    title: 'Synaptix news',
    body: 'New arcade challenges are rolling out.',
    route: canonicalLabsRoute,
  ),
  dailyReward: SynaptixRewardPrompt(
    title: 'Daily reward',
    body: '2 account rewards waiting.',
    route: canonicalRewardsRoute,
    icon: Icons.card_giftcard_rounded,
  ),
  friends: [
    SynaptixFriendPreview(initials: 'A', color: SynaptixHomeTheme.purple),
    SynaptixFriendPreview(initials: 'B', color: SynaptixHomeTheme.blue),
  ],
  profileIncomplete: false,
  remainingAccountRewards: 2,
);
