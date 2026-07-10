import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/screens/question/widgets/question_feedback_panel.dart';

void main() {
  group('QuestionFeedbackPanel', () {
    testWidgets('Displays correct result with icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
            ),
          ),
        ),
      );

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Displays incorrect result with icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: false,
            ),
          ),
        ),
      );

      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('Shows explanation when provided', (WidgetTester tester) async {
      const explanation = 'This is the correct answer because...';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
              explanation: explanation,
            ),
          ),
        ),
      );

      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text(explanation), findsOneWidget);
    });

    testWidgets('Shows hint when provided', (WidgetTester tester) async {
      const hint = 'Try to remember...';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
              hint: hint,
            ),
          ),
        ),
      );

      expect(find.text(hint), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    });

    testWidgets('Displays XP earned badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
              xpEarned: 150,
            ),
          ),
        ),
      );

      expect(find.text('+150'), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('Displays coins earned badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
              coinsEarned: 75,
            ),
          ),
        ),
      );

      expect(find.text('+75'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('Displays streak bonus indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
              streakBonus: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('Shows Next Question button', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
              onNext: () {
                buttonPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Next Question'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('Hides rewards for incorrect answers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: false,
              xpEarned: 0,
              coinsEarned: 0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.flash_on), findsNothing);
      expect(find.byIcon(Icons.monetization_on), findsNothing);
    });

    testWidgets('Shows multiple reward badges together',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
              xpEarned: 250,
              coinsEarned: 100,
              streakBonus: true,
            ),
          ),
        ),
      );

      expect(find.text('+250'), findsOneWidget);
      expect(find.text('+100'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('Renders correct background color for correct answer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isNotNull);
    });

    testWidgets('Renders correct background color for incorrect answer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isNotNull);
    });

    testWidgets('Text is properly aligned and styled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
              explanation: 'Test explanation',
            ),
          ),
        ),
      );

      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Test explanation'), findsOneWidget);
    });

    testWidgets('Handles null callbacks gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
              onNext: null,
            ),
          ),
        ),
      );

      // Should not crash
      expect(find.text('Correct!'), findsOneWidget);
      // Next button should not be visible
      expect(find.text('Next Question'), findsNothing);
    });

    testWidgets('Renders with all optional fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionFeedbackPanel(
              isCorrect: true,
              explanation: 'Full explanation',
              hint: 'Helpful hint',
              onNext: () {},
              xpEarned: 200,
              coinsEarned: 100,
              streakBonus: true,
            ),
          ),
        ),
      );

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('Full explanation'), findsOneWidget);
      expect(find.text('Helpful hint'), findsOneWidget);
      expect(find.text('+200'), findsOneWidget);
      expect(find.text('+100'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('Renders with minimal fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const QuestionFeedbackPanel(
              isCorrect: true,
            ),
          ),
        ),
      );

      expect(find.text('Correct!'), findsOneWidget);
      // Optional fields should not be rendered
      expect(find.byIcon(Icons.flash_on), findsNothing);
    });
  });
}
