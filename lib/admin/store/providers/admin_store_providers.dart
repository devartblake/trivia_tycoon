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
  return ref.watch(adminStoreServiceProvider).fetchPolicy(sku);
});

// ── Reward Limits ─────────────────────────────────────────────────────────────

final adminRewardLimitsProvider =
    FutureProvider<List<RewardLimitFormModel>>((ref) {
  return ref.watch(adminStoreServiceProvider).fetchRewardLimits();
});

// ── Flash Sales ───────────────────────────────────────────────────────────────

final adminFlashSalesProvider =
    FutureProvider<List<FlashSaleFormModel>>((ref) {
  return ref.watch(adminStoreServiceProvider).fetchFlashSales();
});

// ── User Overrides ────────────────────────────────────────────────────────────

final adminPlayerOverridesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, playerId) async {
  if (playerId.isEmpty) return const [];
  return ref.watch(adminStoreServiceProvider).fetchPlayerOverrides(playerId);
});

// ── Analytics ─────────────────────────────────────────────────────────────────

final adminStoreAnalyticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminStoreServiceProvider).fetchAnalyticsSummary();
});
