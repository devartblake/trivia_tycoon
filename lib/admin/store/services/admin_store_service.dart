import '../../../core/services/api_service.dart';
import '../models/stock_policy_form_model.dart';
import '../models/stock_override_form_model.dart';

/// Thin service wrapping all /admin/store/* backend endpoints.
/// All methods throw [ApiRequestException] on network/server errors —
/// callers are responsible for handling and showing error feedback.
class AdminStoreService {
  final ApiService _api;

  AdminStoreService(this._api);

  // ── Stock Policies ──────────────────────────────────────────────────────────

  Future<List<StockPolicyFormModel>> fetchPolicies() async {
    final json = await _api.get('/admin/store/policies');
    final items = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((m) => StockPolicyFormModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<StockPolicyFormModel> fetchPolicy(String sku) async {
    final json = await _api.get('/admin/store/policies/$sku');
    return StockPolicyFormModel.fromJson(json);
  }

  Future<void> updatePolicy(StockPolicyFormModel model) {
    return _api.put(
      '/admin/store/policies/${model.sku}',
      body: model.toJson(),
    );
  }

  Future<void> resetPolicyStock(String sku) {
    return _api.post('/admin/store/policies/$sku/reset', body: const {});
  }

  // ── Reward Limits ───────────────────────────────────────────────────────────

  Future<List<RewardLimitFormModel>> fetchRewardLimits() async {
    final json = await _api.get('/admin/store/reward-limits');
    final items = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((m) =>
            RewardLimitFormModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> updateRewardLimit(RewardLimitFormModel model) {
    return _api.put(
      '/admin/store/reward-limits/${model.rewardId}',
      body: model.toJson(),
    );
  }

  // ── Flash Sales ─────────────────────────────────────────────────────────────

  Future<List<FlashSaleFormModel>> fetchFlashSales() async {
    final json = await _api.get('/admin/store/flash-sales');
    final items = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((m) =>
            FlashSaleFormModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> createFlashSale(FlashSaleFormModel model) {
    return _api.post('/admin/store/flash-sales', body: model.toJson());
  }

  Future<void> updateFlashSale(FlashSaleFormModel model) {
    return _api.put(
      '/admin/store/flash-sales/${model.saleId}',
      body: model.toJson(),
    );
  }

  Future<void> deleteFlashSale(String saleId) {
    return _api.delete('/admin/store/flash-sales/$saleId');
  }

  // ── User Overrides ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchPlayerOverrides(String playerId) async {
    final json = await _api.get('/admin/store/overrides/$playerId');
    final items = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<void> createOverride(StockOverrideFormModel model) {
    return _api.post('/admin/store/overrides', body: model.toJson());
  }

  Future<void> deleteOverride(String overrideId) {
    return _api.delete('/admin/store/overrides/$overrideId');
  }

  // ── Analytics ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchAnalyticsSummary() async {
    return _api.get('/admin/store/analytics/summary');
  }
}
