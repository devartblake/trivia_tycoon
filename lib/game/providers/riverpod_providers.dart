/// Barrel file — re-exports all domain provider files.
///
/// Existing import sites (`import '...riverpod_providers.dart'`) continue to
/// work without modification.  New code should import the specific domain
/// file directly for better readability and faster incremental compilation:
///
///   import 'package:trivia_tycoon/game/providers/core_providers.dart';
///   import 'package:trivia_tycoon/game/providers/game_providers.dart';
///   import 'package:trivia_tycoon/game/providers/profile_providers.dart';
///   import 'package:trivia_tycoon/game/providers/multiplayer_providers.dart';
///   import 'package:trivia_tycoon/game/providers/admin_providers.dart';
///   import 'package:trivia_tycoon/game/providers/arcade_providers.dart';
///
/// See also: [providers/index.dart] for a single convenience import.
library;

export 'core_providers.dart';
export 'game_providers.dart';
export 'profile_providers.dart';
export 'multiplayer_providers.dart';
export 'admin_providers.dart';
export 'arcade_providers.dart';

// ---------------------------------------------------------------------------
// Providers that remain here pending further migration
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/controllers/power_up_controller.dart';
import '../../game/models/power_up.dart';
import '../../game/state/premium_profile_state.dart';
import 'profile_providers.dart';

// Power-ups
final equippedPowerUpProvider =
    StateNotifierProvider<PowerUpController, PowerUp?>((ref) {
  return PowerUpController(ref);
});

// UI badge state
final unreadNotificationsProvider = StateProvider<int>((ref) => 0);
final dailyRewardsAvailableProvider = StateProvider<bool>((ref) => true);

// Premium status
final premiumStatusProvider = StateProvider<PremiumStatus>((ref) {
  return PremiumStatus(
    isPremium: false,
    discountPercent: 50,
    expiryDate: null,
  );
});

// Non-widget access container (legacy — prefer passing ProviderContainer via DI)
// ignore: prefer_const_constructors
final refContainer = ProviderContainer();
