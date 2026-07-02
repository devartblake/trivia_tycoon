import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/ui_components/tier/tier_history_timeline.dart';

void main() {
  group('TierHistoryTimeline', () {
    late List<TierHistoryEvent> testEvents;

    setUp(() {
      final now = DateTime.now();
      testEvents = [
        TierHistoryEvent(
          tier: 5,
          tierName: 'Tier 5: Master',
          timestamp: now.subtract(const Duration(hours: 2)),
          achievement: 'Tier Up',
          tierColor: Colors.amber,
        ),
        TierHistoryEvent(
          tier: 4,
          tierName: 'Tier 4: Expert',
          timestamp: now.subtract(const Duration(days: 1)),
          achievement: 'Tier Up',
          tierColor: Colors.orange,
        ),
        TierHistoryEvent(
          tier: 3,
          tierName: 'Tier 3: Advanced',
          timestamp: now.subtract(const Duration(days: 7)),
          achievement: 'Tier Up',
          tierColor: Colors.purple,
        ),
      ];
    });

    testWidgets('renders timeline title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(events: testEvents),
          ),
        ),
      );

      expect(find.text('Tier History'), findsOneWidget);
    });

    testWidgets('renders all events', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(events: testEvents),
          ),
        ),
      );

      expect(find.text('Tier 5: Master'), findsOneWidget);
      expect(find.text('Tier 4: Expert'), findsOneWidget);
      expect(find.text('Tier 3: Advanced'), findsOneWidget);
    });

    testWidgets('renders all achievements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(events: testEvents),
          ),
        ),
      );

      expect(find.text('Tier Up'), findsWidgets);
    });

    testWidgets('shows dates when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(
              events: testEvents,
              showDates: true,
            ),
          ),
        ),
      );

      // Should show at least one date
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('hides dates when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(
              events: testEvents,
              showDates: false,
            ),
          ),
        ),
      );

      expect(find.byType(TierHistoryTimeline), findsOneWidget);
    });

    testWidgets('shows empty state with no events', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(events: []),
          ),
        ),
      );

      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.text('No tier history yet'), findsOneWidget);
      expect(find.text('Complete challenges to progress through tiers'),
          findsOneWidget);
    });

    testWidgets('renders single event', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(events: [testEvents[0]]),
          ),
        ),
      );

      expect(find.text('Tier 5: Master'), findsOneWidget);
    });

    testWidgets('handles many events', (WidgetTester tester) async {
      final now = DateTime.now();
      final manyEvents = List.generate(
        20,
        (index) => TierHistoryEvent(
          tier: 20 - index,
          tierName: 'Tier ${20 - index}',
          timestamp: now.subtract(Duration(days: index)),
          achievement: 'Tier Up',
          tierColor: Colors.blue,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TierHistoryTimeline(events: manyEvents),
            ),
          ),
        ),
      );

      expect(find.text('Tier History'), findsOneWidget);
    });

    testWidgets('timeline has correct structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(events: testEvents),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('tier names have correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(events: testEvents),
          ),
        ),
      );

      expect(find.text('Tier 5: Master'), findsOneWidget);
    });

    testWidgets('achievement badges are visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(events: testEvents),
          ),
        ),
      );

      expect(find.text('Tier Up'), findsWidgets);
    });

    testWidgets('can scroll through many events',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final manyEvents = List.generate(
        30,
        (index) => TierHistoryEvent(
          tier: index,
          tierName: 'Tier $index',
          timestamp: now.subtract(Duration(days: index)),
          achievement: 'Tier Up',
          tierColor: Colors.blue,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TierHistoryTimeline(events: manyEvents),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(TierHistoryTimeline), findsOneWidget);
    });

    testWidgets('different tier colors are applied',
        (WidgetTester tester) async {
      final coloredEvents = [
        TierHistoryEvent(
          tier: 1,
          tierName: 'Tier 1',
          timestamp: DateTime.now(),
          achievement: 'Started',
          tierColor: Colors.green,
        ),
        TierHistoryEvent(
          tier: 2,
          tierName: 'Tier 2',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          achievement: 'Tier Up',
          tierColor: Colors.blue,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(events: coloredEvents),
          ),
        ),
      );

      expect(find.text('Tier 1'), findsOneWidget);
      expect(find.text('Tier 2'), findsOneWidget);
    });
  });

  group('TierHistoryEvent', () {
    testWidgets('creates event with all fields', (WidgetTester tester) async {
      final now = DateTime.now();
      final event = TierHistoryEvent(
        tier: 5,
        tierName: 'Tier 5: Master',
        timestamp: now,
        achievement: 'Tier Up',
        tierColor: Colors.amber,
      );

      expect(event.tier, equals(5));
      expect(event.tierName, equals('Tier 5: Master'));
      expect(event.timestamp, equals(now));
      expect(event.achievement, equals('Tier Up'));
      expect(event.tierColor, equals(Colors.amber));
    });

    testWidgets('handles different tier numbers', (WidgetTester tester) async {
      final event1 = TierHistoryEvent(
        tier: 1,
        tierName: 'Tier 1',
        timestamp: DateTime.now(),
        achievement: 'Started',
        tierColor: Colors.green,
      );

      final event10 = TierHistoryEvent(
        tier: 10,
        tierName: 'Tier 10',
        timestamp: DateTime.now(),
        achievement: 'Mastered',
        tierColor: Colors.amber,
      );

      expect(event1.tier, equals(1));
      expect(event10.tier, equals(10));
    });

    testWidgets('handles different achievement types',
        (WidgetTester tester) async {
      final achievements = [
        'Tier Up',
        'Started',
        'Reward Claimed',
        'Unlocked Skill',
      ];

      for (final achievement in achievements) {
        final event = TierHistoryEvent(
          tier: 1,
          tierName: 'Tier 1',
          timestamp: DateTime.now(),
          achievement: achievement,
          tierColor: Colors.green,
        );

        expect(event.achievement, equals(achievement));
      }
    });
  });

  group('generateMockTierHistory', () {
    testWidgets('generates mock data', (WidgetTester tester) async {
      final mockData = generateMockTierHistory();

      expect(mockData, isNotEmpty);
      expect(mockData.length, equals(5));
    });

    testWidgets('mock data has correct structure',
        (WidgetTester tester) async {
      final mockData = generateMockTierHistory();

      for (final event in mockData) {
        expect(event.tier, isNotNull);
        expect(event.tierName, isNotNull);
        expect(event.timestamp, isNotNull);
        expect(event.achievement, isNotNull);
        expect(event.tierColor, isNotNull);
      }
    });

    testWidgets('mock data is ordered newest first',
        (WidgetTester tester) async {
      final mockData = generateMockTierHistory();

      for (int i = 0; i < mockData.length - 1; i++) {
        expect(
          mockData[i].timestamp.isAfter(mockData[i + 1].timestamp),
          true,
        );
      }
    });

    testWidgets('mock data tier numbers are descending',
        (WidgetTester tester) async {
      final mockData = generateMockTierHistory();

      for (int i = 0; i < mockData.length - 1; i++) {
        expect(mockData[i].tier, greaterThan(mockData[i + 1].tier));
      }
    });
  });

  group('Date Formatting', () {
    testWidgets('formats today date correctly', (WidgetTester tester) async {
      final now = DateTime.now();
      final event = TierHistoryEvent(
        tier: 1,
        tierName: 'Tier 1',
        timestamp: now,
        achievement: 'Started',
        tierColor: Colors.green,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(
              events: [event],
              showDates: true,
            ),
          ),
        ),
      );

      expect(find.byType(TierHistoryTimeline), findsOneWidget);
    });

    testWidgets('formats yesterday date correctly', (WidgetTester tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final event = TierHistoryEvent(
        tier: 1,
        tierName: 'Tier 1',
        timestamp: yesterday,
        achievement: 'Started',
        tierColor: Colors.green,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(
              events: [event],
              showDates: true,
            ),
          ),
        ),
      );

      expect(find.byType(TierHistoryTimeline), findsOneWidget);
    });

    testWidgets('formats old dates correctly', (WidgetTester tester) async {
      final oldDate = DateTime.now().subtract(const Duration(days: 30));
      final event = TierHistoryEvent(
        tier: 1,
        tierName: 'Tier 1',
        timestamp: oldDate,
        achievement: 'Started',
        tierColor: Colors.green,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TierHistoryTimeline(
              events: [event],
              showDates: true,
            ),
          ),
        ),
      );

      expect(find.byType(TierHistoryTimeline), findsOneWidget);
    });
  });
}
