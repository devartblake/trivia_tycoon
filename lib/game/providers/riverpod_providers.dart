/// Barrel file — re-exports all provider modules.
///
/// Existing code that imports this file continues to work without change.
/// New code should prefer importing the specific module it needs.
///
/// Module layout:
///   core_providers.dart       — auth chain, storage, networking, router
///   game_providers.dart       — settings, quiz, leaderboard, theme, QR, store, encryption
///   profile_providers.dart    — currency, energy, lives, referral
///   arcade_providers.dart     — spin wheel, badges, seasonal, missions, tier, flow connect
///   admin_providers.dart      — admin filter, analytics
///   multiplayer_providers.dart — challenge coordination, matches
///   ui_state_providers.dart   — power-up equipment, notification badge, daily reward, premium
///   hub_providers.dart        — SignalR notification + match hubs
///   auth_providers.dart       — auth operations, isLoggedIn state
///   avatar_package_providers.dart — avatar package service
///   onboarding_providers.dart — onboarding progress & phase
///   game_session_provider.dart — active game session
///   question_providers.dart   — question hub service & repository
///   provider_bridge.dart      — bridge providers for routing
///   power_up_timer_provider.dart — power-up countdown timer
///   notification_providers.dart  — push notification management
library;

export 'core_providers.dart';
export 'game_providers.dart';
export 'profile_providers.dart';
export 'arcade_providers.dart';
export 'admin_providers.dart';
export 'multiplayer_providers.dart';
export 'ui_state_providers.dart';
export 'hub_providers.dart';
export 'auth_providers.dart';
export 'avatar_package_providers.dart';
export 'onboarding_providers.dart';
export 'game_session_provider.dart';
export 'question_providers.dart';
export 'provider_bridge.dart';
export 'power_up_timer_provider.dart';
export 'notification_providers.dart';
