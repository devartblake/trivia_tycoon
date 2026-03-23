// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/controllers/energy_notifier.dart';
import 'package:trivia_tycoon/game/controllers/challenge_lives_notifier.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';

// ---------------------------------------------------------------------------
// Fake in-memory storage (no Hive required in unit tests)
// ---------------------------------------------------------------------------

class _FakeStorage extends GeneralKeyValueStorageService {
  final Map<String, dynamic> _store = {};

  @override
  Future<dynamic> get(String key) async => _store[key];

  @override
  Future<int> getInt(String key) async {
    final v = _store[key];
    return v is int ? v : 0;
  }

  @override
  Future<void> setInt(String key, int value) async => _store[key] = value;

  @override
  Future<String?> getString(String key) async {
    final v = _store[key];
    return v is String ? v : null;
  }

  @override
  Future<void> setString(String key, String value) async =>
      _store[key] = value;

  @override
  Future<bool?> getBool(String key) async {
    final v = _store[key];
    return v is bool ? v : null;
  }

  @override
  Future<void> setBool(String key, bool value) async => _store[key] = value;
}

// ---------------------------------------------------------------------------
// EnergyState unit tests
// ---------------------------------------------------------------------------

void main() {
  // ── EnergyState ────────────────────────────────────────────────────────────

  group('EnergyState defaults', () {
    test('kEnergyMax is 20', () {
      expect(kEnergyMax, 20);
    });

    test('kEnergyRefillInterval is 10 minutes', () {
      expect(kEnergyRefillInterval, const Duration(minutes: 10));
    });

    test('kEnergyCasualCost is 3', () {
      expect(kEnergyCasualCost, 3);
    });

    test('kEnergyRankedCost is 4', () {
      expect(kEnergyRankedCost, 4);
    });

    test('kEnergyPracticeCost is 1', () {
      expect(kEnergyPracticeCost, 1);
    });

    test('initial state starts full at max (20/20)', () {
      const state = EnergyState(current: kEnergyMax, max: kEnergyMax);
      expect(state.current, kEnergyMax);
      expect(state.max, kEnergyMax);
    });

    test('copyWith preserves unchanged fields', () {
      const original = EnergyState(current: 10, max: kEnergyMax);
      final copy = original.copyWith(current: 15);
      expect(copy.current, 15);
      expect(copy.max, kEnergyMax);
      expect(copy.refillInterval, kEnergyRefillInterval);
    });
  });

  // ── EnergyNotifier ─────────────────────────────────────────────────────────

  group('EnergyNotifier', () {
    late _FakeStorage storage;
    late EnergyNotifier notifier;

    setUp(() {
      storage = _FakeStorage();
      notifier = EnergyNotifier(storage);
    });

    tearDown(() => notifier.dispose());

    test('initialises with full energy (20/20)', () {
      expect(notifier.state.current, kEnergyMax);
      expect(notifier.state.max, kEnergyMax);
    });

    test('canPlayCasual is true when energy >= 3', () {
      expect(notifier.canPlayCasual, isTrue);
    });

    test('canPlayRanked is true when energy >= 4', () {
      expect(notifier.canPlayRanked, isTrue);
    });

    test('canPlayPractice is true when energy >= 1', () {
      expect(notifier.canPlayPractice, isTrue);
    });

    test('useCasualEnergy deducts 3', () {
      final success = notifier.useCasualEnergy();
      expect(success, isTrue);
      expect(notifier.state.current, kEnergyMax - kEnergyCasualCost);
    });

    test('useRankedEnergy deducts 4', () {
      final success = notifier.useRankedEnergy();
      expect(success, isTrue);
      expect(notifier.state.current, kEnergyMax - kEnergyRankedCost);
    });

    test('usePracticeEnergy deducts 1', () {
      final success = notifier.usePracticeEnergy();
      expect(success, isTrue);
      expect(notifier.state.current, kEnergyMax - kEnergyPracticeCost);
    });

    test('useEnergy returns false and does not deduct when insufficient', () {
      // Drain all energy first
      notifier.useEnergy(kEnergyMax);
      expect(notifier.state.current, 0);

      final result = notifier.useEnergy(1);
      expect(result, isFalse);
      expect(notifier.state.current, 0);
    });

    test('canPlayCasual is false when energy < 3', () {
      notifier.useEnergy(kEnergyMax - 2); // leave 2
      expect(notifier.canPlayCasual, isFalse);
    });

    test('canPlayRanked is false when energy < 4', () {
      notifier.useEnergy(kEnergyMax - 3); // leave 3
      expect(notifier.canPlayRanked, isFalse);
    });

    test('addEnergy clamps to max', () {
      notifier.addEnergy(100);
      expect(notifier.state.current, kEnergyMax);
    });

    test('addEnergy increases energy correctly', () {
      notifier.useEnergy(5);
      notifier.addEnergy(3);
      expect(notifier.state.current, kEnergyMax - 5 + 3);
    });

    test('energy does not exceed max after multiple additions', () {
      notifier.useEnergy(1);
      notifier.addEnergy(50);
      expect(notifier.state.current, kEnergyMax);
    });

    test('refillInterval matches kEnergyRefillInterval', () {
      expect(notifier.state.refillInterval, kEnergyRefillInterval);
    });
  });

  // ── ChallengeLivesState defaults ──────────────────────────────────────────

  group('ChallengeLivesState defaults', () {
    test('kChallengeLivesPerRun is 3', () {
      expect(kChallengeLivesPerRun, 3);
    });

    test('kPremiumRevivesPerRun is 1', () {
      expect(kPremiumRevivesPerRun, 1);
    });

    test('initial state is not in an active run', () {
      const state = ChallengeLivesState(
        current: kChallengeLivesPerRun,
        max: kChallengeLivesPerRun,
      );
      expect(state.isRunActive, isFalse);
    });

    test('canRevive is true when premiumRevivesUsed < premiumRevivesAllowed', () {
      const state = ChallengeLivesState(
        current: 0,
        max: kChallengeLivesPerRun,
        premiumRevivesUsed: 0,
        premiumRevivesAllowed: kPremiumRevivesPerRun,
      );
      expect(state.canRevive, isTrue);
    });

    test('canRevive is false when all revives used', () {
      const state = ChallengeLivesState(
        current: 0,
        max: kChallengeLivesPerRun,
        premiumRevivesUsed: kPremiumRevivesPerRun,
        premiumRevivesAllowed: kPremiumRevivesPerRun,
      );
      expect(state.canRevive, isFalse);
    });

    test('isGameOver is true when no lives and no revive', () {
      const state = ChallengeLivesState(
        current: 0,
        max: kChallengeLivesPerRun,
        premiumRevivesUsed: kPremiumRevivesPerRun,
        premiumRevivesAllowed: kPremiumRevivesPerRun,
        isRunActive: true,
      );
      expect(state.isGameOver, isTrue);
    });

    test('isGameOver is false when lives remain', () {
      const state = ChallengeLivesState(
        current: 2,
        max: kChallengeLivesPerRun,
        isRunActive: true,
      );
      expect(state.isGameOver, isFalse);
    });

    test('isGameOver is false when no lives but run is not active', () {
      const state = ChallengeLivesState(
        current: 0,
        max: kChallengeLivesPerRun,
        premiumRevivesUsed: kPremiumRevivesPerRun,
        premiumRevivesAllowed: kPremiumRevivesPerRun,
        isRunActive: false, // not in a run
      );
      expect(state.isGameOver, isFalse);
    });

    test('isGameOver is false when revive is available even with 0 lives', () {
      const state = ChallengeLivesState(
        current: 0,
        max: kChallengeLivesPerRun,
        premiumRevivesUsed: 0,
        premiumRevivesAllowed: kPremiumRevivesPerRun,
        isRunActive: true,
      );
      expect(state.isGameOver, isFalse);
    });
  });

  // ── ChallengeLivesNotifier ────────────────────────────────────────────────

  group('ChallengeLivesNotifier', () {
    late _FakeStorage storage;
    late ChallengeLivesNotifier notifier;

    setUp(() {
      storage = _FakeStorage();
      notifier = ChallengeLivesNotifier(storage);
    });

    tearDown(() => notifier.dispose());

    test('initialises with 3 lives and no active run', () {
      expect(notifier.state.current, kChallengeLivesPerRun);
      expect(notifier.state.max, kChallengeLivesPerRun);
      expect(notifier.state.isRunActive, isFalse);
    });

    test('startRun activates run with full lives', () {
      notifier.startRun();
      expect(notifier.state.isRunActive, isTrue);
      expect(notifier.state.current, kChallengeLivesPerRun);
      expect(notifier.state.premiumRevivesUsed, 0);
    });

    test('loseLife decrements current lives', () {
      notifier.startRun();
      notifier.loseLife();
      expect(notifier.state.current, kChallengeLivesPerRun - 1);
    });

    test('loseLife returns true while lives remain', () {
      notifier.startRun();
      expect(notifier.loseLife(), isTrue);
    });

    test('loseLife returns false when lives reach zero', () {
      notifier.startRun();
      notifier.loseLife();
      notifier.loseLife();
      final result = notifier.loseLife(); // 3rd loss → 0 lives
      expect(result, isFalse);
      expect(notifier.state.current, 0);
    });

    test('loseLife does nothing when run is not active', () {
      expect(notifier.state.isRunActive, isFalse);
      final result = notifier.loseLife();
      expect(result, isFalse);
      expect(notifier.state.current, kChallengeLivesPerRun);
    });

    test('useRevive restores lives to max and increments revivesUsed', () {
      notifier.startRun();
      notifier.loseLife();
      notifier.loseLife();
      notifier.loseLife(); // 0 lives

      expect(notifier.state.canRevive, isTrue);
      final revived = notifier.useRevive();
      expect(revived, isTrue);
      expect(notifier.state.current, kChallengeLivesPerRun);
      expect(notifier.state.premiumRevivesUsed, 1);
    });

    test('useRevive returns false when no revives available', () {
      notifier.startRun();
      notifier.loseLife();
      notifier.loseLife();
      notifier.loseLife();
      notifier.useRevive(); // use the one revive

      notifier.loseLife();
      notifier.loseLife();
      notifier.loseLife(); // 0 lives again
      final result = notifier.useRevive();
      expect(result, isFalse);
      expect(notifier.state.premiumRevivesUsed, kPremiumRevivesPerRun);
    });

    test('useRevive returns false when run is not active', () {
      final result = notifier.useRevive();
      expect(result, isFalse);
    });

    test('endRun resets to idle state with full lives', () {
      notifier.startRun();
      notifier.loseLife();
      notifier.endRun();

      expect(notifier.state.isRunActive, isFalse);
      expect(notifier.state.current, kChallengeLivesPerRun);
    });

    test('startRun resets revives used from a previous run', () {
      notifier.startRun();
      notifier.loseLife();
      notifier.loseLife();
      notifier.loseLife();
      notifier.useRevive();

      notifier.endRun();
      notifier.startRun(); // new run

      expect(notifier.state.premiumRevivesUsed, 0);
      expect(notifier.state.canRevive, isTrue);
    });

    test('lives do not go below zero', () {
      notifier.startRun();
      for (int i = 0; i < kChallengeLivesPerRun + 5; i++) {
        notifier.loseLife();
      }
      expect(notifier.state.current, 0);
    });
  });
}
