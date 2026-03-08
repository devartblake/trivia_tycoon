import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/controllers/onboarding_controller.dart';
import 'package:trivia_tycoon/screens/onboarding/steps/completion_step.dart';
import 'package:trivia_tycoon/screens/onboarding/steps/welcome_step.dart';

void main() {
  testWidgets('welcome step advances controller when tapping Get Started', (
    tester,
  ) async {
    final controller = OnboardingController(totalSteps: 6);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WelcomeStep(controller: controller)),
      ),
    );

    expect(controller.currentStep, 0);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(controller.currentStep, 1);
  });

  testWidgets('completion step calls onComplete callback', (tester) async {
    final controller = OnboardingController(totalSteps: 6)
      ..updateUserData({
        'username': 'WidgetUser',
        'ageGroup': '18_24',
        'country': 'Canada',
        'categories': ['science'],
      });

    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompletionStep(
            controller: controller,
            onComplete: () => completed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start Playing!'));
    await tester.pumpAndSettle();

    expect(completed, true);
  });
}
