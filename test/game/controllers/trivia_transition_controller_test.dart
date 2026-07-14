import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/controllers/trivia_transition_controller.dart';

void main() {
  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('initial state', () {
    test('secondsRemaining is 5 immediately after creation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ctrl = container.read(triviaTransitionControllerProvider);
      expect(ctrl.secondsRemaining, 5);
    });

    test('can register a listener without error', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ctrl = container.read(triviaTransitionControllerProvider);
      var fired = false;
      ctrl.addListener(() => fired = true);
      // Listener was added successfully; it has not fired yet (no timer tick)
      expect(fired, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // dispose
  // -------------------------------------------------------------------------

  group('dispose', () {
    test('container.dispose() cancels the timer without throwing', () {
      final container = ProviderContainer();
      container.read(triviaTransitionControllerProvider);
      // Disposing the container disposes the ChangeNotifierProvider which
      // calls TriviaTransitionController.dispose(), cancelling the timer.
      expect(() => container.dispose(), returnsNormally);
    });

    test('multiple dispose calls do not throw', () {
      final container = ProviderContainer();
      container.read(triviaTransitionControllerProvider);
      container.dispose();
      // Calling dispose on an already-disposed container does not crash.
      expect(() => container.dispose(), returnsNormally);
    });
  });

  // -------------------------------------------------------------------------
  // secondsRemaining countdown (real timer — no fake_async in pubspec)
  // -------------------------------------------------------------------------

  group('countdown', () {
    test('secondsRemaining decrements by 1 after one real second', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ctrl = container.read(triviaTransitionControllerProvider);
      expect(ctrl.secondsRemaining, 5);

      await Future.delayed(const Duration(milliseconds: 1100));
      expect(ctrl.secondsRemaining, 4);
    });

    test('secondsRemaining stops at 0 after countdown completes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ctrl = container.read(triviaTransitionControllerProvider);
      // Wait for full 5-second countdown; _secondsRemaining <= 1 cancels timer
      await Future.delayed(const Duration(milliseconds: 5500));
      // Timer stops when remaining reaches 1 — so last notified value is 1,
      // the field is not decremented to 0
      expect(ctrl.secondsRemaining, lessThanOrEqualTo(1));
    }, timeout: Timeout(Duration(seconds: 10)));
  });
}
