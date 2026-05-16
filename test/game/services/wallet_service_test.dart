import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/game/services/wallet_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wallet_service_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  WalletService make() => WalletService();

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('WalletService — initial state', () {
    test('coins start at 0', () {
      expect(make().coins, 0);
    });

    test('gems start at 0', () {
      expect(make().gems, 0);
    });
  });

  // -------------------------------------------------------------------------
  // addCoins
  // -------------------------------------------------------------------------

  group('WalletService — addCoins', () {
    test('adds positive coin amount', () {
      final wallet = make();
      wallet.addCoins(100);
      expect(wallet.coins, 100);
    });

    test('accumulates across multiple calls', () {
      final wallet = make();
      wallet.addCoins(50);
      wallet.addCoins(75);
      expect(wallet.coins, 125);
    });

    test('zero or negative amount has no effect', () {
      final wallet = make();
      wallet.addCoins(0);
      wallet.addCoins(-10);
      expect(wallet.coins, 0);
    });
  });

  // -------------------------------------------------------------------------
  // addGems
  // -------------------------------------------------------------------------

  group('WalletService — addGems', () {
    test('adds positive gem amount', () {
      final wallet = make();
      wallet.addGems(25);
      expect(wallet.gems, 25);
    });

    test('accumulates across calls', () {
      final wallet = make();
      wallet.addGems(10);
      wallet.addGems(15);
      expect(wallet.gems, 25);
    });

    test('zero or negative amount has no effect', () {
      final wallet = make();
      wallet.addGems(0);
      wallet.addGems(-5);
      expect(wallet.gems, 0);
    });
  });

  // -------------------------------------------------------------------------
  // spendCoins
  // -------------------------------------------------------------------------

  group('WalletService — spendCoins', () {
    test('deducts coins and returns true when balance is sufficient', () {
      final wallet = make();
      wallet.addCoins(200);
      final result = wallet.spendCoins(50);
      expect(result, isTrue);
      expect(wallet.coins, 150);
    });

    test('returns false and does not deduct when balance is insufficient', () {
      final wallet = make();
      wallet.addCoins(30);
      final result = wallet.spendCoins(100);
      expect(result, isFalse);
      expect(wallet.coins, 30);
    });

    test('exact spend succeeds', () {
      final wallet = make();
      wallet.addCoins(100);
      final result = wallet.spendCoins(100);
      expect(result, isTrue);
      expect(wallet.coins, 0);
    });

    test('spending zero always returns true', () {
      final wallet = make();
      expect(wallet.spendCoins(0), isTrue);
      expect(wallet.coins, 0);
    });

    test('spending negative amount returns true without effect', () {
      final wallet = make();
      wallet.addCoins(50);
      expect(wallet.spendCoins(-10), isTrue);
      expect(wallet.coins, 50); // unchanged
    });
  });

  // -------------------------------------------------------------------------
  // spendGems
  // -------------------------------------------------------------------------

  group('WalletService — spendGems', () {
    test('deducts gems and returns true when balance is sufficient', () {
      final wallet = make();
      wallet.addGems(50);
      final result = wallet.spendGems(20);
      expect(result, isTrue);
      expect(wallet.gems, 30);
    });

    test('returns false when gems are insufficient', () {
      final wallet = make();
      wallet.addGems(5);
      final result = wallet.spendGems(10);
      expect(result, isFalse);
      expect(wallet.gems, 5);
    });

    test('spending zero gems returns true', () {
      expect(make().spendGems(0), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // setBalances
  // -------------------------------------------------------------------------

  group('WalletService — setBalances', () {
    test('sets both coins and gems', () async {
      final wallet = make();
      await wallet.setBalances(coins: 500, gems: 25);
      expect(wallet.coins, 500);
      expect(wallet.gems, 25);
    });

    test('clamps negative coins to 0', () async {
      final wallet = make();
      await wallet.setBalances(coins: -100, gems: 0);
      expect(wallet.coins, 0);
    });

    test('clamps negative gems to 0', () async {
      final wallet = make();
      await wallet.setBalances(coins: 0, gems: -50);
      expect(wallet.gems, 0);
    });

    test('overwrites previous balance', () async {
      final wallet = make();
      wallet.addCoins(999);
      await wallet.setBalances(coins: 100, gems: 5);
      expect(wallet.coins, 100);
      expect(wallet.gems, 5);
    });
  });

  // -------------------------------------------------------------------------
  // coins and gems are independent
  // -------------------------------------------------------------------------

  group('WalletService — coins/gems independence', () {
    test('adding coins does not affect gems', () {
      final wallet = make();
      wallet.addCoins(500);
      expect(wallet.gems, 0);
    });

    test('adding gems does not affect coins', () {
      final wallet = make();
      wallet.addGems(50);
      expect(wallet.coins, 0);
    });

    test('spending coins does not affect gems', () {
      final wallet = make();
      wallet.addCoins(200);
      wallet.addGems(30);
      wallet.spendCoins(100);
      expect(wallet.gems, 30);
    });
  });
}
