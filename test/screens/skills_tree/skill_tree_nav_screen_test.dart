import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/core/services/event_queue_service.dart';
import 'package:trivia_tycoon/game/analytics/providers/analytics_providers.dart';
import 'package:trivia_tycoon/game/analytics/services/analytics_service.dart';
import 'package:trivia_tycoon/game/controllers/skill_tree_controller.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';
import 'package:trivia_tycoon/game/providers/skill_tree_nav_providers.dart';
import 'package:trivia_tycoon/game/providers/skill_tree_provider.dart';
import 'package:trivia_tycoon/game/providers/xp_provider.dart';
import 'package:trivia_tycoon/screens/skills_tree/skill_tree_nav_screen.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode_notifier.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode_provider.dart';

class _StaticSkillTreeController extends SkillTreeController {
  _StaticSkillTreeController(super.ref, SkillTreeState initial)
      : super(
          initialGraph: initial.graph,
          startingPoints: initial.playerPoints,
        ) {
    state = initial;
  }
}

class _NoopAnalyticsService extends AnalyticsService {
  _NoopAnalyticsService()
      : super(
          ApiService(baseUrl: 'https://example.test', initializeCache: false),
          EventQueueService(),
        );

  @override
  Future<void> trackEvent(String eventName, Map<String, dynamic> data) async {}
}

SkillTreeState _testSkillTreeState() {
  final root = SkillNode(
    id: 'scholar_root',
    title: 'Scholar Root',
    description: 'start',
    tier: 0,
    cost: 1,
    category: SkillCategory.scholar,
    effects: const {},
    branchId: 'scholar',
    available: true,
  );
  final mid = SkillNode(
    id: 'scholar_mid',
    title: 'Scholar Mid',
    description: 'next',
    tier: 1,
    cost: 2,
    category: SkillCategory.scholar,
    effects: const {},
    branchId: 'scholar',
  );

  return SkillTreeState(
    graph: SkillTreeGraph(
      nodes: [
        root,
        mid,
      ],
      edges: [
        SkillEdge(fromId: 'scholar_root', toId: 'scholar_mid'),
      ],
    ),
    positions: const {
      'scholar_root': Offset(0, 0),
      'scholar_mid': Offset(120, 0),
    },
    playerPoints: 0,
  );
}

Widget _buildHarness() {
  final router = GoRouter(
    initialLocation: '/skills',
    routes: [
      GoRoute(
        path: '/skills',
        builder: (_, __) => const SkillTreeNavScreen(),
      ),
      GoRoute(
        path: '/skill-branch/:branchId',
        builder: (context, state) {
          return Scaffold(
            body: Text(
              'route=${state.uri.toString()} branch=${state.pathParameters['branchId']} step=${state.uri.queryParameters['step']} showPath=${state.uri.queryParameters['showPath']}',
            ),
          );
        },
      ),
    ],
  );

  final sections = [
    const SkillTreeNavSectionMeta(
      id: 'combat_focused',
      title: 'Combat',
      branches: [
        SkillTreeNavBranchCardMeta(
          id: 'scholar',
          title: 'Scholar',
          colorHex: '#4A90E2',
          branchCount: 2,
        ),
      ],
    ),
    const SkillTreeNavSectionMeta(
      id: 'enhancement_branches',
      title: 'Enhancement',
      branches: [],
    ),
    const SkillTreeNavSectionMeta(
      id: 'utility_branches',
      title: 'Utility',
      branches: [],
    ),
    const SkillTreeNavSectionMeta(
      id: 'advanced_branches',
      title: 'Advanced',
      branches: [],
    ),
  ];

  return ProviderScope(
    overrides: [
      analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
      synaptixModeProvider
          .overrideWith((_) => SynaptixModeNotifier(PlayerProfileService())),
      skillTreeProvider.overrideWith(
          (ref) => _StaticSkillTreeController(ref, _testSkillTreeState())),
      skillTreeNavSectionsProvider.overrideWith((_) => sections),
      playerXPProvider.overrideWith((_) => 50),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets(
      'route icon deep-links to branch detail with step=0 and showPath=1',
      (tester) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    final deepLinkIconFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Scholar Root'),
        matching: find.byType(Material),
      ),
      matching: find.byIcon(Icons.alt_route),
    );

    await tester.tap(deepLinkIconFinder);
    await tester.pumpAndSettle();

    expect(find.textContaining('/skill-branch/scholar?step=0&showPath=1'),
        findsOneWidget);
    expect(find.textContaining('step=0 showPath=1'), findsOneWidget);
  });

  testWidgets('auto-path preview toggle controls showPath query value',
      (tester) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Auto-path').first);
    await tester.pumpAndSettle();

    expect(find.text('Auto-Path Preview'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Auto-Path'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/skill-branch/scholar?step=0&showPath=0'),
        findsOneWidget);
    expect(find.textContaining('step=0 showPath=0'), findsOneWidget);
  });
}
