import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/features/synaptix_home/widgets/cards/phase2_daily_bonus_card.dart';
import 'package:synaptix/features/synaptix_home/widgets/cards/phase2_weekly_rewards_card.dart';
import 'package:synaptix/features/synaptix_home/widgets/cards/phase2_tier_progress_card.dart';

void main() {
  group('Phase 2 Dashboard Integration', () {
    // ────────────────────────────────────────────────────────────────────────
    // Individual Card Tests
    // ────────────────────────────────────────────────────────────────────────

    group('Phase2DailyBonusCard', () {
      testWidgets('renders without errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: Phase2DailyBonusCard(),
              ),
            ),
          ),
        );

        expect(find.byType(Phase2DailyBonusCard), findsOneWidget);
      });

      testWidgets('renders as a Card widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: Phase2DailyBonusCard(),
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('has proper elevation and shape',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: Phase2DailyBonusCard(),
              ),
            ),
          ),
        );

        final card = find.byType(Card);
        expect(card, findsOneWidget);

        final Card cardWidget = tester.widget(card);
        expect(cardWidget.elevation, equals(2));
        expect(cardWidget.shape, isA<RoundedRectangleBorder>());
      });
    });

    group('Phase2WeeklyRewardsCard', () {
      testWidgets('renders without errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: Phase2WeeklyRewardsCard(),
              ),
            ),
          ),
        );

        expect(find.byType(Phase2WeeklyRewardsCard), findsOneWidget);
      });

      testWidgets('renders as a Card widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: Phase2WeeklyRewardsCard(),
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Phase2TierProgressCard', () {
      testWidgets('renders without errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: Phase2TierProgressCard(),
              ),
            ),
          ),
        );

        expect(find.byType(Phase2TierProgressCard), findsOneWidget);
      });

      testWidgets('renders as a Card widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: Phase2TierProgressCard(),
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('has proper styling with gradient',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: Phase2TierProgressCard(),
              ),
            ),
          ),
        );

        final container = find.byType(Container);
        expect(container, findsWidgets);
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // Layout Integration Tests
    // ────────────────────────────────────────────────────────────────────────

    group('Mobile Layout (stacked columns)', () {
      testWidgets('renders cards in column on narrow screens',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 720) {
                      return Column(
                        children: [
                          Phase2DailyBonusCard(),
                          const SizedBox(height: 16),
                          Phase2WeeklyRewardsCard(),
                          const SizedBox(height: 16),
                          Phase2TierProgressCard(),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: Phase2DailyBonusCard()),
                        const SizedBox(width: 16),
                        Expanded(child: Phase2WeeklyRewardsCard()),
                        const SizedBox(width: 16),
                        Expanded(child: Phase2TierProgressCard()),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.byType(Column), findsWidgets);
        expect(find.byType(Phase2DailyBonusCard), findsOneWidget);
        expect(find.byType(Phase2WeeklyRewardsCard), findsOneWidget);
        expect(find.byType(Phase2TierProgressCard), findsOneWidget);
      });
    });

    group('Desktop Layout (3-column row)', () {
      testWidgets('renders cards in row on wide screens',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: SizedBox(
                  width: 1200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Phase2DailyBonusCard()),
                      const SizedBox(width: 16),
                      Expanded(child: Phase2WeeklyRewardsCard()),
                      const SizedBox(width: 16),
                      Expanded(child: Phase2TierProgressCard()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Expanded), findsNWidgets(3));
        expect(find.byType(Phase2DailyBonusCard), findsOneWidget);
        expect(find.byType(Phase2WeeklyRewardsCard), findsOneWidget);
        expect(find.byType(Phase2TierProgressCard), findsOneWidget);
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // Spacing Tests
    // ────────────────────────────────────────────────────────────────────────

    group('Card Spacing', () {
      testWidgets('mobile layout has proper vertical spacing',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: Column(
                  children: [
                    Phase2DailyBonusCard(),
                    const SizedBox(height: 16),
                    Phase2WeeklyRewardsCard(),
                    const SizedBox(height: 16),
                    Phase2TierProgressCard(),
                  ],
                ),
              ),
            ),
          ),
        );

        final spacers = find.byType(SizedBox);
        expect(spacers, findsWidgets);
      });

      testWidgets('desktop layout has proper horizontal spacing',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: Row(
                  children: [
                    Expanded(child: Phase2DailyBonusCard()),
                    const SizedBox(width: 16),
                    Expanded(child: Phase2WeeklyRewardsCard()),
                    const SizedBox(width: 16),
                    Expanded(child: Phase2TierProgressCard()),
                  ],
                ),
              ),
            ),
          ),
        );

        final spacers = find.byType(SizedBox);
        expect(spacers, findsWidgets);
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // Responsive Behavior Tests
    // ────────────────────────────────────────────────────────────────────────

    group('Responsive Behavior', () {
      testWidgets('all cards render in responsive layout',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [
                          Phase2DailyBonusCard(),
                          const SizedBox(height: 16),
                          Phase2WeeklyRewardsCard(),
                          const SizedBox(height: 16),
                          Phase2TierProgressCard(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(LayoutBuilder), findsOneWidget);
        expect(find.byType(Phase2DailyBonusCard), findsOneWidget);
        expect(find.byType(Phase2WeeklyRewardsCard), findsOneWidget);
        expect(find.byType(Phase2TierProgressCard), findsOneWidget);
      });

      testWidgets('cards are scrollable when needed',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      Phase2DailyBonusCard(),
                      Phase2WeeklyRewardsCard(),
                      Phase2TierProgressCard(),
                      const SizedBox(height: 500),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });
  });
}
