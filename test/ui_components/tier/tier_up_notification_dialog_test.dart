import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';
import 'package:trivia_tycoon/ui_components/tier/tier_up_notification_dialog.dart';

void main() {
  group('TierUpNotificationDialog', () {
    late TierDefinition platinumTier;

    setUp(() {
      platinumTier = TierDefinition(
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

    testWidgets('displays tier up title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tier Up!'), findsOneWidget);
    });

    testWidgets('displays new tier name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Platinum Tier'), findsOneWidget);
    });

    testWidgets('displays congratulations message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Congratulations on reaching Level 6!'),
          findsOneWidget);
    });

    testWidgets('displays rewards unlocked title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rewards Unlocked'), findsOneWidget);
    });

    testWidgets('displays coins reward', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coins'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
    });

    testWidgets('displays gems reward', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gems'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('displays badge reward', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Badge'), findsOneWidget);
    });

    testWidgets('displays awesome button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Awesome!'), findsOneWidget);
    });

    testWidgets('button closes dialog on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) =>
                          TierUpNotificationDialog(
                        newTier: platinumTier,
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Dialog), findsNothing);

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text('Awesome!'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('calls onDismiss callback', (WidgetTester tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Awesome!'));
      await tester.pumpAndSettle();

      expect(dismissed, true);
    });

    testWidgets('displays correct icon for Platinum tier', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.diamond), findsOneWidget);
    });

    testWidgets('displays correct icon for Gold tier', (WidgetTester tester) async {
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
          home: Material(
            child: TierUpNotificationDialog(
              newTier: goldTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('displays correct icon for Silver tier', (WidgetTester tester) async {
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
          home: Material(
            child: TierUpNotificationDialog(
              newTier: silverTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('dialog has scale and fade animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
            ),
          ),
        ),
      );

      expect(find.byType(ScaleTransition), findsOneWidget);
      expect(find.byType(FadeTransition), findsOneWidget);
    });

    testWidgets('displays reward icons in dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: platinumTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.monetization_on), findsWidgets);
      expect(find.byIcon(Icons.diamond), findsWidgets);
      expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
    });

    testWidgets('handles high tier numbers correctly', (WidgetTester tester) async {
      final maxTier = TierDefinition(
        id: '18',
        name: 'Platinum Tier Max',
        level: 18,
        minXp: 10000,
        maxXp: 50000,
        iconName: 'max_icon',
        rewards: TierReward(
          badge: 'Max Badge',
          coinsBonus: 10000,
          gemsBonus: 500,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TierUpNotificationDialog(
              newTier: maxTier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Congratulations on reaching Level 18!'),
          findsOneWidget);
      expect(find.text('10000'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('displays correct level in message for all tiers', (WidgetTester tester) async {
      for (int level = 1; level <= 6; level++) {
        final tier = TierDefinition(
          id: level.toString(),
          name: 'Test Tier',
          level: level,
          minXp: 0,
          maxXp: 100,
          iconName: 'icon',
          rewards: TierReward(
            badge: 'Badge',
            coinsBonus: 100,
            gemsBonus: 10,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: TierUpNotificationDialog(
                newTier: tier,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Congratulations on reaching Level $level!'),
            findsOneWidget);

        // Clean up for next iteration
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });
}
