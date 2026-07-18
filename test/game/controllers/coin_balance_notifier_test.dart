import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/settings/general_key_value_storage_service.dart';
import 'package:synaptix/game/controllers/coin_balance_notifier.dart';

import '../../support/hive_test_env.dart';

void main() {
  late HiveTestEnv hiveEnv;
  late GeneralKeyValueStorageService storage;

  setUp(() async {
    // Close-only dispose (no dir delete) avoids racing the notifier's
    // fire-and-forget persist into PathNotFoundException.
    hiveEnv = await HiveTestEnv.create();
    storage = GeneralKeyValueStorageService();
  });

  tearDown(() async {
    await hiveEnv.dispose();
  });

  CoinBalanceNotifier makeNotifier() => CoinBalanceNotifier(storage);

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('CoinBalanceNotifier — initial state', () {
    test('starts at 0', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      expect(notifier.state, 0);
    });

    test('canAfford(0) is always true', () {
      expect(makeNotifier().canAfford(0), isTrue);
    });

    test('canAfford positive amount returns false when balance is 0', () {
      expect(makeNotifier().canAfford(1), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // add
  // -------------------------------------------------------------------------

  group('CoinBalanceNotifier — add', () {
    test('adds coins to state', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.add(100);
      expect(notifier.state, 100);
    });

    test('accumulates across multiple add calls', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.add(50);
      await notifier.add(25);
      expect(notifier.state, 75);
    });

    test('adding zero has no effect', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.add(0);
      expect(notifier.state, 0);
    });

    test('adding large values', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.add(1000000);
      expect(notifier.state, 1000000);
    });
  });

  // -------------------------------------------------------------------------
  // deduct
  // -------------------------------------------------------------------------

  group('CoinBalanceNotifier — deduct', () {
    test('deducts when balance is sufficient', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.set(200);
      await notifier.deduct(50);
      expect(notifier.state, 150);
    });

    test('does not deduct when balance is insufficient', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.set(30);
      await notifier.deduct(100); // can't afford
      expect(notifier.state, 30);
    });

    test('exact deduction brings balance to zero', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.set(100);
      await notifier.deduct(100);
      expect(notifier.state, 0);
    });
  });

  // -------------------------------------------------------------------------
  // canAfford
  // -------------------------------------------------------------------------

  group('CoinBalanceNotifier — canAfford', () {
    test('returns true when balance >= amount', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.set(500);
      expect(notifier.canAfford(500), isTrue);
      expect(notifier.canAfford(499), isTrue);
    });

    test('returns false when balance < amount', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.set(99);
      expect(notifier.canAfford(100), isFalse);
    });

    test('returns false for any amount when balance is 0', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      expect(notifier.canAfford(1), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // set
  // -------------------------------------------------------------------------

  group('CoinBalanceNotifier — set', () {
    test('sets balance to exact value', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.set(750);
      expect(notifier.state, 750);
    });

    test('can set to 0 (reset)', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.add(500);
      await notifier.set(0);
      expect(notifier.state, 0);
    });

    test('can overwrite a previously set value', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.set(100);
      await notifier.set(999);
      expect(notifier.state, 999);
    });
  });

  // -------------------------------------------------------------------------
  // reset
  // -------------------------------------------------------------------------

  group('CoinBalanceNotifier — reset', () {
    test('resets balance to 0', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.add(300);
      await notifier.reset();
      expect(notifier.state, 0);
    });

    test('reset on already-zero notifier stays at 0', () async {
      final notifier = makeNotifier();
      await notifier.initialized;
      await notifier.reset();
      expect(notifier.state, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Persistence round-trip
  // -------------------------------------------------------------------------

  group('CoinBalanceNotifier — persistence', () {
    test('persisted value is loaded by a new notifier', () async {
      final n1 = makeNotifier();
      await n1.set(123);

      // Allow async _loadFromStorage in new notifier to complete
      final n2 = makeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(n2.state, 123);
    });

    test('reset clears persisted value', () async {
      final n1 = makeNotifier();
      await n1.set(500);
      await n1.reset();

      final n2 = makeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(n2.state, 0);
    });
  });
}
