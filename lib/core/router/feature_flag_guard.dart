import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/models/app_config.dart';
import 'package:trivia_tycoon/game/providers/feature_flag_providers.dart';

/// Returns null (allow navigation) when [isEnabled] returns true for the
/// current [FeatureFlags], or redirects to ['/home'] when the feature is
/// disabled by the backend config.
///
/// Usage in a GoRoute:
/// ```dart
/// redirect: (context, state) => featureFlagGuard(
///   context, state,
///   isEnabled: (f) => f.realtimeMultiplayerEnabled,
/// ),
/// ```
///
/// To chain with an existing guard (e.g. onboardingGuard), call this first
/// and fall through on null. This avoids BuildContext-across-async-gap warnings
/// because featureFlagGuard is synchronous:
/// ```dart
/// redirect: (context, state) async {
///   final r = featureFlagGuard(context, state, isEnabled: (f) => f.socialEnabled);
///   if (r != null) return r;
///   return onboardingGuard(context, state);
/// },
/// ```
String? featureFlagGuard(
  BuildContext context,
  GoRouterState state, {
  required bool Function(FeatureFlags) isEnabled,
}) {
  final container = ProviderScope.containerOf(context);
  final flags = container.read(featureFlagsProvider);
  return isEnabled(flags) ? null : '/home';
}
