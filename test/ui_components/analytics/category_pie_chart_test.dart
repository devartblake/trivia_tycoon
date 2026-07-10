import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/question_analytics_service.dart';
import 'package:trivia_tycoon/ui_components/analytics/category_pie_chart.dart';

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

    testWidgets('displays title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(categories: mockCategories),
          ),
        ),
      );

      expect(find.text('Performance by Category'), findsOneWidget);
    });

    testWidgets('displays all categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(categories: mockCategories),
          ),
        ),
      );

      expect(find.text('Math'), findsOneWidget);
      expect(find.text('Science'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('displays accuracy percentages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(categories: mockCategories),
          ),
        ),
      );

      expect(find.text('90.0%'), findsOneWidget);
      expect(find.text('80.0%'), findsOneWidget);
      expect(find.text('70.0%'), findsOneWidget);
    });

    testWidgets('displays correct/total questions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(categories: mockCategories),
          ),
        ),
      );

      expect(find.text('18/20 correct'), findsOneWidget);
      expect(find.text('12/15 correct'), findsOneWidget);
      expect(find.text('7/10 correct'), findsOneWidget);
    });

    testWidgets('shows empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(categories: []),
          ),
        ),
      );

      expect(find.text('No category data available'), findsOneWidget);
    });

    testWidgets('handles callback on category tap',
        (WidgetTester tester) async {
      String? selectedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(
              categories: mockCategories,
              onCategoryTap: (category) {
                selectedCategory = category;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Math').first);
      await tester.pumpAndSettle();

      expect(selectedCategory, 'Math');
    });

    testWidgets('limits to top 5 categories', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(categories: manyCategories),
          ),
        ),
      );

      expect(find.text('Category 0'), findsOneWidget);
      expect(find.text('Category 4'), findsOneWidget);
      expect(find.text('Category 9'), findsNothing); // Should not show 6th+
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(categories: unsortedCategories),
          ),
        ),
      );

      final highFinder = find.text('High');
      final lowFinder = find.text('Low');
      expect(highFinder, findsOneWidget);
      expect(lowFinder, findsOneWidget);
    });

    testWidgets('displays progress bar for each category',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(categories: mockCategories),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('handles perfect accuracy (100%)', (WidgetTester tester) async {
      final perfectCategories = [
        CategoryPerformance(
          category: 'Perfect',
          totalQuestions: 10,
          correctQuestions: 10,
          accuracy: 100.0,
          totalXP: 1000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(categories: perfectCategories),
          ),
        ),
      );

      expect(find.text('100.0%'), findsOneWidget);
    });

    testWidgets('handles zero accuracy (0%)', (WidgetTester tester) async {
      final zeroCategories = [
        CategoryPerformance(
          category: 'Zero',
          totalQuestions: 10,
          correctQuestions: 0,
          accuracy: 0.0,
          totalXP: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(categories: zeroCategories),
          ),
        ),
      );

      expect(find.text('0.0%'), findsOneWidget);
    });
  });
}
