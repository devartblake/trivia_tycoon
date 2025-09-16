import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// RewardSettingsService manages store purchases, power-up inventory,
/// win streaks, jackpot times, and currency-related progress.
class RewardSettingsService {
  static const _settingsBox = 'settings';
  static const _purchasedItemsBox = 'purchased_items';
  static const _storeDataBox = 'store_data';
  static const _inventoryKey = 'inventory';
  static const _rewardStateKey = 'reward_state_snapshot';
  static const _lastRewardUpdateKey = 'last_reward_update';

  // Cache for performance
  int? _cachedWinStreak;
  int? _cachedExclusiveCurrency;
  DateTime? _cachedJackpotTime;
  List<String>? _cachedInventory;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 3);

  Future<void> addPurchasedItem(String itemId) async {
    final box = await Hive.openBox(_purchasedItemsBox);
    await box.put(itemId, true);
    await _updateLastRewardUpdate();
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
    final List<String> current = box.get(_inventoryKey, defaultValue: [])!;
    if (!current.contains(itemId)) {
      current.add(itemId);
      await box.put(_inventoryKey, current);
      _invalidateCache();
      await _updateLastRewardUpdate();
    }
  }

  /// Removes an item from inventory (for consumable items)
  Future<void> removeFromInventory(String itemId) async {
    final box = await Hive.openBox<List<String>>(_storeDataBox);
    final List<String> current = box.get(_inventoryKey, defaultValue: [])!;
    if (current.contains(itemId)) {
      current.remove(itemId);
      await box.put(_inventoryKey, current);
      _invalidateCache();
      await _updateLastRewardUpdate();
    }
  }

  /// Uses/consumes multiple instances of an item
  Future<bool> useItem(String itemId, {int count = 1}) async {
    final box = await Hive.openBox<List<String>>(_storeDataBox);
    final List<String> current = box.get(_inventoryKey, defaultValue: [])!;

    final availableCount = current.where((item) => item == itemId).length;
    if (availableCount < count) {
      return false; // Not enough items
    }

    // Remove the specified count
    for (int i = 0; i < count; i++) {
      current.remove(itemId);
    }

    await box.put(_inventoryKey, current);
    _invalidateCache();
    await _updateLastRewardUpdate();
    return true;
  }

  Future<List<String>> getInventory() async {
    if (_isCacheValid() && _cachedInventory != null) {
      return List<String>.from(_cachedInventory!);
    }

    final box = await Hive.openBox<List<String>>(_storeDataBox);
    _cachedInventory = box.get(_inventoryKey, defaultValue: [])!;
    _lastCacheUpdate = DateTime.now();
    return List<String>.from(_cachedInventory!);
  }

  Future<bool> isInInventory(String id) async {
    final inventory = await getInventory();
    return inventory.contains(id);
  }

  /// Gets the count of a specific item in inventory
  Future<int> getItemCount(String itemId) async {
    final inventory = await getInventory();
    return inventory.where((item) => item == itemId).length;
  }

  Future<void> setWinStreak(int streak) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('winStreak', streak);
    _cachedWinStreak = streak;
    await _updateLastRewardUpdate();
  }

  Future<int> getWinStreak() async {
    if (_isCacheValid() && _cachedWinStreak != null) {
      return _cachedWinStreak!;
    }

    final box = await Hive.openBox(_settingsBox);
    _cachedWinStreak = box.get('winStreak', defaultValue: 0);
    _lastCacheUpdate = DateTime.now();
    return _cachedWinStreak!;
  }

  /// Increments win streak by 1
  Future<void> incrementWinStreak() async {
    final current = await getWinStreak();
    await setWinStreak(current + 1);
  }

  /// Resets win streak to 0
  Future<void> resetWinStreak() async {
    await setWinStreak(0);
  }

  Future<void> setJackpotTime(DateTime time) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('lastJackpotWin', time.toIso8601String());
    _cachedJackpotTime = time;
    await _updateLastRewardUpdate();
  }

  Future<DateTime> getJackpotTime() async {
    if (_isCacheValid() && _cachedJackpotTime != null) {
      return _cachedJackpotTime!;
    }

    final box = await Hive.openBox(_settingsBox);
    final raw = box.get('lastJackpotWin');
    _cachedJackpotTime = raw != null ? DateTime.parse(raw) : DateTime.fromMillisecondsSinceEpoch(0);
    _lastCacheUpdate = DateTime.now();
    return _cachedJackpotTime!;
  }

  /// Checks if jackpot is available (24 hours since last win)
  Future<bool> isJackpotAvailable() async {
    final lastWin = await getJackpotTime();
    final now = DateTime.now();
    return now.difference(lastWin).inHours >= 24;
  }

  /// Sets exclusive currency amount
  Future<void> setExclusiveCurrency(int amount) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('exclusiveCurrency', amount);
    _cachedExclusiveCurrency = amount;
    await _updateLastRewardUpdate();
  }

  Future<int> getExclusiveCurrency() async {
    if (_isCacheValid() && _cachedExclusiveCurrency != null) {
      return _cachedExclusiveCurrency!;
    }

    final box = await Hive.openBox(_settingsBox);
    _cachedExclusiveCurrency = box.get('exclusiveCurrency', defaultValue: 0);
    _lastCacheUpdate = DateTime.now();
    return _cachedExclusiveCurrency!;
  }

  /// Adds to exclusive currency
  Future<void> addExclusiveCurrency(int amount) async {
    final current = await getExclusiveCurrency();
    await setExclusiveCurrency(current + amount);
  }

  /// Spends exclusive currency if available
  Future<bool> spendExclusiveCurrency(int amount) async {
    final current = await getExclusiveCurrency();
    if (current >= amount) {
      await setExclusiveCurrency(current - amount);
      return true;
    }
    return false;
  }

  /// Sets regular currency amount
  Future<void> setRegularCurrency(int amount) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('regularCurrency', amount);
    await _updateLastRewardUpdate();
  }

  /// Gets regular currency amount
  Future<int> getRegularCurrency() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('regularCurrency', defaultValue: 0);
  }

  /// Adds to regular currency
  Future<void> addRegularCurrency(int amount) async {
    final current = await getRegularCurrency();
    await setRegularCurrency(current + amount);
  }

  /// Spends regular currency if available
  Future<bool> spendRegularCurrency(int amount) async {
    final current = await getRegularCurrency();
    if (current >= amount) {
      await setRegularCurrency(current - amount);
      return true;
    }
    return false;
  }

  /// Sets total score
  Future<void> setTotalScore(int score) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('totalScore', score);
    await _updateLastRewardUpdate();
  }

  /// Gets total score
  Future<int> getTotalScore() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('totalScore', defaultValue: 0);
  }

  /// Adds to total score
  Future<void> addScore(int points) async {
    final current = await getTotalScore();
    await setTotalScore(current + points);
  }

  /// Daily reward tracking
  Future<void> setLastDailyReward(DateTime date) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('lastDailyReward', date.toIso8601String());
    await _updateLastRewardUpdate();
  }

  Future<DateTime?> getLastDailyReward() async {
    final box = await Hive.openBox(_settingsBox);
    final raw = box.get('lastDailyReward');
    return raw != null ? DateTime.parse(raw) : null;
  }

  /// Checks if daily reward is available
  Future<bool> isDailyRewardAvailable() async {
    final lastReward = await getLastDailyReward();
    if (lastReward == null) return true;

    final now = DateTime.now();
    final lastRewardDate = DateTime(lastReward.year, lastReward.month, lastReward.day);
    final currentDate = DateTime(now.year, now.month, now.day);

    return currentDate.isAfter(lastRewardDate);
  }

  /// Claims daily reward
  Future<Map<String, int>> claimDailyReward() async {
    if (!await isDailyRewardAvailable()) {
      return {'regularCurrency': 0, 'exclusiveCurrency': 0};
    }

    final winStreak = await getWinStreak();
    final baseReward = 100;
    final streakBonus = winStreak * 10;
    final regularReward = baseReward + streakBonus;
    final exclusiveReward = winStreak >= 5 ? 10 : 0;

    await addRegularCurrency(regularReward);
    if (exclusiveReward > 0) {
      await addExclusiveCurrency(exclusiveReward);
    }

    await setLastDailyReward(DateTime.now());

    return {
      'regularCurrency': regularReward,
      'exclusiveCurrency': exclusiveReward,
    };
  }

  /// LIFECYCLE METHOD: Saves current reward state
  /// Called when app goes to background or is about to be terminated
  Future<void> saveRewardState() async {
    try {
      final box = await Hive.openBox(_settingsBox);

      // Create a comprehensive snapshot of reward state
      final rewardState = {
        'winStreak': await getWinStreak(),
        'exclusiveCurrency': await getExclusiveCurrency(),
        'regularCurrency': await getRegularCurrency(),
        'totalScore': await getTotalScore(),
        'lastJackpotWin': (await getJackpotTime()).toIso8601String(),
        'lastDailyReward': (await getLastDailyReward())?.toIso8601String(),
        'inventory': await getInventory(),
        'purchasedItems': await getAllPurchasedItems(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await box.put(_rewardStateKey, rewardState);

      // Ensure all boxes are flushed
      await box.flush();
      final purchasedBox = await Hive.openBox(_purchasedItemsBox);
      await purchasedBox.flush();
      final storeBox = await Hive.openBox<List<String>>(_storeDataBox);
      await storeBox.flush();

      if (kDebugMode) {
        print('✅ Reward state saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save reward state: $e');
      }
      rethrow;
    }
  }

  /// LIFECYCLE METHOD: Validates and recovers reward data integrity
  /// Called when app resumes or starts
  Future<void> validateRewardIntegrity() async {
    try {
      final box = await Hive.openBox(_settingsBox);
      bool needsRepair = false;

      // Validate win streak
      final winStreak = box.get('winStreak');
      if (winStreak == null || winStreak is! int || winStreak < 0) {
        await box.put('winStreak', 0);
        _cachedWinStreak = 0;
        needsRepair = true;
      }

      // Validate exclusive currency
      final exclusiveCurrency = box.get('exclusiveCurrency');
      if (exclusiveCurrency == null || exclusiveCurrency is! int || exclusiveCurrency < 0) {
        await box.put('exclusiveCurrency', 0);
        _cachedExclusiveCurrency = 0;
        needsRepair = true;
      }

      // Validate regular currency
      final regularCurrency = box.get('regularCurrency');
      if (regularCurrency == null || regularCurrency is! int || regularCurrency < 0) {
        await box.put('regularCurrency', 0);
        needsRepair = true;
      }

      // Validate total score
      final totalScore = box.get('totalScore');
      if (totalScore == null || totalScore is! int || totalScore < 0) {
        await box.put('totalScore', 0);
        needsRepair = true;
      }

      // Validate jackpot time
      final jackpotTime = box.get('lastJackpotWin');
      if (jackpotTime != null && jackpotTime is String) {
        try {
          DateTime.parse(jackpotTime);
        } catch (e) {
          await box.put('lastJackpotWin', DateTime.fromMillisecondsSinceEpoch(0).toIso8601String());
          _cachedJackpotTime = DateTime.fromMillisecondsSinceEpoch(0);
          needsRepair = true;
        }
      }

      // Validate daily reward time
      final dailyReward = box.get('lastDailyReward');
      if (dailyReward != null && dailyReward is String) {
        try {
          DateTime.parse(dailyReward);
        } catch (e) {
          await box.delete('lastDailyReward');
          needsRepair = true;
        }
      }

      // Validate inventory
      await _validateInventoryIntegrity();

      if (needsRepair) {
        await _updateLastRewardUpdate();
        if (kDebugMode) {
          print('🔧 Reward data integrity restored');
        }
      }

      _lastCacheUpdate = DateTime.now();
      if (kDebugMode) {
        print('✅ Reward integrity validation completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Reward integrity validation failed: $e');
      }
      await _resetRewardData();
    }
  }

  /// Validates inventory data integrity
  Future<void> _validateInventoryIntegrity() async {
    try {
      final box = await Hive.openBox<List<String>>(_storeDataBox);
      final inventory = box.get(_inventoryKey, defaultValue: [])!;

      // Remove any null or invalid entries
      final validInventory = inventory.where((item) => item.isNotEmpty).toList();

      if (validInventory.length != inventory.length) {
        await box.put(_inventoryKey, validInventory);
        _cachedInventory = validInventory;
        print('🔧 Inventory integrity restored');
      }

      // Validate purchased items
      final purchasedBox = await Hive.openBox(_purchasedItemsBox);
      final keys = purchasedBox.keys.toList();

      for (final key in keys) {
        if (key == null || key is! String || key.isEmpty) {
          await purchasedBox.delete(key);
          if (kDebugMode) {
            print('🔧 Invalid purchased item removed: $key');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Inventory validation failed: $e');
      }
    }
  }

  /// Resets reward data to defaults
  Future<void> _resetRewardData() async {
    try {
      final box = await Hive.openBox(_settingsBox);
      await box.put('winStreak', 0);
      await box.put('exclusiveCurrency', 0);
      await box.put('regularCurrency', 0);
      await box.put('totalScore', 0);
      await box.put('lastJackpotWin', DateTime.fromMillisecondsSinceEpoch(0).toIso8601String());
      await box.delete('lastDailyReward');

      _cachedWinStreak = 0;
      _cachedExclusiveCurrency = 0;
      _cachedJackpotTime = DateTime.fromMillisecondsSinceEpoch(0);

      await _updateLastRewardUpdate();
      print('🔄 Reward data reset to defaults');
    } catch (e) {
      print('❌ Failed to reset reward data: $e');
    }
  }

  /// Updates the last reward update timestamp
  Future<void> _updateLastRewardUpdate() async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(_lastRewardUpdateKey, DateTime.now().toIso8601String());
  }

  /// Gets the last reward update timestamp
  Future<DateTime?> getLastRewardUpdate() async {
    final box = await Hive.openBox(_settingsBox);
    final raw = box.get(_lastRewardUpdateKey);
    return raw != null ? DateTime.parse(raw) : null;
  }

  /// Cache management helpers
  bool _isCacheValid() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }

  void _invalidateCache() {
    _cachedWinStreak = null;
    _cachedExclusiveCurrency = null;
    _cachedJackpotTime = null;
    _cachedInventory = null;
    _lastCacheUpdate = null;
  }

  /// Gets comprehensive reward statistics
  Future<Map<String, dynamic>> getRewardStats() async {
    final lastUpdate = await getLastRewardUpdate();

    return {
      'winStreak': await getWinStreak(),
      'exclusiveCurrency': await getExclusiveCurrency(),
      'regularCurrency': await getRegularCurrency(),
      'totalScore': await getTotalScore(),
      'inventoryItems': (await getInventory()).length,
      'purchasedItems': (await getAllPurchasedItems()).length,
      'jackpotAvailable': await isJackpotAvailable(),
      'dailyRewardAvailable': await isDailyRewardAvailable(),
      'lastUpdate': lastUpdate?.toIso8601String(),
      'cacheValid': _isCacheValid(),
    };
  }

  /// Clear all reward data (for testing or reset)
  Future<void> clearAllRewardData() async {
    final settingsBox = await Hive.openBox(_settingsBox);
    final purchasedBox = await Hive.openBox(_purchasedItemsBox);
    final storeBox = await Hive.openBox<List<String>>(_storeDataBox);

    // Clear reward-related keys from settings
    final rewardKeys = ['winStreak', 'exclusiveCurrency', 'regularCurrency', 'totalScore',
      'lastJackpotWin', 'lastDailyReward', _rewardStateKey, _lastRewardUpdateKey];

    for (final key in rewardKeys) {
      await settingsBox.delete(key);
    }

    await purchasedBox.clear();
    await storeBox.clear();

    _invalidateCache();
    print('🗑️ All reward data cleared');
  }
}
