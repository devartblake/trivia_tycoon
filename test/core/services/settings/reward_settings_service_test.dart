import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/reward_settings_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reward_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  RewardSettingsService _make() => RewardSettingsService();

  // -------------------------------------------------------------------------
  // addPurchasedItem / hasItem / getAllPurchasedItems
  // -------------------------------------------------------------------------

  group('addPurchasedItem / hasItem / getAllPurchasedItems', () {
    test('hasItem false before adding', () async {
      final svc = _make();
      expect(await svc.hasItem('item_1'), isFalse);
    });

    test('hasItem true after adding', () async {
      final svc = _make();
      await svc.addPurchasedItem('item_1');
      expect(await svc.hasItem('item_1'), isTrue);
    });

    test('getAllPurchasedItems empty initially', () async {
      final svc = _make();
      expect(await svc.getAllPurchasedItems(), isEmpty);
    });

    test('getAllPurchasedItems returns all added items', () async {
      final svc = _make();
      await svc.addPurchasedItem('a');
      await svc.addPurchasedItem('b');
      final items = await svc.getAllPurchasedItems();
      expect(items, containsAll(['a', 'b']));
    });
  });

  // -------------------------------------------------------------------------
  // inventory: addToInventory / removeFromInventory / getInventory / isInInventory
  // -------------------------------------------------------------------------

  group('inventory', () {
    test('getInventory empty initially', () async {
      final svc = _make();
      expect(await svc.getInventory(), isEmpty);
    });

    test('addToInventory adds item', () async {
      final svc = _make();
      await svc.addToInventory('sword');
      expect(await svc.isInInventory('sword'), isTrue);
    });

    test('addToInventory no duplicates', () async {
      final svc = _make();
      await svc.addToInventory('sword');
      await svc.addToInventory('sword');
      final inv = await svc.getInventory();
      expect(inv.where((i) => i == 'sword').length, 1);
    });

    test('removeFromInventory removes item', () async {
      final svc = _make();
      await svc.addToInventory('shield');
      await svc.removeFromInventory('shield');
      expect(await svc.isInInventory('shield'), isFalse);
    });

    test('removeFromInventory no-op when not present', () async {
      final svc = _make();
      await svc.removeFromInventory('nonexistent');
      expect(await svc.getInventory(), isEmpty);
    });

    test('isInInventory false for absent item', () async {
      final svc = _make();
      expect(await svc.isInInventory('ghost'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // useItem / getItemCount
  // -------------------------------------------------------------------------

  group('useItem / getItemCount', () {
    test('getItemCount 0 when not in inventory', () async {
      final svc = _make();
      expect(await svc.getItemCount('potion'), 0);
    });

    test('getItemCount reflects added duplicates', () async {
      final svc = _make();
      final box = await Hive.openBox<List<String>>('store_data');
      await box.put('inventory', ['potion', 'potion', 'potion']);
      expect(await svc.getItemCount('potion'), 3);
    });

    test('useItem returns false when not enough', () async {
      final svc = _make();
      expect(await svc.useItem('potion', count: 2), isFalse);
    });

    test('useItem returns true and decrements when enough', () async {
      final svc = _make();
      final box = await Hive.openBox<List<String>>('store_data');
      await box.put('inventory', ['potion', 'potion', 'potion']);
      expect(await svc.useItem('potion', count: 2), isTrue);
      expect(await svc.getItemCount('potion'), 1);
    });

    test('useItem default count is 1', () async {
      final svc = _make();
      final box = await Hive.openBox<List<String>>('store_data');
      await box.put('inventory', ['gem']);
      expect(await svc.useItem('gem'), isTrue);
      expect(await svc.getItemCount('gem'), 0);
    });
  });

  // -------------------------------------------------------------------------
  // win streak
  // -------------------------------------------------------------------------

  group('winStreak', () {
    test('getWinStreak defaults to 0', () async {
      final svc = _make();
      expect(await svc.getWinStreak(), 0);
    });

    test('setWinStreak persists value', () async {
      final svc = _make();
      await svc.setWinStreak(7);
      expect(await svc.getWinStreak(), 7);
    });

    test('incrementWinStreak adds 1', () async {
      final svc = _make();
      await svc.setWinStreak(3);
      await svc.incrementWinStreak();
      expect(await svc.getWinStreak(), 4);
    });

    test('resetWinStreak sets to 0', () async {
      final svc = _make();
      await svc.setWinStreak(10);
      await svc.resetWinStreak();
      expect(await svc.getWinStreak(), 0);
    });
  });

  // -------------------------------------------------------------------------
  // jackpot time
  // -------------------------------------------------------------------------

  group('jackpotTime', () {
    test('getJackpotTime defaults to epoch when not set', () async {
      final svc = _make();
      final t = await svc.getJackpotTime();
      expect(t.millisecondsSinceEpoch, 0);
    });

    test('setJackpotTime persists', () async {
      final svc = _make();
      final now = DateTime(2025, 6, 1, 12);
      await svc.setJackpotTime(now);
      final t = await svc.getJackpotTime();
      expect(t.year, 2025);
      expect(t.month, 6);
    });

    test('isJackpotAvailable true when last win was > 24h ago', () async {
      final svc = _make();
      await svc
          .setJackpotTime(DateTime.now().subtract(const Duration(hours: 25)));
      expect(await svc.isJackpotAvailable(), isTrue);
    });

    test('isJackpotAvailable false when last win was < 24h ago', () async {
      final svc = _make();
      await svc
          .setJackpotTime(DateTime.now().subtract(const Duration(hours: 1)));
      expect(await svc.isJackpotAvailable(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // exclusive currency
  // -------------------------------------------------------------------------

  group('exclusiveCurrency', () {
    test('defaults to 0', () async {
      final svc = _make();
      expect(await svc.getExclusiveCurrency(), 0);
    });

    test('setExclusiveCurrency persists', () async {
      final svc = _make();
      await svc.setExclusiveCurrency(50);
      expect(await svc.getExclusiveCurrency(), 50);
    });

    test('addExclusiveCurrency accumulates', () async {
      final svc = _make();
      await svc.addExclusiveCurrency(30);
      await svc.addExclusiveCurrency(20);
      expect(await svc.getExclusiveCurrency(), 50);
    });

    test('spendExclusiveCurrency returns true when sufficient', () async {
      final svc = _make();
      await svc.setExclusiveCurrency(100);
      expect(await svc.spendExclusiveCurrency(40), isTrue);
      expect(await svc.getExclusiveCurrency(), 60);
    });

    test('spendExclusiveCurrency returns false when insufficient', () async {
      final svc = _make();
      await svc.setExclusiveCurrency(10);
      expect(await svc.spendExclusiveCurrency(20), isFalse);
      expect(await svc.getExclusiveCurrency(), 10);
    });

    test('spendExclusiveCurrency exact amount', () async {
      final svc = _make();
      await svc.setExclusiveCurrency(50);
      expect(await svc.spendExclusiveCurrency(50), isTrue);
      expect(await svc.getExclusiveCurrency(), 0);
    });
  });

  // -------------------------------------------------------------------------
  // regular currency
  // -------------------------------------------------------------------------

  group('regularCurrency', () {
    test('defaults to 0', () async {
      final svc = _make();
      expect(await svc.getRegularCurrency(), 0);
    });

    test('setRegularCurrency persists', () async {
      final svc = _make();
      await svc.setRegularCurrency(200);
      expect(await svc.getRegularCurrency(), 200);
    });

    test('addRegularCurrency accumulates', () async {
      final svc = _make();
      await svc.addRegularCurrency(100);
      await svc.addRegularCurrency(50);
      expect(await svc.getRegularCurrency(), 150);
    });

    test('spendRegularCurrency sufficient', () async {
      final svc = _make();
      await svc.setRegularCurrency(500);
      expect(await svc.spendRegularCurrency(200), isTrue);
      expect(await svc.getRegularCurrency(), 300);
    });

    test('spendRegularCurrency insufficient', () async {
      final svc = _make();
      await svc.setRegularCurrency(50);
      expect(await svc.spendRegularCurrency(100), isFalse);
      expect(await svc.getRegularCurrency(), 50);
    });
  });

  // -------------------------------------------------------------------------
  // total score
  // -------------------------------------------------------------------------

  group('totalScore', () {
    test('defaults to 0', () async {
      final svc = _make();
      expect(await svc.getTotalScore(), 0);
    });

    test('setTotalScore and getTotalScore', () async {
      final svc = _make();
      await svc.setTotalScore(999);
      expect(await svc.getTotalScore(), 999);
    });

    test('addScore accumulates', () async {
      final svc = _make();
      await svc.addScore(500);
      await svc.addScore(200);
      expect(await svc.getTotalScore(), 700);
    });
  });

  // -------------------------------------------------------------------------
  // daily reward
  // -------------------------------------------------------------------------

  group('daily reward', () {
    test('isDailyRewardAvailable true when never claimed', () async {
      final svc = _make();
      expect(await svc.isDailyRewardAvailable(), isTrue);
    });

    test('isDailyRewardAvailable false when claimed today', () async {
      final svc = _make();
      await svc.setLastDailyReward(DateTime.now());
      expect(await svc.isDailyRewardAvailable(), isFalse);
    });

    test('isDailyRewardAvailable true when claimed yesterday', () async {
      final svc = _make();
      await svc
          .setLastDailyReward(DateTime.now().subtract(const Duration(days: 1)));
      expect(await svc.isDailyRewardAvailable(), isTrue);
    });

    test('getLastDailyReward null when never claimed', () async {
      final svc = _make();
      expect(await svc.getLastDailyReward(), isNull);
    });

    test('getLastDailyReward returns saved date', () async {
      final svc = _make();
      final date = DateTime(2025, 3, 15);
      await svc.setLastDailyReward(date);
      final result = await svc.getLastDailyReward();
      expect(result!.year, 2025);
      expect(result.month, 3);
    });

    test('claimDailyReward returns zero when already claimed', () async {
      final svc = _make();
      await svc.setLastDailyReward(DateTime.now());
      final rewards = await svc.claimDailyReward();
      expect(rewards['regularCurrency'], 0);
      expect(rewards['exclusiveCurrency'], 0);
    });

    test('claimDailyReward awards base 100 coins with 0 streak', () async {
      final svc = _make();
      final rewards = await svc.claimDailyReward();
      expect(rewards['regularCurrency'], 100);
      expect(rewards['exclusiveCurrency'], 0);
    });

    test('claimDailyReward awards streak bonus', () async {
      final svc = _make();
      await svc.setWinStreak(3);
      final rewards = await svc.claimDailyReward();
      expect(rewards['regularCurrency'], 130);
    });

    test('claimDailyReward awards exclusive currency at streak >= 5', () async {
      final svc = _make();
      await svc.setWinStreak(5);
      final rewards = await svc.claimDailyReward();
      expect(rewards['exclusiveCurrency'], 10);
    });
  });

  // -------------------------------------------------------------------------
  // getLastRewardUpdate
  // -------------------------------------------------------------------------

  group('getLastRewardUpdate', () {
    test('null before any reward update', () async {
      final svc = _make();
      expect(await svc.getLastRewardUpdate(), isNull);
    });

    test('set after any write operation', () async {
      final svc = _make();
      final before = DateTime.now();
      await svc.setWinStreak(1);
      final ts = await svc.getLastRewardUpdate();
      expect(ts, isNotNull);
      expect(ts!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // getRewardStats
  // -------------------------------------------------------------------------

  group('getRewardStats', () {
    test('returns map with expected keys', () async {
      final svc = _make();
      final stats = await svc.getRewardStats();
      expect(stats.containsKey('winStreak'), isTrue);
      expect(stats.containsKey('exclusiveCurrency'), isTrue);
      expect(stats.containsKey('regularCurrency'), isTrue);
      expect(stats.containsKey('totalScore'), isTrue);
      expect(stats.containsKey('jackpotAvailable'), isTrue);
      expect(stats.containsKey('dailyRewardAvailable'), isTrue);
    });

    test('reflects set values', () async {
      final svc = _make();
      await svc.setWinStreak(7);
      await svc.setExclusiveCurrency(100);
      final stats = await svc.getRewardStats();
      expect(stats['winStreak'], 7);
      expect(stats['exclusiveCurrency'], 100);
    });
  });

  // -------------------------------------------------------------------------
  // clearAllRewardData
  // -------------------------------------------------------------------------

  group('clearAllRewardData', () {
    test('resets winStreak, currencies, score', () async {
      final svc = _make();
      await svc.setWinStreak(5);
      await svc.setExclusiveCurrency(200);
      await svc.setRegularCurrency(500);
      await svc.setTotalScore(1000);
      await svc.clearAllRewardData();
      expect(await svc.getWinStreak(), 0);
      expect(await svc.getExclusiveCurrency(), 0);
      expect(await svc.getRegularCurrency(), 0);
      expect(await svc.getTotalScore(), 0);
    });

    test('clears purchased items', () async {
      final svc = _make();
      await svc.addPurchasedItem('item_x');
      await svc.clearAllRewardData();
      expect(await svc.getAllPurchasedItems(), isEmpty);
    });

    test('clears inventory', () async {
      final svc = _make();
      await svc.addToInventory('sword');
      await svc.clearAllRewardData();
      expect(await svc.getInventory(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // validateRewardIntegrity
  // -------------------------------------------------------------------------

  group('validateRewardIntegrity', () {
    test('repairs negative win streak to 0', () async {
      final box = await Hive.openBox('settings');
      await box.put('winStreak', -5);
      final svc = _make();
      await svc.validateRewardIntegrity();
      expect(await svc.getWinStreak(), 0);
    });

    test('repairs negative exclusive currency to 0', () async {
      final box = await Hive.openBox('settings');
      await box.put('exclusiveCurrency', -10);
      final svc = _make();
      await svc.validateRewardIntegrity();
      expect(await svc.getExclusiveCurrency(), 0);
    });

    test('repairs negative regular currency to 0', () async {
      final box = await Hive.openBox('settings');
      await box.put('regularCurrency', -100);
      final svc = _make();
      await svc.validateRewardIntegrity();
      expect(await svc.getRegularCurrency(), 0);
    });

    test('no repair needed when data is valid', () async {
      final svc = _make();
      await svc.setWinStreak(3);
      await svc.setExclusiveCurrency(50);
      await svc.validateRewardIntegrity();
      expect(await svc.getWinStreak(), 3);
      expect(await svc.getExclusiveCurrency(), 50);
    });
  });
}
