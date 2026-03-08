import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/controllers/onboarding_controller.dart';

void main() {
  group('OnboardingController', () {
    test('starts at step zero and computes progress correctly', () {
      final controller = OnboardingController(totalSteps: 6);

      expect(controller.currentStep, 0);
      expect(controller.isFirstStep, true);
      expect(controller.isLastStep, false);
      expect(controller.progress, closeTo(1 / 6, 0.0001));
    });

    test('nextStep advances but never exceeds totalSteps - 1', () {
      final controller = OnboardingController(totalSteps: 3);

      controller.nextStep();
      controller.nextStep();
      controller.nextStep();

      expect(controller.currentStep, 2);
      expect(controller.isLastStep, true);
    });

    test('previousStep goes back but never below zero', () {
      final controller = OnboardingController(totalSteps: 3);

      controller.previousStep();
      expect(controller.currentStep, 0);

      controller.nextStep();
      controller.previousStep();
      controller.previousStep();

      expect(controller.currentStep, 0);
      expect(controller.isFirstStep, true);
    });

    test('goToStep ignores out-of-range values', () {
      final controller = OnboardingController(totalSteps: 4);

      controller.goToStep(2);
      expect(controller.currentStep, 2);

      controller.goToStep(-1);
      expect(controller.currentStep, 2);

      controller.goToStep(999);
      expect(controller.currentStep, 2);
    });

    test('updateUserData merges values and reset clears all', () {
      final controller = OnboardingController(totalSteps: 6);

      controller.updateUserData({'username': 'PlayerOne'});
      controller.updateUserData({'country': 'Canada'});

      expect(controller.userData['username'], 'PlayerOne');
      expect(controller.userData['country'], 'Canada');

      controller.nextStep();
      controller.reset();

      expect(controller.currentStep, 0);
      expect(controller.userData, isEmpty);
    });
  });
}
