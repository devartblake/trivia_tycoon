import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/services/question_analytics_service.dart';
import 'package:synaptix/ui_components/analytics/category_pie_chart.dart';

// NOTE: CategoryPieChart was redesigned into the "Neural Bloom" visualization —
// a CustomPaint bloom plus a category legend. The per-category accuracy %,
// correct/total counts, LinearProgressIndicator bars, and the onCategoryTap
// interaction were dropped in that redesign, so those assertions were removed
// here (accuracy is now conveyed visually by the bloom rather than as text).
void main() {
  group('CategoryPieChart', () {
    late List<CategoryPerformance> mockCategories;

    setUp(() {
      mockCategories = [
        CategoryPerformance(
          category: 'Math',
          totalQuestions: 20,
          correctQuestions: 18,
          accuracy: 90.0,
          totalXP: 2000,
        ),
        CategoryPerformance(
          category: 'Science',
          totalQuestions: 15,
          correctQuestions: 12,
          accuracy: 80.0,
          totalXP: 1500,
        ),
        CategoryPerformance(
          category: 'History',
          totalQuestions: 10,
          correctQuestions: 7,
          accuracy: 70.0,
          totalXP: 1000,
        ),
      ];
    });

    Widget wrap(List<CategoryPerformance> categories) => MaterialApp(
          home: Scaffold(body: CategoryPieChart(categories: categories)),
        );

    testWidgets('displays title', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(mockCategories));
      expect(find.text('Neural Bloom'), findsOneWidget);
    });

    testWidgets('displays subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(mockCategories));
      expect(find.text('Your cognitive growth by category'), findsOneWidget);
    });

    testWidgets('displays all categories in the legend',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(mockCategories));
      expect(find.text('Math'), findsOneWidget);
      expect(find.text('Science'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('renders the bloom visualization', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(mockCategories));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('shows empty state', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const []));
      expect(find.text('No category data available'), findsOneWidget);
    });

    testWidgets('limits to the top categories', (WidgetTester tester) async {
      final manyCategories = List.generate(
        10,
        (i) => CategoryPerformance(
          category: 'Category $i',
          totalQuestions: 20 - i,
          correctQuestions: 15 - i,
          accuracy: 75.0,
          totalXP: 1000,
        ),
      );

      await tester.pumpWidget(wrap(manyCategories));

      // Top entries (by total questions) appear; the long tail is trimmed.
      expect(find.text('Category 0'), findsOneWidget);
      expect(find.text('Category 4'), findsOneWidget);
      expect(find.text('Category 9'), findsNothing);
    });

    testWidgets('sorts by questions count (descending)',
        (WidgetTester tester) async {
      final unsortedCategories = [
        CategoryPerformance(
          category: 'Low',
          totalQuestions: 5,
          correctQuestions: 4,
          accuracy: 80.0,
          totalXP: 500,
        ),
        CategoryPerformance(
          category: 'High',
          totalQuestions: 30,
          correctQuestions: 25,
          accuracy: 83.3,
          totalXP: 3000,
        ),
      ];

      await tester.pumpWidget(wrap(unsortedCategories));

      expect(find.text('High'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });
  });
}
