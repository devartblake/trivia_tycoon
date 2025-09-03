import '../../../game/services/store_data_service.dart';
import '../../../game/models/store_item_model.dart';
import '../api_service.dart';

class StoreService {
  final ApiService apiService;

  StoreService._(this.apiService);

  static Future<StoreService> initialize(ApiService apiService) async {
    // Load store items, categories, avatars, etc. here
    return StoreService._(apiService);
  }

  /// Load all store items
  Future<List<StoreItemModel>> getAllItems() async {
    return await StoreDataService.loadStoreItems();
  }

  /// Filter for featured items
  Future<List<StoreItemModel>> getFeaturedItems() async {
    final items = await StoreDataService.loadStoreItems();
    return items.where((item) => item.isFeatured).toList();
  }

  /// Get user-owned items
  Future<List<StoreItemModel>> getOwnedItems(List<String> ownedIds) async {
    final items = await StoreDataService.loadStoreItems();
    return items.where((item) => ownedIds.contains(item.id)).toList();
  }

  /// Filter by category
  Future<List<StoreItemModel>> getItemsByCategory(String category) async {
    final items = await StoreDataService.loadStoreItems();
    return items.where((item) => item.category == category).toList();
  }
}
