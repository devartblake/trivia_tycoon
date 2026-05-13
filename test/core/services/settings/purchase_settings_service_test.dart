import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/purchase_settings_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('purchase_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  PurchaseSettingsService _make() => PurchaseSettingsService();

  // -------------------------------------------------------------------------
  // addPurchasedItem / hasItem / getAllPurchasedItems
  // -------------------------------------------------------------------------

  group('addPurchasedItem / hasItem / getAllPurchasedItems', () {
    test('hasItem false before adding', () async {
      final svc = _make();
      expect(await svc.hasItem('song_1'), isFalse);
    });

    test('hasItem true after adding', () async {
      final svc = _make();
      await svc.addPurchasedItem('song_1');
      expect(await svc.hasItem('song_1'), isTrue);
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

    test('idempotent: adding same item twice still shows once in purchased',
        () async {
      final svc = _make();
      await svc.addPurchasedItem('x');
      await svc.addPurchasedItem('x');
      final items = await svc.getAllPurchasedItems();
      expect(items.where((i) => i == 'x').length, 1);
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
      await svc.addToInventory('potion');
      expect(await svc.isInInventory('potion'), isTrue);
    });

    test('addToInventory no duplicates', () async {
      final svc = _make();
      await svc.addToInventory('potion');
      await svc.addToInventory('potion');
      final inv = await svc.getInventory();
      expect(inv.where((i) => i == 'potion').length, 1);
    });

    test('removeFromInventory removes item', () async {
      final svc = _make();
      await svc.addToInventory('shield');
      await svc.removeFromInventory('shield');
      expect(await svc.isInInventory('shield'), isFalse);
    });

    test('removeFromInventory no-op when not present', () async {
      final svc = _make();
      await svc.removeFromInventory('ghost');
      expect(await svc.getInventory(), isEmpty);
    });

    test('isInInventory false for absent item', () async {
      final svc = _make();
      expect(await svc.isInInventory('nope'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // getItemCount
  // -------------------------------------------------------------------------

  group('getItemCount', () {
    test('0 when not in inventory', () async {
      final svc = _make();
      expect(await svc.getItemCount('gem'), 0);
    });

    test('1 when one instance present', () async {
      final svc = _make();
      await svc.addToInventory('gem');
      expect(await svc.getItemCount('gem'), 1);
    });
  });

  // -------------------------------------------------------------------------
  // song-specific aliases
  // -------------------------------------------------------------------------

  group('purchaseSong / getPurchasedSongs / savePurchasedSongs', () {
    test('purchaseSong adds to purchased items', () async {
      final svc = _make();
      await svc.purchaseSong('track_01.mp3');
      expect(await svc.hasItem('track_01.mp3'), isTrue);
    });

    test('getPurchasedSongs returns all purchased items', () async {
      final svc = _make();
      await svc.purchaseSong('a.mp3');
      await svc.purchaseSong('b.mp3');
      final songs = await svc.getPurchasedSongs();
      expect(songs, containsAll(['a.mp3', 'b.mp3']));
    });

    test('savePurchasedSongs persists multiple songs', () async {
      final svc = _make();
      await svc.savePurchasedSongs(['x.mp3', 'y.mp3']);
      expect(await svc.hasItem('x.mp3'), isTrue);
      expect(await svc.hasItem('y.mp3'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // pending purchases
  // -------------------------------------------------------------------------

  group('addPendingPurchase / getPendingPurchases / clearPendingPurchases', () {
    test('empty list initially', () async {
      final svc = _make();
      expect(await svc.getPendingPurchases(), isEmpty);
    });

    test('addPendingPurchase stores entry', () async {
      final svc = _make();
      await svc.addPendingPurchase('item_x', {'price': 100});
      final pending = await svc.getPendingPurchases();
      expect(pending.length, 1);
      expect(pending.first['itemId'], 'item_x');
    });

    test('addPendingPurchase accumulates multiple entries', () async {
      final svc = _make();
      await svc.addPendingPurchase('a', {});
      await svc.addPendingPurchase('b', {});
      expect((await svc.getPendingPurchases()).length, 2);
    });

    test('clearPendingPurchases empties the list', () async {
      final svc = _make();
      await svc.addPendingPurchase('a', {});
      await svc.clearPendingPurchases();
      expect(await svc.getPendingPurchases(), isEmpty);
    });

    test('pending purchase includes timestamp', () async {
      final svc = _make();
      await svc.addPendingPurchase('item_z', {'qty': 1});
      final pending = await svc.getPendingPurchases();
      expect(pending.first['timestamp'], isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // setLastSyncTime / getLastSyncTime
  // -------------------------------------------------------------------------

  group('setLastSyncTime / getLastSyncTime', () {
    test('null before any sync', () async {
      final svc = _make();
      expect(await svc.getLastSyncTime(), isNull);
    });

    test('returns saved sync time', () async {
      final svc = _make();
      final now = DateTime(2025, 6, 15, 10, 30);
      await svc.setLastSyncTime(now);
      final result = await svc.getLastSyncTime();
      expect(result!.year, 2025);
      expect(result.month, 6);
      expect(result.hour, 10);
    });
  });

  // -------------------------------------------------------------------------
  // getPurchaseStats
  // -------------------------------------------------------------------------

  group('getPurchaseStats', () {
    test('totalPurchases 0 initially', () async {
      final svc = _make();
      final stats = await svc.getPurchaseStats();
      expect(stats['totalPurchases'], 0);
    });

    test('totalPurchases increments with purchases', () async {
      final svc = _make();
      await svc.addPurchasedItem('p1');
      await svc.addPurchasedItem('p2');
      final stats = await svc.getPurchaseStats();
      expect(stats['totalPurchases'], 2);
    });

    test('inventoryItems increments with inventory', () async {
      final svc = _make();
      await svc.addToInventory('sword');
      final stats = await svc.getPurchaseStats();
      expect(stats['inventoryItems'], 1);
    });

    test('contains cacheValid key', () async {
      final svc = _make();
      final stats = await svc.getPurchaseStats();
      expect(stats.containsKey('cacheValid'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // clearAllData
  // -------------------------------------------------------------------------

  group('clearAllData', () {
    test('clears purchased items', () async {
      final svc = _make();
      await svc.addPurchasedItem('item_a');
      await svc.clearAllData();
      expect(await svc.getAllPurchasedItems(), isEmpty);
    });

    test('clears inventory', () async {
      final svc = _make();
      await svc.addToInventory('armor');
      await svc.clearAllData();
      expect(await svc.getInventory(), isEmpty);
    });

    test('after clearAllData hasItem returns false', () async {
      final svc = _make();
      await svc.addPurchasedItem('gone');
      await svc.clearAllData();
      expect(await svc.hasItem('gone'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // validatePurchaseIntegrity
  // -------------------------------------------------------------------------

  group('validatePurchaseIntegrity', () {
    test('runs without error on empty state', () async {
      final svc = _make();
      await expectLater(svc.validatePurchaseIntegrity(), completes);
    });

    test('preserves valid items after validation', () async {
      final svc = _make();
      await svc.addPurchasedItem('valid_item');
      await svc.addToInventory('valid_inv');
      await svc.validatePurchaseIntegrity();
      expect(await svc.hasItem('valid_item'), isTrue);
      expect(await svc.isInInventory('valid_inv'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // saveState (lifecycle)
  // -------------------------------------------------------------------------

  group('saveState', () {
    test('completes without error', () async {
      final svc = _make();
      await expectLater(svc.saveState(), completes);
    });

    test('sets lastSyncTime after saveState', () async {
      final svc = _make();
      final before = DateTime.now();
      await svc.saveState();
      final syncTime = await svc.getLastSyncTime();
      expect(syncTime, isNotNull);
      expect(syncTime!.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
    });
  });
}
