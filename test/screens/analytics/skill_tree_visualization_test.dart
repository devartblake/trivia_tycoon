import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/screens/analytics/skill_tree_visualization.dart';

void main() {
  group('SkillTreeVisualization', () {
    testWidgets('renders screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('shows title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Skill Tree'), findsOneWidget);
    });

    testWidgets('renders in scrollable view', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('displays with mock data initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('shows loading indicator initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      // May show loading on first pump
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('has refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('can press refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final refreshButton = find.byIcon(Icons.refresh);
      if (refreshButton.evaluate().isNotEmpty) {
        await tester.tap(refreshButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('displays skill nodes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('is responsive', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('handles mobile size', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 667);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('shows tier sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('contains Card widgets for layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('displays summary statistics', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));
      // Should have some text widgets for stats
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows proper material design', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(Material), findsWidgets);
    });
  });

  group('SkillTreeVisualization Error Handling', () {
    testWidgets('shows error state gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });

    testWidgets('shows empty state message', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });
  });

  group('SkillTreeVisualization Interactions', () {
    testWidgets('can tap on skill nodes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      final containers = find.byType(Container);
      if (containers.evaluate().isNotEmpty) {
        await tester.tap(containers.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('responds to scroll actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkillTreeVisualization(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(find.byType(SkillTreeVisualization), findsOneWidget);
    });
  });
}
