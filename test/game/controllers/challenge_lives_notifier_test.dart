import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/game/controllers/challenge_lives_notifier.dart';

void main() {
  late Directory tempDir;
  late GeneralKeyValueStorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp
        .createTemp('challenge_lives_test_');
    Hive.init(tempDir.path);
    storage = GeneralKeyValueStorageService();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  ChallengeLivesNotifier _make() => ChallengeLivesNotifier(storage);

  // -------------------------------------------------------------------------
  // ChallengeLivesState — computed properties
  // -------------------------------------------------------------------------

  group('ChallengeLivesState — canRevive', () {
    test('true when premiumRevivesUsed < premiumRevivesAllowed', () {
      const s = ChallengeLivesState(
          current: 0, max: 3, premiumRevivesUsed: 0, premiumRevivesAllowed: 1);
      expect(s.canRevive, isTrue);
    });

    test('false when premiumRevivesUsed == premiumRevivesAllowed', () {
      const s = ChallengeLivesState(
          current: 0, max: 3, premiumRevivesUsed: 1, premiumRevivesAllowed: 1);
      expect(s.canRevive, isFalse);
    });

    test('false when premiumRevivesUsed > premiumRevivesAllowed', () {
      const s = ChallengeLivesState(
          current: 0, max: 3, premiumRevivesUsed: 2, premiumRevivesAllowed: 1);
      expect(s.canRevive, isFalse);
    });
  });

  group('ChallengeLivesState — isGameOver', () {
    test('true when run active, 0 lives, and no revive', () {
      const s = ChallengeLivesState(
          current: 0,
          max: 3,
          premiumRevivesUsed: 1,
          premiumRevivesAllowed: 1,
          isRunActive: true);
      expect(s.isGameOver, isTrue);
    });

    test('false when run active, 0 lives, but revive available', () {
      const s = ChallengeLivesState(
          current: 0,
          max: 3,
          premiumRevivesUsed: 0,
          premiumRevivesAllowed: 1,
          isRunActive: true);
      expect(s.isGameOver, isFalse);
    });

    test('false when lives > 0 even with no revive', () {
      const s = ChallengeLivesState(
          current: 1,
          max: 3,
          premiumRevivesUsed: 1,
          premiumRevivesAllowed: 1,
          isRunActive: true);
      expect(s.isGameOver, isFalse);
    });

    test('false when run is not active even with 0 lives', () {
      const s = ChallengeLivesState(
          current: 0,
          max: 3,
          premiumRevivesUsed: 1,
          premiumRevivesAllowed: 1,
          isRunActive: false);
      expect(s.isGameOver, isFalse);
    });
  });

  group('ChallengeLivesState — copyWith', () {
    const base = ChallengeLivesState(
        current: 2, max: 3, premiumRevivesUsed: 0, isRunActive: true);

    test('copies current', () {
      expect(base.copyWith(current: 1).current, 1);
    });

    test('copies isRunActive', () {
      expect(base.copyWith(isRunActive: false).isRunActive, isFalse);
    });

    test('copies premiumRevivesUsed', () {
      expect(base.copyWith(premiumRevivesUsed: 1).premiumRevivesUsed, 1);
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(current: 0);
      expect(updated.max, base.max);
      expect(updated.isRunActive, base.isRunActive);
    });
  });

  // -------------------------------------------------------------------------
  // ChallengeLivesNotifier — constants
  // -------------------------------------------------------------------------

  group('Constants', () {
    test('kChallengeLivesPerRun == 3', () {
      expect(kChallengeLivesPerRun, 3);
    });

    test('kPremiumRevivesPerRun == 1', () {
      expect(kPremiumRevivesPerRun, 1);
    });
  });

  // -------------------------------------------------------------------------
  // ChallengeLivesNotifier — initial state
  // -------------------------------------------------------------------------

  group('ChallengeLivesNotifier — initial state', () {
    test('starts with kChallengeLivesPerRun lives', () {
      final notifier = _make();
      expect(notifier.state.current, kChallengeLivesPerRun);
    });

    test('starts with isRunActive = false', () {
      final notifier = _make();
      expect(notifier.state.isRunActive, isFalse);
    });

    test('starts with 0 premium revives used', () {
      final notifier = _make();
      expect(notifier.state.premiumRevivesUsed, 0);
    });
  });

  // -------------------------------------------------------------------------
  // ChallengeLivesNotifier — startRun
  // -------------------------------------------------------------------------

  group('ChallengeLivesNotifier — startRun', () {
    test('sets isRunActive to true', () {
      final notifier = _make();
      notifier.startRun();
      expect(notifier.state.isRunActive, isTrue);
    });

    test('resets lives to kChallengeLivesPerRun', () {
      final notifier = _make();
      notifier.startRun();
      expect(notifier.state.current, kChallengeLivesPerRun);
    });

    test('resets premiumRevivesUsed to 0', () {
      final notifier = _make();
      notifier.startRun();
      notifier.loseLife();
      notifier.loseLife();
      notifier.loseLife();
      notifier.useRevive();
      expect(notifier.state.premiumRevivesUsed, 1);
      notifier.startRun();
      expect(notifier.state.premiumRevivesUsed, 0);
    });

    test('restores to kPremiumRevivesPerRun allowed', () {
      final notifier = _make();
      notifier.startRun();
      expect(notifier.state.premiumRevivesAllowed, kPremiumRevivesPerRun);
    });
  });

  // -------------------------------------------------------------------------
  // ChallengeLivesNotifier — endRun
  // -------------------------------------------------------------------------

  group('ChallengeLivesNotifier — endRun', () {
    test('sets isRunActive to false', () {
      final notifier = _make();
      notifier.startRun();
      notifier.endRun();
      expect(notifier.state.isRunActive, isFalse);
    });

    test('resets lives to kChallengeLivesPerRun', () {
      final notifier = _make();
      notifier.startRun();
      notifier.loseLife();
      notifier.endRun();
      expect(notifier.state.current, kChallengeLivesPerRun);
    });
  });

  // -------------------------------------------------------------------------
  // ChallengeLivesNotifier — loseLife
  // -------------------------------------------------------------------------

  group('ChallengeLivesNotifier — loseLife', () {
    test('returns false when run is not active', () {
      final notifier = _make();
      expect(notifier.loseLife(), isFalse);
    });

    test('decrements current by 1', () {
      final notifier = _make();
      notifier.startRun();
      notifier.loseLife();
      expect(notifier.state.current, kChallengeLivesPerRun - 1);
    });

    test('returns true when lives remain after losing', () {
      final notifier = _make();
      notifier.startRun();
      expect(notifier.loseLife(), isTrue); // 3→2
    });

    test('returns false when lives reach 0', () {
      final notifier = _make();
      notifier.startRun();
      notifier.loseLife(); // 3→2
      notifier.loseLife(); // 2→1
      final result = notifier.loseLife(); // 1→0
      expect(result, isFalse);
      expect(notifier.state.current, 0);
    });

    test('does not go below 0', () {
      final notifier = _make();
      notifier.startRun();
      notifier.loseLife();
      notifier.loseLife();
      notifier.loseLife();
      notifier.loseLife(); // should clamp at 0
      expect(notifier.state.current, 0);
    });
  });

  // -------------------------------------------------------------------------
  // ChallengeLivesNotifier — useRevive
  // -------------------------------------------------------------------------

  group('ChallengeLivesNotifier — useRevive', () {
    test('returns false when run is not active', () {
      final notifier = _make();
      expect(notifier.useRevive(), isFalse);
    });

    test('returns false when no revive available', () {
      final notifier = _make();
      notifier.startRun();
      notifier.useRevive(); // uses the one available
      expect(notifier.useRevive(), isFalse);
    });

    test('returns true when revive is available', () {
      final notifier = _make();
      notifier.startRun();
      notifier.loseLife();
      notifier.loseLife();
      notifier.loseLife(); // 0 lives
      expect(notifier.useRevive(), isTrue);
    });

    test('restores lives to kChallengeLivesPerRun', () {
      final notifier = _make();
      notifier.startRun();
      notifier.loseLife();
      notifier.loseLife();
      notifier.useRevive();
      expect(notifier.state.current, kChallengeLivesPerRun);
    });

    test('increments premiumRevivesUsed', () {
      final notifier = _make();
      notifier.startRun();
      notifier.useRevive();
      expect(notifier.state.premiumRevivesUsed, 1);
    });

    test('canRevive is false after using the single allowed revive', () {
      final notifier = _make();
      notifier.startRun();
      notifier.useRevive();
      expect(notifier.state.canRevive, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // ChallengeLivesNotifier — isGameOver integration
  // -------------------------------------------------------------------------

  group('ChallengeLivesNotifier — isGameOver integration', () {
    test('game over when out of lives and revive used', () {
      final notifier = _make();
      notifier.startRun();
      notifier.loseLife();
      notifier.loseLife();
      notifier.loseLife(); // 0 lives
      notifier.useRevive(); // uses revive, back to 3
      notifier.loseLife();
      notifier.loseLife();
      notifier.loseLife(); // 0 lives again
      expect(notifier.state.isGameOver, isTrue);
    });

    test('not game over when lives remain', () {
      final notifier = _make();
      notifier.startRun();
      notifier.loseLife();
      expect(notifier.state.isGameOver, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // ChallengeLivesNotifier — loadRunState
  // -------------------------------------------------------------------------

  group('ChallengeLivesNotifier — loadRunState', () {
    test('restores persisted run state', () async {
      final notifier1 = _make();
      notifier1.startRun();
      notifier1.loseLife(); // 3→2
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier2 = _make();
      await notifier2.loadRunState();
      expect(notifier2.state.current, 2);
      expect(notifier2.state.isRunActive, isTrue);
    });

    test('defaults to kChallengeLivesPerRun when nothing persisted', () async {
      final notifier = _make();
      await notifier.loadRunState();
      expect(notifier.state.current, kChallengeLivesPerRun);
    });
  });
}
