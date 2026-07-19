import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/settings/general_key_value_storage_service.dart';
import 'package:synaptix/game/controllers/energy_notifier.dart';

import '../../support/hive_test_env.dart';

void main() {
  late HiveTestEnv hiveEnv;
  late GeneralKeyValueStorageService storage;

  setUp(() async {
    // HiveTestEnv leaves the temp dir in place on dispose so EnergyNotifier's
    // fire-and-forget persists don't race a dir delete into PathNotFound.
    hiveEnv = await HiveTestEnv.create(boxes: ['settings']);
    storage = GeneralKeyValueStorageService();
  });

  tearDown(() async {
    // Let any fire-and-forget _loadEnergyState/_saveEnergyState finish touching
    // the box before it is closed, so they don't throw "Box has already been
    // closed" into the next test.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await hiveEnv.dispose();
  });

  EnergyNotifier makeNotifier() => EnergyNotifier(storage);

  // -------------------------------------------------------------------------
  // EnergyState — copyWith
  // -------------------------------------------------------------------------

  group('EnergyState — copyWith', () {
    test('updates current energy', () {
      const original = EnergyState(current: 10, max: 20);
      final updated = original.copyWith(current: 5);
      expect(updated.current, 5);
      expect(updated.max, 20); // unchanged
    });

    test('updates max energy', () {
      const original = EnergyState(current: 10, max: 20);
      final updated = original.copyWith(max: 30);
      expect(updated.max, 30);
      expect(updated.current, 10); // unchanged
    });

    test('updates refillInterval', () {
      const original = EnergyState(current: 10, max: 20);
      final updated =
          original.copyWith(refillInterval: const Duration(minutes: 5));
      expect(updated.refillInterval, const Duration(minutes: 5));
    });

    test('updates lastRefillTime', () {
      const original = EnergyState(current: 10, max: 20);
      final now = DateTime.now();
      final updated = original.copyWith(lastRefillTime: now);
      expect(updated.lastRefillTime, now);
    });

    test('preserves all unchanged fields', () {
      final now = DateTime.now();
      final state = EnergyState(
        current: 15,
        max: 20,
        lastRefillTime: now,
        refillInterval: const Duration(minutes: 10),
      );
      final updated = state.copyWith(current: 10);
      expect(updated.max, 20);
      expect(updated.lastRefillTime, now);
      expect(updated.refillInterval, const Duration(minutes: 10));
    });
  });

  // -------------------------------------------------------------------------
  // EnergyNotifier — initial state
  // -------------------------------------------------------------------------

  group('EnergyNotifier — initial state', () {
    test('starts at kEnergyMax', () {
      final notifier = makeNotifier();
      expect(notifier.state.current, kEnergyMax);
      notifier.dispose();
    });

    test('max equals kEnergyMax', () {
      final notifier = makeNotifier();
      expect(notifier.state.max, kEnergyMax);
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // EnergyNotifier — canPlay* getters
  // -------------------------------------------------------------------------

  group('EnergyNotifier — canPlay getters', () {
    test('canPlayCasual is true when energy >= kEnergyCasualCost', () {
      final notifier = makeNotifier();
      expect(notifier.canPlayCasual, isTrue);
      notifier.dispose();
    });

    test('canPlayRanked is true when energy >= kEnergyRankedCost', () {
      final notifier = makeNotifier();
      expect(notifier.canPlayRanked, isTrue);
      notifier.dispose();
    });

    test('canPlayPractice is true when energy >= kEnergyPracticeCost', () {
      final notifier = makeNotifier();
      expect(notifier.canPlayPractice, isTrue);
      notifier.dispose();
    });

    test('canPlayCasual is false when energy is below cost', () {
      final notifier = makeNotifier();
      // Use all energy first
      notifier.useEnergy(kEnergyMax);
      expect(notifier.canPlayCasual, isFalse);
      notifier.dispose();
    });

    test('canPlayRanked is false when energy is 0', () {
      final notifier = makeNotifier();
      notifier.useEnergy(kEnergyMax);
      expect(notifier.canPlayRanked, isFalse);
      notifier.dispose();
    });

    test('canPlayPractice is false when energy is 0', () {
      final notifier = makeNotifier();
      notifier.useEnergy(kEnergyMax);
      expect(notifier.canPlayPractice, isFalse);
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // EnergyNotifier — useEnergy
  // -------------------------------------------------------------------------

  group('EnergyNotifier — useEnergy', () {
    test('deducts energy and returns true when sufficient', () {
      final notifier = makeNotifier();
      final result = notifier.useEnergy(5);
      expect(result, isTrue);
      expect(notifier.state.current, kEnergyMax - 5);
      notifier.dispose();
    });

    test('returns false and does not deduct when insufficient', () {
      final notifier = makeNotifier();
      notifier.useEnergy(kEnergyMax); // drain to 0
      final result = notifier.useEnergy(1);
      expect(result, isFalse);
      expect(notifier.state.current, 0);
      notifier.dispose();
    });

    test('exact cost deduction succeeds', () {
      final notifier = makeNotifier();
      final result = notifier.useEnergy(kEnergyMax);
      expect(result, isTrue);
      expect(notifier.state.current, 0);
      notifier.dispose();
    });

    test('useCasualEnergy deducts kEnergyCasualCost', () {
      final notifier = makeNotifier();
      final before = notifier.state.current;
      notifier.useCasualEnergy();
      expect(notifier.state.current, before - kEnergyCasualCost);
      notifier.dispose();
    });

    test('useRankedEnergy deducts kEnergyRankedCost', () {
      final notifier = makeNotifier();
      final before = notifier.state.current;
      notifier.useRankedEnergy();
      expect(notifier.state.current, before - kEnergyRankedCost);
      notifier.dispose();
    });

    test('usePracticeEnergy deducts kEnergyPracticeCost', () {
      final notifier = makeNotifier();
      final before = notifier.state.current;
      notifier.usePracticeEnergy();
      expect(notifier.state.current, before - kEnergyPracticeCost);
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // EnergyNotifier — addEnergy
  // -------------------------------------------------------------------------

  group('EnergyNotifier — addEnergy', () {
    test('adds energy up to max', () {
      final notifier = makeNotifier();
      notifier.useEnergy(5);
      notifier.addEnergy(3);
      expect(notifier.state.current, kEnergyMax - 2);
      notifier.dispose();
    });

    test('clamped at max: adding excess energy stays at max', () {
      final notifier = makeNotifier();
      notifier.addEnergy(100); // already at max
      expect(notifier.state.current, kEnergyMax);
      notifier.dispose();
    });

    test('adds energy from 0 back up to max', () {
      final notifier = makeNotifier();
      notifier.useEnergy(kEnergyMax);
      expect(notifier.state.current, 0);
      notifier.addEnergy(kEnergyMax);
      expect(notifier.state.current, kEnergyMax);
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // EnergyNotifier — syncWithServer
  // -------------------------------------------------------------------------

  group('EnergyNotifier — syncWithServer', () {
    test('sets state from server values', () {
      final notifier = makeNotifier();
      notifier.syncWithServer(12, 25, const Duration(minutes: 5));
      expect(notifier.state.current, 12);
      expect(notifier.state.max, 25);
      expect(notifier.state.refillInterval, const Duration(minutes: 5));
      notifier.dispose();
    });

    test('clamps server energy to server max', () {
      final notifier = makeNotifier();
      notifier.syncWithServer(30, 20, const Duration(minutes: 10));
      // 30 > max of 20, so clamped to 20
      expect(notifier.state.current, 20);
      notifier.dispose();
    });

    test('clamps negative server energy to 0', () {
      final notifier = makeNotifier();
      notifier.syncWithServer(-5, 20, const Duration(minutes: 10));
      expect(notifier.state.current, 0);
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // EnergyNotifier — constants
  // -------------------------------------------------------------------------

  group('Energy constants', () {
    test('kEnergyMax is positive', () => expect(kEnergyMax, greaterThan(0)));
    test('kEnergyCasualCost < kEnergyMax',
        () => expect(kEnergyCasualCost, lessThan(kEnergyMax)));
    test(
        'kEnergyRankedCost >= kEnergyCasualCost',
        () =>
            expect(kEnergyRankedCost, greaterThanOrEqualTo(kEnergyCasualCost)));
    test('kEnergyPracticeCost is positive',
        () => expect(kEnergyPracticeCost, greaterThan(0)));
  });
}
