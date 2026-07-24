import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptix/game/providers/auth_providers.dart';

/// Redirects anonymous device-guests away from account-required surfaces
/// (real-money store purchases, crypto wallet) toward the account-upgrade
/// prompt, instead of letting them reach a feature whose backend calls a
/// secure-channel-gated endpoint they can't complete as a guest.
///
/// Returns `null` (allow navigation) when the player is platform-linked or a
/// full account; otherwise redirects to [upgradeRoute] with a `from` query set
/// to the attempted location so the upgrade screen can show context and route
/// the player back afterwards.
///
/// Synchronous, so it composes with the other guards (chain it first and fall
/// through on null), mirroring [featureFlagGuard]:
/// ```dart
/// redirect: (context, state) async {
///   final r = accountRequiredGuard(context, state);
///   if (r != null) return r;
///   return onboardingGuard(context, state);
/// },
/// ```
String? accountRequiredGuard(
  BuildContext context,
  GoRouterState state, {
  String upgradeRoute = '/account-link',
}) {
  final container = ProviderScope.containerOf(context);
  if (container.read(hasUpgradedAccountProvider)) return null;

  final from = Uri.encodeQueryComponent(state.matchedLocation);
  return '$upgradeRoute?from=$from';
}
