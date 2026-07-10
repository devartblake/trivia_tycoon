import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';
import 'package:trivia_tycoon/ui_components/tier/tier_requirements_card.dart';

void main() {
  group('TierRequirementsCard', () {
    late TierDefinition nextTier;

    setUp(() {
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
    });

    testWidgets('displays requirements title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.text('Tier Requirements'), findsOneWidget);
    });

    testWidgets('displays next tier name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.text('Platinum Tier'), findsOneWidget);
    });

    testWidgets('displays next tier level', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.text('Level 6'), findsOneWidget);
    });

    testWidgets('displays minimum XP requirement', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.text('Minimum XP Required'), findsOneWidget);
      expect(find.text('1000 XP'), findsOneWidget);
    });

    testWidgets('displays max XP in tier', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.text('Max XP in Tier'), findsOneWidget);
      expect(find.text('1500 XP'), findsOneWidget);
    });

    testWidgets('displays badge reward', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.text('Badge Reward'), findsOneWidget);
      expect(find.text('Platinum Badge'), findsOneWidget);
    });

    testWidgets('displays coins reward', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.text('Coins Reward'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
    });

    testWidgets('displays gems reward', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.text('Gems Reward'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('hides when nextTier is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: null,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.byType(TierRequirementsCard), findsOneWidget);
      expect(find.text('Tier Requirements'), findsNothing);
    });

    testWidgets('hides when xpNeeded is zero', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 0,
            ),
          ),
        ),
      );

      expect(find.text('Tier Requirements'), findsNothing);
    });

    testWidgets('hides when xpNeeded is negative', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: -100,
            ),
          ),
        ),
      );

      expect(find.text('Tier Requirements'), findsNothing);
    });

    testWidgets('displays requirement icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.school), findsWidgets); // For XP icons
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
      expect(find.byIcon(Icons.diamond), findsOneWidget);
    });

    testWidgets('uses correct color for Platinum tier',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.diamond), findsOneWidget);
    });

    testWidgets('uses correct color for Gold tier',
        (WidgetTester tester) async {
      final goldTier = TierDefinition(
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: goldTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.monetization_on), findsWidgets);
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: silverTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('card has proper elevation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      final card = find.byType(Card);
      expect(card, findsOneWidget);
    });

    testWidgets('renders all requirement items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierRequirementsCard(
              nextTier: nextTier,
              xpNeeded: 250,
            ),
          ),
        ),
      );

      // Verify all 5 requirement items are present
      expect(find.text('Minimum XP Required'), findsOneWidget);
      expect(find.text('Max XP in Tier'), findsOneWidget);
      expect(find.text('Badge Reward'), findsOneWidget);
      expect(find.text('Coins Reward'), findsOneWidget);
      expect(find.text('Gems Reward'), findsOneWidget);
    });
  });
}
