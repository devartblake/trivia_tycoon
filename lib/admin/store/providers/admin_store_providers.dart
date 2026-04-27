import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../models/stock_policy_form_model.dart';
import '../models/stock_override_form_model.dart';
import '../services/admin_store_service.dart';

final adminStoreServiceProvider = Provider<AdminStoreService>((ref) {
  return AdminStoreService(ref.watch(apiServiceProvider));
});

// ── Stock Policies ────────────────────────────────────────────────────────────

final adminStorePoliciesProvider =
    FutureProvider<List<StockPolicyFormModel>>((ref) {
  return ref.watch(adminStoreServiceProvider).fetchPolicies();
});

final adminStorePolicyProvider =
    FutureProvider.family<StockPolicyFormModel, String>((ref, sku) {
  // Re-use the list provider and filter — avoids an extra endpoint call.
  return ref.watch(adminStorePoliciesProvider.future).then(
        (policies) => policies.firstWhere(
          (p) => p.sku == sku,
          orElse: () => StockPolicyFormModel(sku: sku, itemTitle: '', itemType: ''),
        ),
      );
});

// ── Player Stock ──────────────────────────────────────────────────────────────

final adminPlayerStockProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, playerId) async {
  if (playerId.isEmpty) return const {};
  return ref.watch(adminStoreServiceProvider).fetchPlayerStock(playerId);
});

// ── Reward Limits ─────────────────────────────────────────────────────────────

final adminRewardLimitProvider =
    FutureProvider.family<RewardLimitFormModel, String>((ref, rewardId) {
  return ref.watch(adminStoreServiceProvider).fetchRewardLimit(rewardId);
});

// ── Flash Sales ───────────────────────────────────────────────────────────────

final adminFlashSalesProvider =
    FutureProvider<List<FlashSaleFormModel>>((ref) {
  return ref.watch(adminStoreServiceProvider).fetchFlashSales();
});

// ── Analytics ─────────────────────────────────────────────────────────────────

final adminPurchaseAnalyticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminStoreServiceProvider).fetchPurchaseAnalytics();
});

final adminStockResetHistoryProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminStoreServiceProvider).fetchStockResetHistory();
});

// ── Backward-compatible aliases ───────────────────────────────────────────────

/// Alias kept for screens that watch adminStoreAnalyticsProvider.
final adminStoreAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminPurchaseAnalyticsProvider.future);
});

/// Backend has no list endpoint for reward limits; returns empty until one is added.
final adminRewardLimitsProvider =
    FutureProvider<List<RewardLimitFormModel>>((ref) async {
  return const <RewardLimitFormModel>[];
});

/// Returns the override-eligible stock items for a specific player.
final adminPlayerOverridesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, playerId) async {
  if (playerId.isEmpty) return const [];
  final stock =
      await ref.watch(adminStoreServiceProvider).fetchPlayerStock(playerId);
  final items = stock['items'] as List<dynamic>? ?? const [];
  return items
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .toList();
});
