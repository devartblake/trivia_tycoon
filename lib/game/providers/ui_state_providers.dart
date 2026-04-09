/// UI-state providers — power-up equipment, notification badge, daily reward,
/// premium status.
///
/// Depends only on [core_providers.dart].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/power_up_controller.dart';
import '../models/power_up.dart';
import '../state/premium_profile_state.dart';

// ---------------------------------------------------------------------------
// Power-ups
// ---------------------------------------------------------------------------

final equippedPowerUpProvider =
    StateNotifierProvider<PowerUpController, PowerUp?>((ref) {
  return PowerUpController(ref);
});

// ---------------------------------------------------------------------------
// Notification / UI badge state
// ---------------------------------------------------------------------------

final unreadNotificationsProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// Daily rewards
// ---------------------------------------------------------------------------

final dailyRewardsAvailableProvider = StateProvider<bool>((ref) => true);

// ---------------------------------------------------------------------------
// Premium status
// ---------------------------------------------------------------------------

final premiumStatusProvider = StateProvider<PremiumStatus>((ref) {
  return PremiumStatus(
    isPremium: false,
    discountPercent: 50,
    expiryDate: null,
  );
});

// ---------------------------------------------------------------------------
// Legacy global container
// Used by GameController for non-widget power-up access. Prefer passing a
// WidgetRef or Ref from the widget tree wherever possible.
// ---------------------------------------------------------------------------

// ignore: prefer_const_constructors
final refContainer = ProviderContainer();
