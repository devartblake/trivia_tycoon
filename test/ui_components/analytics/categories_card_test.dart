import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/services/question_analytics_service.dart';
import 'package:synaptix/ui_components/analytics/categories_card.dart';

void main() {
  group('WeakCategoriesCard', () {
    late List<WeakCategory> weakCategories;

    setUp(() {
      weakCategories = [
        WeakCategory(category: 'Math', accuracy: '40.0', questionCount: 20),
        WeakCategory(category: 'Science', accuracy: '60.0', questionCount: 15),
      ];
    });

    testWidgets('displays weak categories title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeakCategoriesCard(categories: weakCategories),
          ),
        ),
      );

      expect(find.text('Areas for Improvement'), findsOneWidget);
    });

    testWidgets('displays all weak categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeakCategoriesCard(categories: weakCategories),
          ),
        ),
      );

      expect(find.text('Math'), findsOneWidget);
      expect(find.text('Science'), findsOneWidget);
    });

    testWidgets('displays accuracy percentages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeakCategoriesCard(categories: weakCategories),
          ),
        ),
      );

      expect(find.text('40.0%'), findsOneWidget);
      expect(find.text('60.0%'), findsOneWidget);
    });

    testWidgets('displays question counts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeakCategoriesCard(categories: weakCategories),
          ),
        ),
      );

      expect(find.text('20 questions answered'), findsOneWidget);
      expect(find.text('15 questions answered'), findsOneWidget);
    });

    testWidgets('shows empty state message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeakCategoriesCard(categories: []),
          ),
        ),
      );

      expect(find.text('No weak categories - Great job!'), findsOneWidget);
    });

    testWidgets('handles category tap callback', (WidgetTester tester) async {
      String? tappedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeakCategoriesCard(
              categories: weakCategories,
              onCategoryTap: (category) => tappedCategory = category,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Math'));
      await tester.pumpAndSettle();

      expect(tappedCategory, 'Math');
    });

    testWidgets('sorts by accuracy ascending', (WidgetTester tester) async {
      final unsortedCategories = [
        WeakCategory(category: 'High', accuracy: '70.0', questionCount: 10),
        WeakCategory(category: 'Low', accuracy: '30.0', questionCount: 15),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeakCategoriesCard(categories: unsortedCategories),
          ),
        ),
      );

      expect(find.text('High'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });
  });

  group('StrongCategoriesCard', () {
    late List<StrongCategory> strongCategories;

    setUp(() {
      strongCategories = [
        StrongCategory(
          category: 'Math',
          accuracy: '95.0',
          questionCount: 20,
          totalXP: 2000,
        ),
        StrongCategory(
          category: 'Science',
          accuracy: '85.0',
          questionCount: 15,
          totalXP: 1500,
        ),
      ];
    });

    testWidgets('displays strong categories title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrongCategoriesCard(categories: strongCategories),
          ),
        ),
      );

      expect(find.text('Your Strengths'), findsOneWidget);
    });

    testWidgets('displays all strong categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrongCategoriesCard(categories: strongCategories),
          ),
        ),
      );

      expect(find.text('Math'), findsOneWidget);
      expect(find.text('Science'), findsOneWidget);
    });

    testWidgets('displays mastery percentages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrongCategoriesCard(categories: strongCategories),
          ),
        ),
      );

      expect(find.text('95.0%'), findsOneWidget);
      expect(find.text('85.0%'), findsOneWidget);
    });

    testWidgets('displays XP earned', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrongCategoriesCard(categories: strongCategories),
          ),
        ),
      );

      expect(find.text('2000 XP earned'), findsOneWidget);
      expect(find.text('1500 XP earned'), findsOneWidget);
    });

    testWidgets('shows empty state message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrongCategoriesCard(categories: []),
          ),
        ),
      );

      expect(find.text('No strong categories yet - Keep practicing!'),
          findsOneWidget);
    });

    testWidgets('handles category tap callback', (WidgetTester tester) async {
      String? tappedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrongCategoriesCard(
              categories: strongCategories,
              onCategoryTap: (category) => tappedCategory = category,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Math'));
      await tester.pumpAndSettle();

      expect(tappedCategory, 'Math');
    });

    testWidgets('sorts by accuracy descending', (WidgetTester tester) async {
      final unsortedCategories = [
        StrongCategory(
          category: 'Low',
          accuracy: '75.0',
          questionCount: 10,
          totalXP: 750,
        ),
        StrongCategory(
          category: 'High',
          accuracy: '95.0',
          questionCount: 20,
          totalXP: 1900,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrongCategoriesCard(categories: unsortedCategories),
          ),
        ),
      );

      expect(find.text('High'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('displays star icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrongCategoriesCard(categories: strongCategories),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsWidgets);
    });
  });
}
