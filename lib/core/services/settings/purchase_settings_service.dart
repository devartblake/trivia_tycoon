import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Service to manage purchased items and inventory (e.g. store items, power-ups)
class PurchaseSettingsService {
  static const String _purchasedItemsBox = 'purchased_items';
  static const String _storeDataBox = 'store_data';
  static const String _inventoryKey = 'inventory';
  static const String _pendingPurchasesKey = 'pending_purchases';
  static const String _lastSyncKey = 'last_sync';

  // Cache for performance
  List<String>? _cachedPurchasedItems;
  List<String>? _cachedInventory;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Helper method to safely get the purchased items box
  Future<Box> _getPurchasedItemsBox() async {
    if (Hive.isBoxOpen(_purchasedItemsBox)) {
      return Hive.box(_purchasedItemsBox);
    } else {
      return await Hive.openBox(_purchasedItemsBox);
    }
  }

  /// Helper method to safely get the store data box
  /// Note: Using dynamic type to avoid type conflicts
  Future<Box> _getStoreDataBox() async {
    if (Hive.isBoxOpen(_storeDataBox)) {
      return Hive.box(_storeDataBox);
    } else {
      return await Hive.openBox(_storeDataBox);
    }
  }

  /// Adds an item ID to the list of purchased items
  Future<void> addPurchasedItem(String itemId) async {
    final box = await _getPurchasedItemsBox();
    await box.put(itemId, true);
    _invalidateCache();
  }

  /// Checks if an item has been purchased
  Future<bool> hasItem(String itemId) async {
    final box = await _getPurchasedItemsBox();
    return box.get(itemId, defaultValue: false);
  }

  /// Retrieves all purchased item IDs
  Future<List<String>> getAllPurchasedItems() async {
    if (_isCacheValid() && _cachedPurchasedItems != null) {
      return List<String>.from(_cachedPurchasedItems!);
    }

    final box = await _getPurchasedItemsBox();
    _cachedPurchasedItems = box.keys.cast<String>().toList();
    _lastCacheUpdate = DateTime.now();
    return List<String>.from(_cachedPurchasedItems!);
  }

  /// Adds an item ID to the player's inventory
  Future<void> addToInventory(String itemId) async {
    final box = await _getStoreDataBox();
    final dynamic rawCurrent = box.get(_inventoryKey, defaultValue: <String>[]);
    final List<String> current = List<String>.from(rawCurrent ?? <String>[]);

    if (!current.contains(itemId)) {
      current.add(itemId);
      await box.put(_inventoryKey, current);
      _invalidateCache();
    }
  }

  /// Removes an item from the player's inventory
  Future<void> removeFromInventory(String itemId) async {
    final box = await _getStoreDataBox();
    final dynamic rawCurrent = box.get(_inventoryKey, defaultValue: <String>[]);
    final List<String> current = List<String>.from(rawCurrent ?? <String>[]);

    if (current.contains(itemId)) {
      current.remove(itemId);
      await box.put(_inventoryKey, current);
      _invalidateCache();
    }
  }

  /// Retrieves all item IDs from the player's inventory
  Future<List<String>> getInventory() async {
    if (_isCacheValid() && _cachedInventory != null) {
      return List<String>.from(_cachedInventory!);
    }

    final box = await _getStoreDataBox();
    final dynamic rawInventory = box.get(_inventoryKey, defaultValue: <String>[]);
    _cachedInventory = List<String>.from(rawInventory ?? <String>[]);
    _lastCacheUpdate = DateTime.now();
    return List<String>.from(_cachedInventory!);
  }

  /// Checks if a specific item ID is in the inventory
  Future<bool> isInInventory(String id) async {
    final items = await getInventory();
    return items.contains(id);
  }

  /// Gets the count of a specific item in inventory
  Future<int> getItemCount(String itemId) async {
    final items = await getInventory();
    return items.where((item) => item == itemId).length;
  }

  Future<List<String>> getPurchasedSongs() async {
    return await getAllPurchasedItems();
  }

  Future<void> savePurchasedSongs(List<String> songs) async {
    final box = await _getPurchasedItemsBox();
    for (final song in songs) {
      await box.put(song, true);
    }
    _invalidateCache();
  }

  /// Song-specific alias for addPurchasedItem
  Future<void> purchaseSong(String filename) async {
    await addPurchasedItem(filename);
  }

  /// Adds a pending purchase for later processing
  Future<void> addPendingPurchase(String itemId, Map<String, dynamic> purchaseData) async {
    final box = await _getStoreDataBox();
    final dynamic rawPending = box.get(_pendingPurchasesKey, defaultValue: <dynamic>[]);
    final List<dynamic> pending = List<dynamic>.from(rawPending ?? <dynamic>[]);

    pending.add({
      'itemId': itemId,
      'timestamp': DateTime.now().toIso8601String(),
      'data': purchaseData,
    });
    await box.put(_pendingPurchasesKey, pending);
  }

  /// Gets all pending purchases
  Future<List<Map<String, dynamic>>> getPendingPurchases() async {
    final box = await _getStoreDataBox();
    final dynamic rawPending = box.get(_pendingPurchasesKey, defaultValue: <dynamic>[]);
    final List<dynamic> pending = List<dynamic>.from(rawPending ?? <dynamic>[]);
    return pending.cast<Map<String, dynamic>>();
  }

  /// Clears pending purchases after successful processing
  Future<void> clearPendingPurchases() async {
    final box = await _getStoreDataBox();
    await box.delete(_pendingPurchasesKey);
  }

  /// Sets the last sync timestamp
  Future<void> setLastSyncTime(DateTime timestamp) async {
    final box = await _getStoreDataBox();
    await box.put(_lastSyncKey, timestamp.toIso8601String());
  }

  /// Gets the last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final box = await _getStoreDataBox();
    final raw = box.get(_lastSyncKey);
    return raw != null ? DateTime.parse(raw) : null;
  }

  /// LIFECYCLE METHOD: Saves current purchase state
  /// Called when app goes to background or is about to be terminated
  Future<void> saveState() async {
    try {
      // Ensure all cached data is persisted
      final purchasedBox = await _getPurchasedItemsBox();
      final storeBox = await _getStoreDataBox();

      // Force flush any pending writes
      await purchasedBox.flush();
      await storeBox.flush();

      // Update last save timestamp
      await setLastSyncTime(DateTime.now());

      debugPrint('✅ Purchase state saved successfully');
    } catch (e) {
      debugPrint('❌ Failed to save purchase state: $e');
      rethrow;
    }
  }

  /// LIFECYCLE METHOD: Validates and recovers purchase data integrity
  /// Called when app resumes or starts
  Future<void> validatePurchaseIntegrity() async {
    try {
      // Check for corrupted data
      final purchasedItems = await getAllPurchasedItems();
      final inventory = await getInventory();

      // Remove any invalid entries
      final validPurchases = purchasedItems.where((item) => item.isNotEmpty).toList();
      final validInventory = inventory.where((item) => item.isNotEmpty).toList();

      // Update if changes were made
      if (validPurchases.length != purchasedItems.length ||
          validInventory.length != inventory.length) {
        await _saveCorrectedData(validPurchases, validInventory);
        debugPrint('🔧 Purchase data integrity restored');
      }

      debugPrint('✅ Purchase integrity validation completed');
    } catch (e) {
      debugPrint('❌ Purchase integrity validation failed: $e');
    }
  }

  /// Helper method to save corrected data
  Future<void> _saveCorrectedData(List<String> purchases, List<String> inventory) async {
    // Clear and rebuild purchased items
    final purchasedBox = await _getPurchasedItemsBox();
    await purchasedBox.clear();
    for (final item in purchases) {
      await purchasedBox.put(item, true);
    }

    // Update inventory
    final storeBox = await _getStoreDataBox();
    await storeBox.put(_inventoryKey, inventory);

    _invalidateCache();
  }

  /// Cache management helpers
  bool _isCacheValid() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }

  void _invalidateCache() {
    _cachedPurchasedItems = null;
    _cachedInventory = null;
    _lastCacheUpdate = null;
  }

  /// Clear all purchase data (for testing or reset functionality)
  Future<void> clearAllData() async {
    final purchasedBox = await _getPurchasedItemsBox();
    final storeBox = await _getStoreDataBox();

    await purchasedBox.clear();
    await storeBox.clear();
    _invalidateCache();
  }

  /// Get purchase statistics
  Future<Map<String, dynamic>> getPurchaseStats() async {
    final purchases = await getAllPurchasedItems();
    final inventory = await getInventory();
    final lastSync = await getLastSyncTime();

    return {
      'totalPurchases': purchases.length,
      'inventoryItems': inventory.length,
      'lastSync': lastSync?.toIso8601String(),
      'cacheValid': _isCacheValid(),
    };
  }

  /// Optional: Method to properly close boxes when the service is disposed
  /// Call this when your app is shutting down or the service is no longer needed
  Future<void> dispose() async {
    try {
      if (Hive.isBoxOpen(_purchasedItemsBox)) {
        await Hive.box(_purchasedItemsBox).close();
      }
      if (Hive.isBoxOpen(_storeDataBox)) {
        await Hive.box(_storeDataBox).close();
      }
      _invalidateCache();
      debugPrint('✅ Purchase service disposed successfully');
    } catch (e) {
      debugPrint('❌ Error disposing purchase service: $e');
    }
  }
}
