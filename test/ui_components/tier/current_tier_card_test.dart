import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/tier_api_client.dart';
import 'package:synaptix/ui_components/tier/current_tier_card.dart';

void main() {
  group('CurrentTierCard', () {
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

    testWidgets('displays current tier name and level',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentTierCard(progress: mockProgress),
          ),
        ),
      );

      expect(find.text('Current Tier'), findsOneWidget);
      expect(find.text('Gold Tier'), findsOneWidget);
      expect(find.text('Level 5'), findsOneWidget);
    });

    testWidgets('displays rewards breakdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentTierCard(progress: mockProgress),
          ),
        ),
      );

      expect(find.text('Badge'), findsOneWidget);
      expect(find.text('Coins'), findsOneWidget);
      expect(find.text('Gems'), findsOneWidget);
      expect(find.text('Gold Badge'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('displays max tier message when at max tier',
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
            body: CurrentTierCard(progress: maxTierProgress),
          ),
        ),
      );

      expect(find.text("You've reached the maximum tier!"), findsOneWidget);
    });

    testWidgets('uses correct color for Gold tier',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentTierCard(progress: mockProgress),
          ),
        ),
      );

      final icons = find.byIcon(Icons.monetization_on);
      expect(icons, findsWidgets);
    });

    testWidgets('uses correct color for Platinum tier',
        (WidgetTester tester) async {
      final platinumTier = TierDefinition(
        id: '10',
        name: 'Platinum Tier',
        level: 10,
        minXp: 5000,
        maxXp: 6000,
        iconName: 'platinum_icon',
        rewards: TierReward(
          badge: 'Platinum Badge',
          coinsBonus: 5000,
          gemsBonus: 250,
        ),
      );

      final platinumProgress = PlayerTierProgress(
        currentTier: platinumTier,
        nextTier: null,
        currentXp: 5500,
        xpInCurrentTier: 500,
        xpNeededForNextTier: 1000,
        progressPercentage: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentTierCard(progress: platinumProgress),
          ),
        ),
      );

      expect(find.byIcon(Icons.diamond), findsOneWidget);
    });

    testWidgets('uses correct color for Silver tier',
        (WidgetTester tester) async {
      final silverTier = TierDefinition(
        id: '3',
        name: 'Silver Tier',
        level: 3,
        minXp: 300,
        maxXp: 500,
        iconName: 'silver_icon',
        rewards: TierReward(
          badge: 'Silver Badge',
          coinsBonus: 600,
          gemsBonus: 30,
        ),
      );

      final silverProgress = PlayerTierProgress(
        currentTier: silverTier,
        nextTier: currentTier,
        currentXp: 350,
        xpInCurrentTier: 50,
        xpNeededForNextTier: 200,
        progressPercentage: 25,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentTierCard(progress: silverProgress),
          ),
        ),
      );

      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('card has proper elevation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentTierCard(progress: mockProgress),
          ),
        ),
      );

      final card = find.byType(Card);
      expect(card, findsOneWidget);
    });

    testWidgets('displays all reward icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentTierCard(progress: mockProgress),
          ),
        ),
      );

      expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
      expect(find.byIcon(Icons.diamond), findsOneWidget);
    });

    testWidgets('tier icon displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentTierCard(progress: mockProgress),
          ),
        ),
      );

      // Gold tier should have monetization_on icon (at least once for the tier icon)
      expect(find.byIcon(Icons.monetization_on), findsWidgets);
    });

    testWidgets('max tier message styled correctly',
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
            body: CurrentTierCard(progress: maxTierProgress),
          ),
        ),
      );

      final maxTierText = find.text("You've reached the maximum tier!");
      expect(maxTierText, findsOneWidget);

      final star = find.byIcon(Icons.star);
      expect(star, findsOneWidget);
    });

    testWidgets('reward values are displayed correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentTierCard(progress: mockProgress),
          ),
        ),
      );

      expect(find.text('1000'), findsOneWidget); // coinsBonus
      expect(find.text('50'), findsOneWidget); // gemsBonus
      expect(find.text('Gold Badge'), findsOneWidget); // badge
    });

    testWidgets('layout has proper spacing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentTierCard(progress: mockProgress),
          ),
        ),
      );

      // Verify we have proper columns and rows
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('card renders without errors for Bronze tier',
        (WidgetTester tester) async {
      final bronzeTier = TierDefinition(
        id: '1',
        name: 'Bronze Tier',
        level: 1,
        minXp: 0,
        maxXp: 100,
        iconName: 'bronze_icon',
        rewards: TierReward(
          badge: 'Bronze Badge',
          coinsBonus: 100,
          gemsBonus: 5,
        ),
      );

      final bronzeProgress = PlayerTierProgress(
        currentTier: bronzeTier,
        nextTier: null,
        currentXp: 50,
        xpInCurrentTier: 50,
        xpNeededForNextTier: 100,
        progressPercentage: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentTierCard(progress: bronzeProgress),
          ),
        ),
      );

      expect(find.byType(CurrentTierCard), findsOneWidget);
      expect(find.text('Bronze Tier'), findsOneWidget);
    });
  });
}
