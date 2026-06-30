import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/question_analytics_service.dart';
import 'package:trivia_tycoon/ui_components/analytics/trending_card.dart';

void main() {
  group('TrendingPerformanceCard', () {
    testWidgets('displays period', (WidgetTester tester) async {
      final trending = TrendingSummary(
        period: '24h',
        questionsAnswered: 20,
        correctAnswered: 16,
        accuracyPercent: '80.0',
        trending: 'up',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendingPerformanceCard(trending: trending),
          ),
        ),
      );

      expect(find.text('Last 24h'), findsOneWidget);
    });

    testWidgets('displays trending up indicator', (WidgetTester tester) async {
      final trending = TrendingSummary(
        period: '24h',
        questionsAnswered: 20,
        correctAnswered: 18,
        accuracyPercent: '90.0',
        trending: 'up',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendingPerformanceCard(trending: trending),
          ),
        ),
      );

      expect(find.text('Excellent'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('displays trending down indicator', (WidgetTester tester) async {
      final trending = TrendingSummary(
        period: '24h',
        questionsAnswered: 20,
        correctAnswered: 8,
        accuracyPercent: '40.0',
        trending: 'down',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendingPerformanceCard(trending: trending),
          ),
        ),
      );

      expect(find.text('Needs Work'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('displays neutral trend', (WidgetTester tester) async {
      final trending = TrendingSummary(
        period: '24h',
        questionsAnswered: 20,
        correctAnswered: 12,
        accuracyPercent: '60.0',
        trending: 'neutral',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendingPerformanceCard(trending: trending),
          ),
        ),
      );

      expect(find.text('Average'), findsOneWidget);
      expect(find.byIcon(Icons.trending_flat), findsOneWidget);
    });

    testWidgets('displays all stats', (WidgetTester tester) async {
      final trending = TrendingSummary(
        period: '24h',
        questionsAnswered: 20,
        correctAnswered: 16,
        accuracyPercent: '80.0',
        trending: 'up',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendingPerformanceCard(trending: trending),
          ),
        ),
      );

      expect(find.text('Questions'), findsOneWidget);
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('80.0%'), findsOneWidget);
    });

    testWidgets('displays success rate progress bar', (WidgetTester tester) async {
      final trending = TrendingSummary(
        period: '24h',
        questionsAnswered: 20,
        correctAnswered: 16,
        accuracyPercent: '80.0',
        trending: 'up',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendingPerformanceCard(trending: trending),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Success Rate'), findsOneWidget);
    });

    testWidgets('handles zero questions', (WidgetTester tester) async {
      final trending = TrendingSummary(
        period: '24h',
        questionsAnswered: 0,
        correctAnswered: 0,
        accuracyPercent: '0.0',
        trending: 'neutral',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendingPerformanceCard(trending: trending),
          ),
        ),
      );

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('handles perfect accuracy', (WidgetTester tester) async {
      final trending = TrendingSummary(
        period: '24h',
        questionsAnswered: 10,
        correctAnswered: 10,
        accuracyPercent: '100.0',
        trending: 'up',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendingPerformanceCard(trending: trending),
          ),
        ),
      );

      expect(find.text('100.0%'), findsOneWidget);
    });

    testWidgets('different time periods', (WidgetTester tester) async {
      final trending7h = TrendingSummary(
        period: '7d',
        questionsAnswered: 50,
        correctAnswered: 40,
        accuracyPercent: '80.0',
        trending: 'up',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendingPerformanceCard(trending: trending7h),
          ),
        ),
      );

      expect(find.text('Last 7d'), findsOneWidget);
    });

    testWidgets('color accuracy indicator green for high accuracy',
        (WidgetTester tester) async {
      final trending = TrendingSummary(
        period: '24h',
        questionsAnswered: 20,
        correctAnswered: 18,
        accuracyPercent: '90.0',
        trending: 'up',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendingPerformanceCard(trending: trending),
          ),
        ),
      );

      final progressIndicator =
          find.byType(LinearProgressIndicator).first;
      expect(progressIndicator, findsOneWidget);
    });
  });
}
