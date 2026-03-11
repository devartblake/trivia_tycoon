import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/collection_items_loader.dart';
import '../models/collection_item.dart';

/// Service provider for collection items loader
final collectionItemsLoaderProvider = Provider<CollectionItemsLoader>((ref) {
  return CollectionItemsLoader();
});

/// Provider for all collection items
final allCollectionItemsProvider = FutureProvider<List<CollectionItem>>((ref) async {
  final loader = ref.read(collectionItemsLoaderProvider);
  return loader.loadAllItems();
});

/// Provider for unlocked collection items
final unlockedCollectionItemsProvider = FutureProvider<List<CollectionItem>>((ref) async {
  final loader = ref.read(collectionItemsLoaderProvider);
  return loader.loadUnlocked();
});

/// Provider for locked collection items
final lockedCollectionItemsProvider = FutureProvider<List<CollectionItem>>((ref) async {
  final loader = ref.read(collectionItemsLoaderProvider);
  return loader.loadLocked();
});

/// Provider for collection items by category
final collectionItemsByCategoryProvider =
FutureProvider.family<List<CollectionItem>, String>((ref, category) async {
  final loader = ref.read(collectionItemsLoaderProvider);
  return loader.loadByCategory(category);
});

/// Provider for collection items by rarity
final collectionItemsByRarityProvider =
FutureProvider.family<List<CollectionItem>, String>((ref, rarity) async {
  final loader = ref.read(collectionItemsLoaderProvider);
  return loader.loadByRarity(rarity);
});

/// Provider for total collection count
final totalCollectionCountProvider = FutureProvider<int>((ref) async {
  final loader = ref.read(collectionItemsLoaderProvider);
  return loader.getTotalCount();
});

/// Provider for unlocked count
final unlockedCollectionCountProvider = FutureProvider<int>((ref) async {
  final loader = ref.read(collectionItemsLoaderProvider);
  return loader.getUnlockedCount();
});

/// Provider for completion percentage
final collectionCompletionProvider = FutureProvider<double>((ref) async {
  final loader = ref.read(collectionItemsLoaderProvider);
  return loader.getCompletionPercentage();
});

/// Provider for checking if an item has an image
final itemHasImageProvider =
FutureProvider.family<bool, String>((ref, itemId) async {
  final loader = ref.read(collectionItemsLoaderProvider);
  return loader.hasImage(itemId);
});

/// Provider for getting an item's image path
final itemImagePathProvider =
FutureProvider.family<String?, String>((ref, itemId) async {
  final loader = ref.read(collectionItemsLoaderProvider);
  return loader.getImagePath(itemId);
});

/// State notifier for managing collection item unlock actions
class CollectionItemsNotifier extends StateNotifier<AsyncValue<List<CollectionItem>>> {
  CollectionItemsNotifier(this._loader) : super(const AsyncValue.loading()) {
    _loadItems();
  }

  final CollectionItemsLoader _loader;

  Future<void> _loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _loader.loadAllItems();
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Unlock a collection item
  Future<void> unlockItem(String itemId) async {
    await _loader.unlockItem(itemId);
    await _loadItems(); // Reload items after unlock
  }

  /// Update a collection item
  Future<void> updateItem(CollectionItem item) async {
    await _loader.updateItem(item);
    await _loadItems(); // Reload items after update
  }

  /// Refresh collection items
  Future<void> refresh() async {
    await _loadItems();
  }
}

/// StateNotifier provider for collection items with actions
final collectionItemsNotifierProvider =
StateNotifierProvider<CollectionItemsNotifier, AsyncValue<List<CollectionItem>>>((ref) {
  final loader = ref.read(collectionItemsLoaderProvider);
  return CollectionItemsNotifier(loader);
});