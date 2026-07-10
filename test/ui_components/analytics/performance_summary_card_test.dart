import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/question_analytics_service.dart';
import 'package:trivia_tycoon/ui_components/analytics/performance_summary_card.dart';

void main() {
  group('PerformanceSummaryCard', () {
    late PerformanceSummary mockSummary;

    setUp(() {
      mockSummary = PerformanceSummary(
        totalQuestions: 50,
        correctQuestions: 40,
        accuracy: 80.0,
        totalXP: 5000,
        totalCoins: 1500,
        averageTimeSeconds: 45,
        lastUpdated: DateTime.now(),
      );
    });

    testWidgets('displays performance title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceSummaryCard(summary: mockSummary),
          ),
        ),
      );

      expect(find.text('Overall Performance'), findsOneWidget);
    });

    testWidgets('displays all stat tiles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceSummaryCard(summary: mockSummary),
          ),
        ),
      );

      expect(find.text('Questions'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('Total XP'), findsOneWidget);
      expect(find.text('Coins'), findsOneWidget);
    });

    testWidgets('displays correct stat values', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceSummaryCard(summary: mockSummary),
          ),
        ),
      );

      expect(find.text('50'), findsOneWidget); // Total questions
      expect(find.text('80.0%'), findsOneWidget); // Accuracy
      expect(find.text('5000'), findsOneWidget); // XP
      expect(find.text('1500'), findsOneWidget); // Coins
    });

    testWidgets('displays breakdown stats', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceSummaryCard(summary: mockSummary),
          ),
        ),
      );

      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('40'), findsOneWidget); // Correct count
      expect(find.text('10'), findsOneWidget); // Incorrect count
    });

    testWidgets('displays average time', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceSummaryCard(summary: mockSummary),
          ),
        ),
      );

      expect(find.text('Avg. Time: 45s'), findsOneWidget);
    });

    testWidgets('calculates incorrect questions correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceSummaryCard(summary: mockSummary),
          ),
        ),
      );

      final incorrectQuestions = mockSummary.incorrectQuestions;
      expect(incorrectQuestions, 10);
    });

    testWidgets('displays percentages correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceSummaryCard(summary: mockSummary),
          ),
        ),
      );

      // 40/50 = 80%, 10/50 = 20%
      expect(find.text('80.0%'), findsOneWidget);
      expect(find.text('20.0%'), findsOneWidget);
    });

    testWidgets('renders with zero questions', (WidgetTester tester) async {
      final emptySummary = PerformanceSummary(
        totalQuestions: 0,
        correctQuestions: 0,
        accuracy: 0.0,
        totalXP: 0,
        totalCoins: 0,
        averageTimeSeconds: 0,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceSummaryCard(summary: emptySummary),
          ),
        ),
      );

      expect(find.text('0'), findsWidgets);
      expect(find.text('0.0%'), findsOneWidget);
    });

    testWidgets('renders with high accuracy', (WidgetTester tester) async {
      final highAccuracy = PerformanceSummary(
        totalQuestions: 100,
        correctQuestions: 99,
        accuracy: 99.0,
        totalXP: 10000,
        totalCoins: 3000,
        averageTimeSeconds: 30,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceSummaryCard(summary: highAccuracy),
          ),
        ),
      );

      expect(find.text('99.0%'), findsOneWidget);
    });

    testWidgets('renders with low accuracy', (WidgetTester tester) async {
      final lowAccuracy = PerformanceSummary(
        totalQuestions: 100,
        correctQuestions: 30,
        accuracy: 30.0,
        totalXP: 1000,
        totalCoins: 300,
        averageTimeSeconds: 60,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceSummaryCard(summary: lowAccuracy),
          ),
        ),
      );

      expect(find.text('30.0%'), findsOneWidget);
    });

    testWidgets('card is scrollable when needed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PerformanceSummaryCard(summary: mockSummary),
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceSummaryCard), findsOneWidget);
    });
  });
}
