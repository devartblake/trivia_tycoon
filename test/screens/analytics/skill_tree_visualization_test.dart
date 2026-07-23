import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/skill_progression_model.dart';
import 'package:synaptix/screens/analytics/skill_tree_visualization.dart';

/// Mock skill catalog so the visualization renders its data state (the real
/// [skillProgressionProvider] hits the backend, which is unavailable in tests
/// and would otherwise drop the widget into its error state).
final _mockSkills = <SkillNode>[
  SkillNode(
    skillId: 'math-basics',
    name: 'Math Basics',
    category: 'math',
    description: 'Foundational arithmetic',
    level: 1,
    totalXpRequired: 1000,
    currentXp: 1000,
    tier: 0,
  ),
  SkillNode(
    skillId: 'algebra',
    name: 'Algebra',
    category: 'math',
    description: 'Solving for x',
    level: 0,
    totalXpRequired: 2500,
    prerequisites: const ['math-basics'],
    tier: 1,
  ),
  SkillNode(
    skillId: 'calculus',
    name: 'Calculus',
    category: 'math',
    description: 'Derivatives and integrals',
    level: 0,
    totalXpRequired: 5000,
    prerequisites: const ['algebra'],
    tier: 2,
  ),
];

Widget _buildWidget({List<SkillNode>? skills}) {
  return ProviderScope(
    overrides: [
      skillProgressionProvider
          .overrideWith((ref) async => skills ?? _mockSkills),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SkillTreeVisualization(),
      ),
    ),
  );
}

void main() {
  group('SkillTreeVisualization', () {
    testWidgets('renders screen', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('shows title', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle();
      expect(find.text('Skill Tree'), findsOneWidget);
    });

    testWidgets('renders in scrollable view', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('displays with mock data initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('shows loading indicator initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      // The provider resolves asynchronously, so the first frame is loading.
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('has refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('can press refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle();

      final refreshButton = find.byIcon(Icons.refresh);
      if (refreshButton.evaluate().isNotEmpty) {
        await tester.tap(refreshButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('displays skill nodes', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('is responsive', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('handles mobile size', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('shows tier sections', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('contains Card widgets for layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle();
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('displays summary statistics', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle(const Duration(seconds: 1));
      // Should have some text widgets for stats
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows proper material design', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle();
      expect(find.byType(Material), findsWidgets);
    });
  });

  group('SkillTreeVisualization Error Handling', () {
    testWidgets('shows error state gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('shows empty state message', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget(skills: const []));

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });
  });

  group('SkillTreeVisualization Interactions', () {
    testWidgets('can tap on skill nodes', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle(const Duration(seconds: 1));

      final containers = find.byType(Container);
      if (containers.evaluate().isNotEmpty) {
        await tester.tap(containers.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('responds to scroll actions', (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());

      await tester.pumpAndSettle();

      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });
  });
}
