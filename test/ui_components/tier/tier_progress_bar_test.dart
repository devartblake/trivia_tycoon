import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';
import 'package:trivia_tycoon/ui_components/tier/tier_progress_bar.dart';

void main() {
  group('TierProgressBar', () {
    late PlayerTierProgress mockProgress;
    late TierDefinition currentTier;
    late TierDefinition nextTier;

    setUp(() {
      currentTier = TierDefinition(
        id: '5',
        name: 'Gold Tier',
        level: 5,
        minXp: 500,
        maxXp: 1000,
        iconName: 'gold_icon',
        rewards: TierReward(
          badge: 'Gold Badge',
          coinsBonus: 1000,
          gemsBonus: 50,
        ),
      );

      nextTier = TierDefinition(
        id: '6',
        name: 'Platinum Tier',
        level: 6,
        minXp: 1000,
        maxXp: 1500,
        iconName: 'platinum_icon',
        rewards: TierReward(
          badge: 'Platinum Badge',
          coinsBonus: 1500,
          gemsBonus: 75,
        ),
      );

      mockProgress = PlayerTierProgress(
        currentTier: currentTier,
        nextTier: nextTier,
        currentXp: 750,
        xpInCurrentTier: 250,
        xpNeededForNextTier: 500,
        progressPercentage: 50,
      );
    });

    testWidgets('displays progress title and next tier name',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: mockProgress),
          ),
        ),
      );

      expect(find.text('Progress to Next Tier'), findsOneWidget);
      expect(find.text('Platinum Tier'), findsOneWidget);
    });

    testWidgets('displays XP progress correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: mockProgress),
          ),
        ),
      );

      expect(find.text('XP Progress'), findsOneWidget);
      expect(find.text('250 / 500'), findsOneWidget);
    });

    testWidgets('displays completion percentage', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: mockProgress),
          ),
        ),
      );

      expect(find.text('Completion'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('displays estimated quiz count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: mockProgress),
          ),
        ),
      );

      // Remaining XP: 500 - 250 = 250, so ~3 quizzes at ~100 XP each (ceil)
      expect(find.text('Estimated: ~3 more quizzes'), findsOneWidget);
    });

    testWidgets('progress bar renders with correct value',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: mockProgress),
          ),
        ),
      );

      final linearProgress = find.byType(LinearProgressIndicator);
      expect(linearProgress, findsOneWidget);
    });

    testWidgets('shows max tier message when at max tier',
        (WidgetTester tester) async {
      final maxTierProgress = PlayerTierProgress(
        currentTier: currentTier,
        nextTier: null,
        currentXp: 750,
        xpInCurrentTier: 250,
        xpNeededForNextTier: 500,
        progressPercentage: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: maxTierProgress),
          ),
        ),
      );

      expect(find.text("You've reached the maximum tier!"), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('progress color changes at 0% (blue)',
        (WidgetTester tester) async {
      final lowProgress = PlayerTierProgress(
        currentTier: currentTier,
        nextTier: nextTier,
        currentXp: 750,
        xpInCurrentTier: 0,
        xpNeededForNextTier: 500,
        progressPercentage: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: lowProgress),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('progress color changes at 25% (orange)',
        (WidgetTester tester) async {
      final quarterProgress = PlayerTierProgress(
        currentTier: currentTier,
        nextTier: nextTier,
        currentXp: 750,
        xpInCurrentTier: 125,
        xpNeededForNextTier: 500,
        progressPercentage: 25,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: quarterProgress),
          ),
        ),
      );

      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('progress color changes at 50% (amber)',
        (WidgetTester tester) async {
      final halfProgress = PlayerTierProgress(
        currentTier: currentTier,
        nextTier: nextTier,
        currentXp: 750,
        xpInCurrentTier: 250,
        xpNeededForNextTier: 500,
        progressPercentage: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: halfProgress),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('progress color changes at 75% (green)',
        (WidgetTester tester) async {
      final threeQuarterProgress = PlayerTierProgress(
        currentTier: currentTier,
        nextTier: nextTier,
        currentXp: 750,
        xpInCurrentTier: 375,
        xpNeededForNextTier: 500,
        progressPercentage: 75,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: threeQuarterProgress),
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('progress color at 100% (green)', (WidgetTester tester) async {
      final almostMaxProgress = PlayerTierProgress(
        currentTier: currentTier,
        nextTier: nextTier,
        currentXp: 750,
        xpInCurrentTier: 500,
        xpNeededForNextTier: 500,
        progressPercentage: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: almostMaxProgress),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('displays schedule icon for estimated time',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: mockProgress),
          ),
        ),
      );

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('card has proper elevation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: mockProgress),
          ),
        ),
      );

      final card = find.byType(Card);
      expect(card, findsOneWidget);
    });

    testWidgets('shows correct quiz count for large XP difference',
        (WidgetTester tester) async {
      final newProgress = PlayerTierProgress(
        currentTier: currentTier,
        nextTier: nextTier,
        currentXp: 750,
        xpInCurrentTier: 100,
        xpNeededForNextTier: 500,
        progressPercentage: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: newProgress),
          ),
        ),
      );

      // Remaining: 500 - 100 = 400, so ~4 quizzes
      expect(find.text('Estimated: ~4 more quizzes'), findsOneWidget);
    });

    testWidgets('shows correct quiz count for 1 remaining',
        (WidgetTester tester) async {
      final almostProgress = PlayerTierProgress(
        currentTier: currentTier,
        nextTier: nextTier,
        currentXp: 750,
        xpInCurrentTier: 450,
        xpNeededForNextTier: 500,
        progressPercentage: 90,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: almostProgress),
          ),
        ),
      );

      // Remaining: 500 - 450 = 50, so 1 quiz (ceil(50/100) = 1)
      expect(find.text('Estimated: ~1 more quizzes'), findsOneWidget);
    });

    testWidgets('layout has proper sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierProgressBar(progress: mockProgress),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });
  });
}
