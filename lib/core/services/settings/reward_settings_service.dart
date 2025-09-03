import 'package:hive/hive.dart';

/// RewardSettingsService manages store purchases, power-up inventory,
/// win streaks, jackpot times, and currency-related progress.
class RewardSettingsService {
  static const _settingsBox = 'settings';
  static const _purchasedItemsBox = 'purchased_items';
  static const _storeDataBox = 'store_data';

  Future<void> addPurchasedItem(String itemId) async {
    final box = await Hive.openBox(_purchasedItemsBox);
    await box.put(itemId, true);
  }

  Future<bool> hasItem(String itemId) async {
    final box = await Hive.openBox(_purchasedItemsBox);
    return box.get(itemId, defaultValue: false);
  }

  Future<List<String>> getAllPurchasedItems() async {
    final box = await Hive.openBox(_purchasedItemsBox);
    return box.keys.cast<String>().toList();
  }

  Future<void> addToInventory(String itemId) async {
    final box = await Hive.openBox<List<String>>(_storeDataBox);
    final List<String> current = box.get(_settingsBox, defaultValue: [])!;
    if (!current.contains(itemId)) {
      current.add(itemId);
      await box.put(_settingsBox, current);
    }
  }

  Future<List<String>> getInventory() async {
    final box = await Hive.openBox<List<String>>(_storeDataBox);
    return box.get(_settingsBox, defaultValue: [])!;
  }

  Future<bool> isInInventory(String id) async {
    final inventory = await getInventory();
    return inventory.contains(id);
  }

  Future<void> setWinStreak(int streak) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('winStreak', streak);
  }

  Future<int> getWinStreak() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('winStreak', defaultValue: 0);
  }

  Future<void> setJackpotTime(DateTime time) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('lastJackpotWin', time.toIso8601String());
  }

  Future<DateTime> getJackpotTime() async {
    final box = await Hive.openBox(_settingsBox);
    final raw = box.get('lastJackpotWin');
    return raw != null ? DateTime.parse(raw) : DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<int> getExclusiveCurrency() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('exclusiveCurrency', defaultValue: 0);
  }
}
