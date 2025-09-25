import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/state/tier_update_result.dart';
import '../../core/manager/tier_manager.dart';
import '../models/tier_model.dart';

/// Represents the current state of tier progression
class TierProgressionState {
  final bool isUpdating;
  final TierUpdateResult? lastUpdate;
  final String? error;

  const TierProgressionState({
    this.isUpdating = false,
    this.lastUpdate,
    this.error,
  });

  TierProgressionState copyWith({
    bool? isUpdating,
    TierUpdateResult? lastUpdate,
    String? error,
  }) {
    return TierProgressionState(
      isUpdating: isUpdating ?? this.isUpdating,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TierProgressionState &&
        other.isUpdating == isUpdating &&
        other.lastUpdate == lastUpdate &&
        other.error == error;
  }

  @override
  int get hashCode {
    return isUpdating.hashCode ^ lastUpdate.hashCode ^ error.hashCode;
  }

  @override
  String toString() {
    return 'TierProgressionState(isUpdating: $isUpdating, lastUpdate: $lastUpdate, error: $error)';
  }
}

/// Notifier for managing tier progression state and operations
class TierProgressionNotifier extends StateNotifier<TierProgressionState> {
  final TierManager _tierManager;
  final Ref _ref;

  TierProgressionNotifier(this._tierManager, this._ref) : super(const TierProgressionState());

  /// Update tier progression and return the result
  Future<TierUpdateResult> updateTierProgress() async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      final result = await _tierManager.updateTierProgress();
      state = state.copyWith(
        isUpdating: false,
        lastUpdate: result,
      );

      // Invalidate related providers to trigger UI updates
      if (result.tierChanged || result.hasNewUnlocks) {
        _invalidateTierProviders();
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Reset tier progress (for testing/admin)
  Future<void> resetTierProgress() async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      await _tierManager.resetTierProgress();
      state = state.copyWith(
        isUpdating: false,
        lastUpdate: null,
      );

      // Force refresh all tier-related providers
      _invalidateTierProviders();
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Award tier rewards manually (for admin/testing)
  Future<void> awardTierRewards(TierModel tier) async {
    try {
      await _tierManager.awardTierRewards(tier);
    } catch (e) {
      state = state.copyWith(error: 'Failed to award rewards: $e');
      rethrow;
    }
  }

  /// Get tier by ID
  TierModel? getTierById(int id) {
    return _tierManager.getTierById(id);
  }

  /// Check if player meets requirements for a specific tier
  Future<bool> meetsRequirementsForTier(int tierId) async {
    final tier = getTierById(tierId);
    if (tier == null) return false;

    // This would typically check against player profile
    // Implementation depends on your profile service structure
    return false; // Placeholder
  }

  /// Get next milestone tier (next major tier unlock)
  Future<TierModel?> getNextMilestoneTier() async {
    final allTiers = await _tierManager.getAllTiers();
    final currentTierId = await _tierManager.getCurrentTierId();

    // Find next significant tier (e.g., every 3rd tier)
    for (int i = currentTierId + 1; i < allTiers.length; i++) {
      if (i % 3 == 0) { // Milestone every 3rd tier
        return allTiers[i];
      }
    }

    return null;
  }

  /// Clear any error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Private helper to invalidate tier-related providers
  void _invalidateTierProviders() {
    // Note: These provider names should match your actual provider names
    try {
      _ref.invalidate(currentTierProvider);
      _ref.invalidate(currentTierIdProvider);
      _ref.invalidate(allTiersProvider);
      _ref.invalidate(nextTierProvider);
      _ref.invalidate(tierProgressPercentageProvider);
    } catch (e) {
      // Silently handle provider invalidation errors
      // This prevents cascading errors if providers don't exist yet
    }
  }
}

/// Extension helper for easy tier operations
extension TierProgressionNotifierExtensions on TierProgressionNotifier {
  /// Quick check if currently updating
  bool get isUpdating => state.isUpdating;

  /// Quick access to last tier update result
  TierUpdateResult? get lastUpdate => state.lastUpdate;

  /// Quick check if there's an error
  bool get hasError => state.error != null;

  /// Quick access to error message
  String? get errorMessage => state.error;

  /// Check if last update resulted in tier change
  bool get hadTierChange => state.lastUpdate?.tierChanged ?? false;

  /// Check if last update had new unlocks
  bool get hadNewUnlocks => state.lastUpdate?.hasNewUnlocks ?? false;
}

// Provider references (these will be defined in river-pod_providers.dart)
// This is just for type checking - actual providers are defined elsewhere
abstract class _ProviderReferences {
  static const currentTierProvider = null;
  static const currentTierIdProvider = null;
  static const allTiersProvider = null;
  static const nextTierProvider = null;
  static const tierProgressPercentageProvider = null;
}

// Use the references to avoid import issues
final currentTierProvider = _ProviderReferences.currentTierProvider;
final currentTierIdProvider = _ProviderReferences.currentTierIdProvider;
final allTiersProvider = _ProviderReferences.allTiersProvider;
final nextTierProvider = _ProviderReferences.nextTierProvider;
final tierProgressPercentageProvider = _ProviderReferences.tierProgressPercentageProvider;