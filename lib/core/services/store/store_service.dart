import 'package:hive/hive.dart';
import '../../../game/services/store_data_service.dart';
import '../../../game/models/store_item_model.dart';
import '../api_service.dart';

class StoreService {
  final ApiService apiService;

  // Enhanced caching and storage
  static const _storeBoxName = 'store_cache';
  static const _lastRefreshKey = 'last_store_refresh';
  static const _cacheTimestampKey = 'cache_timestamp';

  // Cache for performance
  List<StoreItemModel>? _cachedItems;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 30);
  static const Duration _refreshInterval = Duration(hours: 2);

  StoreService._(this.apiService);

  static Future<StoreService> initialize(ApiService apiService) async {
    try {
      // Initialize enhanced storage for caching
      await Hive.openBox(_storeBoxName);

      // Load store items, categories, avatars, etc. here
      final service = StoreService._(apiService);

      print('StoreService initialized successfully');
      return service;
    } catch (e) {
      print('Failed to initialize StoreService: $e');
      rethrow;
    }
  }

  /// Load all store items with enhanced caching
  Future<List<StoreItemModel>> getAllItems() async {
    // Return cached items if valid
    if (_isCacheValid() && _cachedItems != null) {
      return List<StoreItemModel>.from(_cachedItems!);
    }

    try {
      // Load from StoreDataService (your original method)
      final items = await StoreDataService.loadStoreItems();

      // Update cache
      _cachedItems = items;
      _lastCacheUpdate = DateTime.now();

      // Cache to persistent storage
      await _cacheItemsToStorage(items);

      return items;
    } catch (e) {
      print('Failed to load store items: $e');

      // Try to load from persistent cache as fallback
      final cachedItems = await _loadItemsFromStorage();
      if (cachedItems.isNotEmpty) {
        _cachedItems = cachedItems;
        return cachedItems;
      }

      return [];
    }
  }

  /// Filter for featured items
  Future<List<StoreItemModel>> getFeaturedItems() async {
    final items = await getAllItems(); // Use enhanced getAllItems
    return items.where((item) => item.isFeatured).toList();
  }

  /// Get user-owned items
  Future<List<StoreItemModel>> getOwnedItems(List<String> ownedIds) async {
    final items = await getAllItems(); // Use enhanced getAllItems
    return items.where((item) => ownedIds.contains(item.id)).toList();
  }

  /// Filter by category
  Future<List<StoreItemModel>> getItemsByCategory(String category) async {
    final items = await getAllItems(); // Use enhanced getAllItems
    return items.where((item) => item.category == category).toList();
  }

  /// Get available categories
  Future<List<String>> getCategories() async {
    final items = await getAllItems();
    final categories = items.map((item) => item.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Search items by name or description
  Future<List<StoreItemModel>> searchItems(String query) async {
    final items = await getAllItems();
    final lowerQuery = query.toLowerCase();

    return items.where((item) {
      return item.name.toLowerCase().contains(lowerQuery) ||
          (item.description.toLowerCase().contains(lowerQuery) ?? false) ||
          item.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get item by ID
  Future<StoreItemModel?> getItemById(String itemId) async {
    final items = await getAllItems();
    try {
      return items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Cache items to persistent storage
  Future<void> _cacheItemsToStorage(List<StoreItemModel> items) async {
    try {
      final box = await Hive.openBox(_storeBoxName);
      final itemsJson = items.map((item) => item.toJson()).toList();

      await box.put('cached_items', itemsJson);
      await box.put(_cacheTimestampKey, DateTime.now().toIso8601String());

      print('Store items cached: ${items.length} items');
    } catch (e) {
      print('Failed to cache items: $e');
    }
  }

  /// Load items from persistent storage
  Future<List<StoreItemModel>> _loadItemsFromStorage() async {
    try {
      final box = await Hive.openBox(_storeBoxName);
      final cachedItemsJson = box.get('cached_items');

      if (cachedItemsJson is List) {
        return cachedItemsJson
            .map((json) => StoreItemModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    } catch (e) {
      print('Failed to load cached items: $e');
    }

    return [];
  }

  /// Check if store data needs refresh
  Future<bool> needsRefresh() async {
    final lastRefresh = await _getLastRefresh();
    if (lastRefresh == null) return true;

    final timeSinceRefresh = DateTime.now().difference(lastRefresh);
    return timeSinceRefresh > _refreshInterval;
  }

  /// LIFECYCLE METHOD: Refreshes store data from server
  /// Called when app resumes or when data needs to be updated
  Future<void> refreshStoreData() async {
    try {
      print('Refreshing store data...');

      // Clear current cache to force reload
      _invalidateCache();

      // Reload from StoreDataService (your original data source)
      final items = await StoreDataService.loadStoreItems();

      // Update cache
      _cachedItems = items;
      _lastCacheUpdate = DateTime.now();

      // Cache to storage
      await _cacheItemsToStorage(items);

      // Update refresh timestamp
      await _updateLastRefresh();

      print('Store data refreshed: ${items.length} items');
    } catch (e) {
      print('Failed to refresh store data: $e');
      rethrow;
    }
  }

  /// Force refresh (clears all caches)
  Future<void> forceRefresh() async {
    try {
      // Clear all caches
      _invalidateCache();
      final box = await Hive.openBox(_storeBoxName);
      await box.clear();

      // Refresh data
      await refreshStoreData();

      print('Store data force refreshed');
    } catch (e) {
      print('Failed to force refresh: $e');
      rethrow;
    }
  }

  /// Validate store data integrity
  Future<void> validateStoreData() async {
    try {
      final items = await getAllItems();
      bool needsRepair = false;

      // Check for invalid items
      final validItems = items.where((item) {
        return item.id.isNotEmpty &&
            item.name.isNotEmpty &&
            item.category.isNotEmpty;
      }).toList();

      if (validItems.length != items.length) {
        needsRepair = true;
        _cachedItems = validItems;
        await _cacheItemsToStorage(validItems);
      }

      if (needsRepair) {
        print('Store data integrity restored');
      }

      print('Store data validation completed');
    } catch (e) {
      print('Store data validation failed: $e');
    }
  }

  /// Update last refresh timestamp
  Future<void> _updateLastRefresh() async {
    try {
      final box = await Hive.openBox(_storeBoxName);
      await box.put(_lastRefreshKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Failed to update last refresh: $e');
    }
  }

  /// Get last refresh timestamp
  Future<DateTime?> _getLastRefresh() async {
    try {
      final box = await Hive.openBox(_storeBoxName);
      final refreshStr = box.get(_lastRefreshKey);
      return refreshStr != null ? DateTime.parse(refreshStr) : null;
    } catch (e) {
      return null;
    }
  }

  /// Cache management helpers
  bool _isCacheValid() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }

  void _invalidateCache() {
    _cachedItems = null;
    _lastCacheUpdate = null;
  }

  /// Get store statistics
  Future<Map<String, dynamic>> getStoreStats() async {
    try {
      final items = await getAllItems();
      final categories = await getCategories();
      final lastRefresh = await _getLastRefresh();

      // Count items by category
      final categoryCounts = <String, int>{};
      for (final item in items) {
        categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
      }

      // Count featured items
      final featuredCount = items.where((item) => item.isFeatured).length;

      return {
        'totalItems': items.length,
        'totalCategories': categories.length,
        'featuredItems': featuredCount,
        'categoryCounts': categoryCounts,
        'lastRefresh': lastRefresh?.toIso8601String(),
        'cacheValid': _isCacheValid(),
        'needsRefresh': await needsRefresh(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Export store data for backup
  Future<Map<String, dynamic>> exportStoreData() async {
    final items = await getAllItems();
    final stats = await getStoreStats();

    return {
      'items': items.map((item) => item.toJson()).toList(),
      'stats': stats,
      'exported': DateTime.now().toIso8601String(),
    };
  }

  /// Import store data from backup
  Future<void> importStoreData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('items')) {
        final itemsList = (data['items'] as List)
            .map((json) => StoreItemModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();

        // Cache the imported data
        _cachedItems = itemsList;
        await _cacheItemsToStorage(itemsList);

        await _updateLastRefresh();
      }

      print('Store data imported successfully');
    } catch (e) {
      print('Failed to import store data: $e');
      rethrow;
    }
  }

  /// Clear all store cache
  Future<void> clearStoreCache() async {
    final box = await Hive.openBox(_storeBoxName);
    await box.clear();
    _invalidateCache();
    print('Store cache cleared');
  }

  /// Check if item is available
  Future<bool> isItemAvailable(String itemId) async {
    final item = await getItemById(itemId);
    return item != null;
  }

  /// Get items by price range (if StoreItemModel has price field)
  Future<List<StoreItemModel>> getItemsByPriceRange(double minPrice, double maxPrice) async {
    final items = await getAllItems();
    return items.where((item) {
      // Assuming StoreItemModel has a price field - adjust as needed
      final price = 0.0; // Replace with actual price field: item.price ?? 0.0
      return price >= minPrice && price <= maxPrice;
    }).toList();
  }
}
