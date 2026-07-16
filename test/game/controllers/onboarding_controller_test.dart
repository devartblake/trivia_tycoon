import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/controllers/onboarding_controller.dart';

void main() {
  ModernOnboardingController makeController({int totalSteps = 5}) =>
      ModernOnboardingController(totalSteps: totalSteps);

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('initial state', () {
    test('currentStep is 0', () {
      expect(makeController().currentStep, 0);
    });

    test('isFirstStep is true', () {
      expect(makeController().isFirstStep, isTrue);
    });

    test('isLastStep is false when totalSteps > 1', () {
      expect(makeController().isLastStep, isFalse);
    });

    test('progress is 1/totalSteps on step 0', () {
      expect(makeController(totalSteps: 5).progress, closeTo(0.2, 0.001));
    });

    test('userData is empty', () {
      expect(makeController().userData, isEmpty);
    });

    test('all typed getters return null initially', () {
      final ctrl = makeController();
      expect(ctrl.username, isNull);
      expect(ctrl.ageGroup, isNull);
      expect(ctrl.intent, isNull);
      expect(ctrl.playStyle, isNull);
      expect(ctrl.synaptixMode, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // nextStep
  // -------------------------------------------------------------------------

  group('nextStep', () {
    test('increments currentStep by 1', () {
      final ctrl = makeController();
      ctrl.nextStep();
      expect(ctrl.currentStep, 1);
    });

    test('isFirstStep becomes false after first nextStep', () {
      final ctrl = makeController();
      ctrl.nextStep();
      expect(ctrl.isFirstStep, isFalse);
    });

    test('isLastStep true at step totalSteps - 1', () {
      final ctrl = makeController(totalSteps: 3);
      ctrl.nextStep();
      ctrl.nextStep();
      expect(ctrl.isLastStep, isTrue);
    });

    test('does not exceed totalSteps - 1', () {
      final ctrl = makeController(totalSteps: 3);
      ctrl.nextStep();
      ctrl.nextStep();
      ctrl.nextStep(); // at last step, no-op
      expect(ctrl.currentStep, 2);
    });

    test('notifies listeners on advance', () {
      final ctrl = makeController();
      var count = 0;
      ctrl.addListener(() => count++);
      ctrl.nextStep();
      expect(count, 1);
    });

    test('does not notify when already at last step', () {
      final ctrl = makeController(totalSteps: 1);
      var count = 0;
      ctrl.addListener(() => count++);
      ctrl.nextStep(); // already at last step (0 == totalSteps - 1)
      expect(count, 0);
    });
  });

  // -------------------------------------------------------------------------
  // previousStep
  // -------------------------------------------------------------------------

  group('previousStep', () {
    test('decrements currentStep by 1', () {
      final ctrl = makeController();
      ctrl.nextStep();
      ctrl.previousStep();
      expect(ctrl.currentStep, 0);
    });

    test('does not go below 0', () {
      final ctrl = makeController();
      ctrl.previousStep(); // already at 0
      expect(ctrl.currentStep, 0);
    });

    test('does not notify when at step 0', () {
      final ctrl = makeController();
      var count = 0;
      ctrl.addListener(() => count++);
      ctrl.previousStep();
      expect(count, 0);
    });

    test('notifies listeners on decrement', () {
      final ctrl = makeController();
      ctrl.nextStep();
      var count = 0;
      ctrl.addListener(() => count++);
      ctrl.previousStep();
      expect(count, 1);
    });
  });

  // -------------------------------------------------------------------------
  // goToStep
  // -------------------------------------------------------------------------

  group('goToStep', () {
    test('jumps to a valid step', () {
      final ctrl = makeController(totalSteps: 10);
      ctrl.goToStep(7);
      expect(ctrl.currentStep, 7);
    });

    test('notifies listeners on valid jump', () {
      final ctrl = makeController(totalSteps: 10);
      var count = 0;
      ctrl.addListener(() => count++);
      ctrl.goToStep(5);
      expect(count, 1);
    });

    test('silently ignores negative step', () {
      final ctrl = makeController(totalSteps: 5);
      ctrl.nextStep(); // go to step 1 first
      ctrl.goToStep(-1);
      expect(ctrl.currentStep, 1); // unchanged
    });

    test('silently ignores step >= totalSteps', () {
      final ctrl = makeController(totalSteps: 5);
      ctrl.goToStep(5); // out of range (valid: 0..4)
      expect(ctrl.currentStep, 0); // unchanged
    });

    test('does not notify when step is out of range', () {
      final ctrl = makeController(totalSteps: 5);
      var count = 0;
      ctrl.addListener(() => count++);
      ctrl.goToStep(99);
      expect(count, 0);
    });

    test('goToStep(0) goes to first step', () {
      final ctrl = makeController();
      ctrl.nextStep();
      ctrl.goToStep(0);
      expect(ctrl.isFirstStep, isTrue);
    });

    test('goToStep(totalSteps-1) sets isLastStep', () {
      final ctrl = makeController(totalSteps: 5);
      ctrl.goToStep(4);
      expect(ctrl.isLastStep, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // progress computation
  // -------------------------------------------------------------------------

  group('progress', () {
    test('progress at step 0 with totalSteps 5 is 0.2', () {
      expect(makeController(totalSteps: 5).progress, closeTo(0.2, 0.001));
    });

    test('progress at last step is 1.0', () {
      final ctrl = makeController(totalSteps: 5);
      ctrl.goToStep(4);
      expect(ctrl.progress, closeTo(1.0, 0.001));
    });

    test('progress at step 2 with totalSteps 5 is 0.6', () {
      final ctrl = makeController(totalSteps: 5);
      ctrl.goToStep(2);
      expect(ctrl.progress, closeTo(0.6, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // updateUserData
  // -------------------------------------------------------------------------

  group('updateUserData', () {
    test('merges new keys into userData', () {
      final ctrl = makeController();
      ctrl.updateUserData({'username': 'alice', 'ageGroup': 'teens'});
      expect(ctrl.userData['username'], 'alice');
      expect(ctrl.userData['ageGroup'], 'teens');
    });

    test('preserves existing keys when merging', () {
      final ctrl = makeController();
      ctrl.updateUserData({'username': 'alice'});
      ctrl.updateUserData({'ageGroup': 'teens'});
      expect(ctrl.userData['username'], 'alice'); // preserved
      expect(ctrl.userData['ageGroup'], 'teens');
    });

    test('overwrites existing key on merge', () {
      final ctrl = makeController();
      ctrl.updateUserData({'username': 'alice'});
      ctrl.updateUserData({'username': 'bob'});
      expect(ctrl.userData['username'], 'bob');
    });

    test('notifies listeners', () {
      final ctrl = makeController();
      var count = 0;
      ctrl.addListener(() => count++);
      ctrl.updateUserData({'k': 'v'});
      expect(count, 1);
    });
  });

  // -------------------------------------------------------------------------
  // setField
  // -------------------------------------------------------------------------

  group('setField', () {
    test('stores value accessible via userData', () {
      final ctrl = makeController();
      ctrl.setField('username', 'charlie');
      expect(ctrl.userData['username'], 'charlie');
    });

    test('typed getter username reads from setField', () {
      final ctrl = makeController();
      ctrl.setField('username', 'dave');
      expect(ctrl.username, 'dave');
    });

    test('typed getter ageGroup reads from setField', () {
      final ctrl = makeController();
      ctrl.setField('ageGroup', 'adults');
      expect(ctrl.ageGroup, 'adults');
    });

    test('typed getter intent reads from setField', () {
      final ctrl = makeController();
      ctrl.setField('intent', 'fun');
      expect(ctrl.intent, 'fun');
    });

    test('typed getter playStyle reads from setField', () {
      final ctrl = makeController();
      ctrl.setField('playStyle', 'casual');
      expect(ctrl.playStyle, 'casual');
    });

    test('typed getter synaptixMode reads from setField', () {
      final ctrl = makeController();
      ctrl.setField('synaptixMode', 'focus');
      expect(ctrl.synaptixMode, 'focus');
    });

    test('typed getter returns null for non-string value', () {
      final ctrl = makeController();
      ctrl.setField('username', 42); // int, not String
      expect(ctrl.username, isNull);
    });

    test('notifies listeners', () {
      final ctrl = makeController();
      var count = 0;
      ctrl.addListener(() => count++);
      ctrl.setField('k', 'v');
      expect(count, 1);
    });
  });

  // -------------------------------------------------------------------------
  // reset
  // -------------------------------------------------------------------------

  group('reset', () {
    test('resets currentStep to 0', () {
      final ctrl = makeController();
      ctrl.goToStep(3);
      ctrl.reset();
      expect(ctrl.currentStep, 0);
    });

    test('clears userData', () {
      final ctrl = makeController();
      ctrl.updateUserData({'username': 'alice', 'ageGroup': 'teens'});
      ctrl.reset();
      expect(ctrl.userData, isEmpty);
    });

    test('typed getters return null after reset', () {
      final ctrl = makeController();
      ctrl.setField('username', 'alice');
      ctrl.reset();
      expect(ctrl.username, isNull);
    });

    test('isFirstStep true after reset', () {
      final ctrl = makeController();
      ctrl.goToStep(4);
      ctrl.reset();
      expect(ctrl.isFirstStep, isTrue);
    });

    test('notifies listeners', () {
      final ctrl = makeController();
      var count = 0;
      ctrl.addListener(() => count++);
      ctrl.reset();
      expect(count, 1);
    });
  });
}
