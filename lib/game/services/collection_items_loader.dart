import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/collection_item.dart';

/// Service to load and manage collection items with their images
class CollectionItemsLoader {
  /// Directory where collection item images are stored
  Future<Directory> get _collectionImagesDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'collectionItems'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Load collection items from bundled JSON asset
  Future<List<CollectionItem>> loadFromAsset({
    String assetPath = 'assets/data/collection_items.json',
  }) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final itemsList = jsonData['items'] as List<dynamic>;

      return itemsList
          .map((item) => CollectionItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading collection items from asset: $e');
      return [];
    }
  }

  /// Load collection items from local file system
  Future<List<CollectionItem>> loadFromLocalFile({
    String fileName = 'collection_items.json',
  }) async {
    try {
      final dir = await _collectionImagesDir;
      final file = File(p.join(dir.path, fileName));

      if (!await file.exists()) {
        return [];
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final itemsList = jsonData['items'] as List<dynamic>;

      return itemsList
          .map((item) => CollectionItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading collection items from local file: $e');
      return [];
    }
  }

  /// Save collection items to local file
  Future<void> saveToLocalFile(
      List<CollectionItem> items, {
        String fileName = 'collection_items.json',
      }) async {
    try {
      final dir = await _collectionImagesDir;
      final file = File(p.join(dir.path, fileName));

      final jsonData = {
        'version': 1,
        'generatedAt': DateTime.now().toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
      );
    } catch (e) {
      print('Error saving collection items to local file: $e');
    }
  }

  /// Load all collection items (tries asset first, then local file)
  Future<List<CollectionItem>> loadAllItems() async {
    // Try loading from asset first
    var items = await loadFromAsset();

    // If asset loading fails or returns empty, try local file
    if (items.isEmpty) {
      items = await loadFromLocalFile();
    }

    // If still empty, generate default items
    if (items.isEmpty) {
      items = _generateDefaultItems();
      // Save default items for future use
      await saveToLocalFile(items);
    }

    return items;
  }

  /// Check if an image exists for a collection item
  Future<bool> hasImage(String itemId) async {
    final dir = await _collectionImagesDir;
    final imageExtensions = ['png', 'jpg', 'jpeg', 'webp'];

    for (final ext in imageExtensions) {
      final file = File(p.join(dir.path, '$itemId.$ext'));
      if (await file.exists()) {
        return true;
      }
    }

    return false;
  }

  /// Get image path for a collection item
  Future<String?> getImagePath(String itemId) async {
    final dir = await _collectionImagesDir;
    final imageExtensions = ['png', 'jpg', 'jpeg', 'webp'];

    for (final ext in imageExtensions) {
      final file = File(p.join(dir.path, '$itemId.$ext'));
      if (await file.exists()) {
        return file.path;
      }
    }

    return null;
  }

  /// Save an image for a collection item
  Future<void> saveImage(
      String itemId,
      List<int> imageBytes, {
        String extension = 'png',
      }) async {
    try {
      final dir = await _collectionImagesDir;
      final file = File(p.join(dir.path, '$itemId.$extension'));
      await file.writeAsBytes(imageBytes);
    } catch (e) {
      print('Error saving collection item image: $e');
    }
  }

  /// Download and save image from URL
  Future<bool> downloadAndSaveImage(
      String itemId,
      String imageUrl, {
        String extension = 'png',
      }) async {
    try {
      // Note: In a real app, you would use http package to download
      // This is a placeholder implementation
      print('Download image for $itemId from $imageUrl');
      return false;
    } catch (e) {
      print('Error downloading collection item image: $e');
      return false;
    }
  }

  /// Load collection items by category
  Future<List<CollectionItem>> loadByCategory(String category) async {
    final allItems = await loadAllItems();
    return allItems
        .where((item) => item.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Load collection items by rarity
  Future<List<CollectionItem>> loadByRarity(String rarity) async {
    final allItems = await loadAllItems();
    return allItems
        .where((item) => item.rarity.toLowerCase() == rarity.toLowerCase())
        .toList();
  }

  /// Load unlocked collection items
  Future<List<CollectionItem>> loadUnlocked() async {
    final allItems = await loadAllItems();
    return allItems.where((item) => item.isUnlocked).toList();
  }

  /// Load locked collection items
  Future<List<CollectionItem>> loadLocked() async {
    final allItems = await loadAllItems();
    return allItems.where((item) => !item.isUnlocked).toList();
  }

  /// Get total collection count
  Future<int> getTotalCount() async {
    final items = await loadAllItems();
    return items.length;
  }

  /// Get unlocked count
  Future<int> getUnlockedCount() async {
    final items = await loadUnlocked();
    return items.length;
  }

  /// Get completion percentage
  Future<double> getCompletionPercentage() async {
    final total = await getTotalCount();
    if (total == 0) return 0.0;

    final unlocked = await getUnlockedCount();
    return (unlocked / total) * 100;
  }

  /// Update collection item (unlock, change image path, etc.)
  Future<void> updateItem(CollectionItem updatedItem) async {
    final allItems = await loadAllItems();
    final index = allItems.indexWhere((item) => item.id == updatedItem.id);

    if (index != -1) {
      allItems[index] = updatedItem;
      await saveToLocalFile(allItems);
    }
  }

  /// Unlock a collection item
  Future<void> unlockItem(String itemId) async {
    final allItems = await loadAllItems();
    final index = allItems.indexWhere((item) => item.id == itemId);

    if (index != -1 && !allItems[index].isUnlocked) {
      allItems[index] = allItems[index].unlock();
      await saveToLocalFile(allItems);
    }
  }

  /// Generate default collection items (fallback)
  List<CollectionItem> _generateDefaultItems() {
    return [
      CollectionItem(
        id: 'renaissance_palette',
        name: 'Renaissance Palette',
        category: 'Arts & Culture',
        rarity: 'Epic',
        description: 'A painter\'s palette used during the Renaissance period',
        aiImagePrompt: 'Ornate wooden artist palette with vibrant oil paint colors',
        pointValue: 500,
      ),
      CollectionItem(
        id: 'ancient_scroll',
        name: 'Ancient Scroll',
        category: 'History & Literature',
        rarity: 'Legendary',
        description: 'A preserved scroll containing ancient wisdom',
        aiImagePrompt: 'Aged parchment scroll with golden seal and mysterious text',
        pointValue: 1000,
      ),
      CollectionItem(
        id: 'dna_crystal',
        name: 'DNA Double Helix Crystal',
        category: 'Science & Discovery',
        rarity: 'Epic',
        description: 'Crystallized representation of the building blocks of life',
        aiImagePrompt: 'Glowing crystal sculpture of DNA double helix structure',
        pointValue: 500,
      ),
      // Add more default items as needed
    ];
  }
}