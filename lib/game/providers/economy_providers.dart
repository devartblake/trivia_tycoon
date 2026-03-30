/// Economy providers — energy-gated mode entry, daily ticket, revive, pity.
///
/// Depends on [core_providers.dart], [profile_providers.dart], and the
/// analytics providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dto/economy_dto.dart';
import '../../game/analytics/providers/analytics_providers.dart';
import '../../game/controllers/economy_notifier.dart';
import 'core_providers.dart';
import 'profile_providers.dart';

// ── Core economy state ───────────────────────────────────────────────────────

final economyProvider =
    StateNotifierProvider<EconomyNotifier, EconomyState>((ref) {
  return EconomyNotifier(
    ref.read(tycoonApiClientProvider),
    ref.read(energyProvider.notifier),
    ref.read(analyticsServiceProvider),
    ref.read(generalKeyValueStorageProvider),
  );
});

// ── Derived providers ────────────────────────────────────────────────────────

/// Cost info for a specific mode name ('casual', 'ranked', 'guardian', 'jackpot').
final modeCostProvider = Provider.family<ModeCostDto?, String>((ref, mode) {
  return ref.watch(economyProvider).modes[mode];
});

/// True once the economy state has been loaded from the server at least once.
final economyLoadedProvider = Provider<bool>((ref) {
  return ref.watch(economyProvider).lastFetched != null;
});

/// User-facing reason why a mode cannot be entered, or null if entry is allowed.
final modeDenyReasonProvider = Provider.family<String?, String>((ref, mode) {
  final cost = ref.watch(modeCostProvider(mode));
  if (cost == null || cost.available) return null;
  return switch (cost.costType) {
    'energy' => 'Not enough energy',
    'ticket' => 'No ticket available',
    _        => 'Mode unavailable right now',
  };
});

/// True when the jackpot daily ticket can still be claimed today.
final dailyTicketAvailableProvider = Provider<bool>((ref) {
  return ref.watch(economyProvider).dailyTicketAvailable;
});

/// Number of jackpot tickets remaining today.
final dailyTicketsRemainingProvider = Provider<int>((ref) {
  return ref.watch(economyProvider).dailyTicketsRemaining;
});

/// True when the pity protection is active (player on a losing streak).
final pityActiveProvider = Provider<bool>((ref) {
  return ref.watch(economyProvider).pityActive;
});
