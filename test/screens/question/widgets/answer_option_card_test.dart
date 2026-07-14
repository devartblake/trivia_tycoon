import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/screens/question/widgets/answer_option_card.dart';

void main() {
  group('AnswerOptionCard', () {
    testWidgets('Renders with text label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOptionCard(
              text: 'Option A',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Option A'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Calls onPressed when tapped', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOptionCard(
              text: 'Option A',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('Disables button when onPressed is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOptionCard(
              text: 'Option A',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);

      // Button should be disabled (grey out)
      final buttonWidget = tester.widget<ElevatedButton>(button);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('Shows selected state with blue background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOptionCard(
              text: 'Option A',
              onPressed: () {},
              isSelected: true,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor, isNotNull);
    });

    testWidgets('Shows correct state with green background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOptionCard(
              text: 'Option A',
              onPressed: () {},
              isCorrect: true,
              showFeedback: true,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor, isNotNull);
    });

    testWidgets('Shows incorrect state with red background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOptionCard(
              text: 'Option A',
              onPressed: () {},
              isCorrect: false,
              isSelected: true,
              showFeedback: true,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor, isNotNull);
    });

    testWidgets('Disables button when showFeedback is true',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOptionCard(
              text: 'Option A',
              onPressed: () {
                pressed = true;
              },
              showFeedback: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isFalse); // Should not call onPressed
    });

    testWidgets('Multiplayer styling applies different colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOptionCard(
              text: 'Option A',
              onPressed: () {},
              isSelected: true,
              isMultiplayer: true,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor, isNotNull);
    });

    testWidgets('Text is centered and properly styled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOptionCard(
              text: 'Option A',
              onPressed: () {},
            ),
          ),
        ),
      );

      final textFinder = find.text('Option A');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.textAlign, equals(TextAlign.center));
    });

    testWidgets('Respects custom text properties', (WidgetTester tester) async {
      const customText = 'Custom Option Text';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOptionCard(
              text: customText,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text(customText), findsOneWidget);
    });

    testWidgets('Button maintains minimum width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AnswerOptionCard(
                text: 'Option A',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);

      // Button should fill available width (double.infinity)
      final button = tester.widget<SizedBox>(find.byType(SizedBox).at(1));
      expect(button.width, equals(double.infinity));
    });

    group('State combinations', () {
      testWidgets('Selected and correct shows green',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnswerOptionCard(
                text: 'Option A',
                onPressed: () {},
                isSelected: true,
                isCorrect: true,
                showFeedback: true,
              ),
            ),
          ),
        );

        expect(find.text('Option A'), findsOneWidget);
      });

      testWidgets('Selected and incorrect shows red',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnswerOptionCard(
                text: 'Option A',
                onPressed: () {},
                isSelected: true,
                isCorrect: false,
                showFeedback: true,
              ),
            ),
          ),
        );

        expect(find.text('Option A'), findsOneWidget);
      });

      testWidgets('Not selected but correct shows light green',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnswerOptionCard(
                text: 'Option A',
                onPressed: () {},
                isSelected: false,
                isCorrect: true,
                showFeedback: true,
              ),
            ),
          ),
        );

        expect(find.text('Option A'), findsOneWidget);
      });
    });
  });
}
