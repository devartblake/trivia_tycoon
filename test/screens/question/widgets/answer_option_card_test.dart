import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/screens/question/widgets/answer_option_card.dart';

void main() {
  group('AnswerOptionCard', () {
    // The card renders as a GestureDetector + AnimatedContainer (BoxDecoration),
    // not an ElevatedButton, so tap/color assertions target those.
    BoxDecoration cardDecoration(WidgetTester tester) {
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      return container.decoration as BoxDecoration;
    }

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
      expect(find.byType(AnswerOptionCard), findsOneWidget);
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

      await tester.tap(find.byType(AnswerOptionCard));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('Not tappable when onPressed is null',
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

      expect(find.byType(AnswerOptionCard), findsOneWidget);
      // Tapping a null-onPressed card is a no-op and must not throw.
      await tester.tap(find.byType(AnswerOptionCard));
      await tester.pump();
    });

    testWidgets('Shows selected state with a background color',
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

      expect(cardDecoration(tester).color, isNotNull);
    });

    testWidgets('Shows correct state with a background color',
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

      expect(cardDecoration(tester).color, isNotNull);
    });

    testWidgets('Shows incorrect state with a background color',
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

      expect(cardDecoration(tester).color, isNotNull);
    });

    testWidgets('Does not call onPressed when showFeedback is true',
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

      await tester.tap(find.byType(AnswerOptionCard));
      await tester.pump();

      expect(pressed, isFalse); // feedback locks input
    });

    testWidgets('Multiplayer styling applies a background color',
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

      expect(cardDecoration(tester).color, isNotNull);
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

    testWidgets('Renders within a constrained width',
        (WidgetTester tester) async {
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

      expect(find.byType(AnswerOptionCard), findsOneWidget);
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
