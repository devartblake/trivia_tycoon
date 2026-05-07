import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/game/controllers/skill_tree_controller.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';
import 'package:trivia_tycoon/game/providers/skill_tree_provider.dart';
import 'package:trivia_tycoon/game/providers/xp_provider.dart';
import 'package:trivia_tycoon/screens/skills_tree/skill_branch_detail_screen.dart';
import 'package:trivia_tycoon/ui_components/hex_grid/paint/auto_path_overlay_painter.dart';

class _StaticSkillTreeController extends SkillTreeController {
  _StaticSkillTreeController(Ref ref, SkillTreeState initial)
      : super(
          ref,
          initialGraph: initial.graph,
          startingPoints: initial.playerPoints,
        ) {
    state = initial;
  }
}

SkillTreeState _stateWithScholarBranch() {
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
      nodes: [root, mid],
      edges: [SkillEdge(fromId: 'scholar_root', toId: 'scholar_mid')],
    ),
    positions: {
      'scholar_root': Offset(-40, 0),
      'scholar_mid': Offset(40, 0),
    },
    playerPoints: 0,
  );
}

Widget _buildHarness({required SkillTreeState state, required String location}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/skill-branch/:branchId',
        builder: (context, routeState) => SkillBranchDetailScreen(
          branchId: routeState.pathParameters['branchId']!,
          initialStep: int.tryParse(routeState.uri.queryParameters['step'] ?? ''),
          showPathInitially: routeState.uri.queryParameters['showPath'] == '1',
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      skillTreeProvider.overrideWith(
          (ref) => _StaticSkillTreeController(ref, state)),
      playerXPProvider.overrideWith((_) => 100),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('keeps empty branch state without action bar and path data',
      (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        state: _stateWithScholarBranch(),
        location: '/skill-branch/unknown?step=0&showPath=1',
      ),
    );
    await tester.pumpAndSettle();

    final overlayPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<AutoPathOverlayPainter>()
        .single;

    final actionBarStepFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data != null &&
          RegExp(r'^Step \d+ / \d+$').hasMatch(widget.data!),
    );

    expect(actionBarStepFinder, findsNothing);
    expect(overlayPainter.pathIds, isEmpty);
  });

  testWidgets('hydrates overlay path data from deep-link query params',
      (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        state: _stateWithScholarBranch(),
        location: '/skill-branch/scholar?step=1&showPath=1',
      ),
    );
    await tester.pumpAndSettle();

    final overlayPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<AutoPathOverlayPainter>()
        .single;

    expect(find.textContaining('Step 2 / 2'), findsOneWidget);
    expect(overlayPainter.pathIds, ['scholar_root', 'scholar_mid']);
    expect(overlayPainter.currentIndex, 1);
    expect(overlayPainter.showFullPath, isTrue);
  });
}
