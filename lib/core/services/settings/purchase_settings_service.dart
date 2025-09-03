import 'package:hive/hive.dart';

/// Service to manage purchased items and inventory (e.g. store items, power-ups)
class PurchaseSettingsService {
  static const String _purchasedItemsBox = 'purchased_items';
  static const String _storeDataBox = 'store_data';
  static const String _inventoryKey = 'inventory';

  /// Adds an item ID to the list of purchased items
  Future<void> addPurchasedItem(String itemId) async {
    final box = await Hive.openBox(_purchasedItemsBox);
    await box.put(itemId, true);
  }

  /// Checks if an item has been purchased
  Future<bool> hasItem(String itemId) async {
    final box = await Hive.openBox(_purchasedItemsBox);
    return box.get(itemId, defaultValue: false);
  }

  /// Retrieves all purchased item IDs
  Future<List<String>> getAllPurchasedItems() async {
    final box = await Hive.openBox(_purchasedItemsBox);
    return box.keys.cast<String>().toList();
  }

  /// Adds an item ID to the player's inventory
  Future<void> addToInventory(String itemId) async {
    final box = await Hive.openBox<List<String>>(_storeDataBox);
    final List<String> current = box.get(_inventoryKey, defaultValue: [])!;
    if (!current.contains(itemId)) {
      current.add(itemId);
      await box.put(_inventoryKey, current);
    }
  }

  /// Retrieves all item IDs from the player's inventory
  Future<List<String>> getInventory() async {
    final box = await Hive.openBox<List<String>>(_storeDataBox);
    return box.get(_inventoryKey, defaultValue: [])!;
  }

  /// Checks if a specific item ID is in the inventory
  Future<bool> isInInventory(String id) async {
    final items = await getInventory();
    return items.contains(id);
  }

  Future<List<String>> getPurchasedSongs() async {
    return await getAllPurchasedItems();
  }

  Future<void> savePurchasedSongs(List<String> songs) async {
    final box = await Hive.openBox(_purchasedItemsBox);
    for (final song in songs) {
      await box.put(song, true);
    }
  }

  /// Song-specific alias for addPurchasedItem
  Future<void> purchaseSong(String filename) async {
    await addPurchasedItem(filename);
  }
}
