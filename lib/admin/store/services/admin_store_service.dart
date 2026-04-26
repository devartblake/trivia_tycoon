import '../../../core/services/api_service.dart';
import '../models/stock_policy_form_model.dart';
import '../models/stock_override_form_model.dart';

/// Thin service wrapping all /admin/store/* backend endpoints (handoff 2026-04-26).
/// All methods throw [ApiRequestException] on network/server errors —
/// callers are responsible for handling and showing error feedback.
///
/// All requests require the `X-Admin-Ops-Key` header — pass it via [ApiService]
/// using the admin-key override on the request level or set it globally.
class AdminStoreService {
  final ApiService _api;

  AdminStoreService(this._api);

  // ── Stock Policies ──────────────────────────────────────────────────────────

  /// `GET /admin/store/stock-policies`
  Future<List<StockPolicyFormModel>> fetchPolicies({
    bool? activeOnly,
    String? sku,
  }) async {
    final qp = <String, String>{};
    if (activeOnly != null) qp['activeOnly'] = activeOnly.toString();
    if (sku != null) qp['sku'] = sku;

    final json = await _api.get(
      '/admin/store/stock-policies',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final items = json['policies'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((m) => StockPolicyFormModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// `PUT /admin/store/stock-policies/{sku}` — create or update a policy.
  Future<StockPolicyFormModel> upsertPolicy(StockPolicyFormModel model) async {
    final json = await _api.put(
      '/admin/store/stock-policies/${model.sku}',
      body: {
        'maxQuantityPerUser': model.maxQuantity ?? 0,
        'resetInterval': model.resetInterval ?? 'none',
        'isActive': model.isPurchasable,
      },
    );
    return StockPolicyFormModel.fromJson(json);
  }

  /// `POST /admin/store/stock-policies/bulk-reset` — reset quantityUsed for all players.
  Future<Map<String, dynamic>> bulkResetPolicies({
    required List<String> skus,
    String? reason,
  }) {
    return _api.post(
      '/admin/store/stock-policies/bulk-reset',
      body: {
        'skus': skus,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  // ── Player Stock ────────────────────────────────────────────────────────────

  /// `GET /admin/store/player-stock/{playerId}` — view a player's stock state.
  Future<Map<String, dynamic>> fetchPlayerStock(String playerId) async {
    return _api.get('/admin/store/player-stock/$playerId');
  }

  /// `POST /admin/store/player-stock/{playerId}/override` — set/clear a per-player ceiling.
  Future<Map<String, dynamic>> overridePlayerStock({
    required String playerId,
    required String sku,
    int? effectiveMaxQuantity, // null clears the override
    String? reason,
  }) {
    return _api.post(
      '/admin/store/player-stock/$playerId/override',
      body: {
        'sku': sku,
        'effectiveMaxQuantity': effectiveMaxQuantity,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  // ── Reward Limits ───────────────────────────────────────────────────────────

  /// `GET /admin/store/reward-limits/{rewardId}` — get limit for one reward.
  Future<RewardLimitFormModel> fetchRewardLimit(String rewardId) async {
    final json = await _api.get('/admin/store/reward-limits/$rewardId');
    return RewardLimitFormModel.fromJson(json);
  }

  /// `PUT /admin/store/reward-limits/{rewardId}` — create or update.
  Future<RewardLimitFormModel> upsertRewardLimit(RewardLimitFormModel model) async {
    final json = await _api.put(
      '/admin/store/reward-limits/${model.rewardId}',
      body: {
        'maxClaimsPerInterval': model.maxClaimsPerInterval,
        'resetInterval': model.interval,
        'isActive': model.isActive,
      },
    );
    return RewardLimitFormModel.fromJson(json);
  }

  // ── Flash Sales ─────────────────────────────────────────────────────────────

  /// `GET /admin/store/flash-sales` — active and scheduled sales only.
  Future<List<FlashSaleFormModel>> fetchFlashSales() async {
    final json = await _api.get('/admin/store/flash-sales');
    // Backend returns { "sales": [...] }
    final items = json['sales'] as List<dynamic>? ??
        json['items'] as List<dynamic>? ??
        const <dynamic>[];
    return items
        .whereType<Map>()
        .map((m) => FlashSaleFormModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// `POST /admin/store/flash-sales` — create a flash sale.
  Future<FlashSaleFormModel> createFlashSale(FlashSaleFormModel model) async {
    final json = await _api.post(
      '/admin/store/flash-sales',
      body: {
        'sku': model.linkedSku,
        'discountPercent': model.discountPercent?.toInt() ?? 0,
        'startsAtUtc': model.startTime.toUtc().toIso8601String(),
        'endsAtUtc': model.endTime.toUtc().toIso8601String(),
        if (model.title.isNotEmpty) 'reason': model.title,
      },
    );
    return FlashSaleFormModel.fromJson(json);
  }

  /// `DELETE /admin/store/flash-sales/{id}` — soft-cancel (preserves audit history).
  Future<void> cancelFlashSale(String saleId) {
    return _api.delete('/admin/store/flash-sales/$saleId');
  }

  // ── Analytics ───────────────────────────────────────────────────────────────

  /// `GET /admin/store/analytics/purchases` — aggregate purchase stats.
  Future<Map<String, dynamic>> fetchPurchaseAnalytics({
    DateTime? from,
    DateTime? to,
    String? sku,
  }) {
    final qp = <String, String>{};
    if (from != null) qp['from'] = from.toUtc().toIso8601String();
    if (to != null) qp['to'] = to.toUtc().toIso8601String();
    if (sku != null) qp['sku'] = sku;
    return _api.get(
      '/admin/store/analytics/purchases',
      queryParameters: qp.isEmpty ? null : qp,
    );
  }

  /// `GET /admin/store/analytics/stock-resets` — paginated reset history.
  Future<Map<String, dynamic>> fetchStockResetHistory({
    String? sku,
    int page = 1,
    int pageSize = 50,
  }) {
    final qp = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (sku != null) qp['sku'] = sku;
    return _api.get('/admin/store/analytics/stock-resets', queryParameters: qp);
  }
}
