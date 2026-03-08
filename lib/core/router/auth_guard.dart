import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

Future<String?> authGuard(BuildContext context, GoRouterState state) async {
  final container = ProviderScope.containerOf(context);
  final authService = container.read(authServiceProvider);

  final isLoggedIn = await authService.isLoggedIn();
  return isLoggedIn ? null : '/login';
}

/// Redirects non-admins or users with admin mode disabled
Future<String?> adminGuard(BuildContext context, GoRouterState state) async {
  final container = ProviderScope.containerOf(context);
  final adminSettings = container.read(adminSettingsServiceProvider);

  final isAdmin = await adminSettings.isAdminUser();
  final isAdminMode = await adminSettings.isAdminMode();

  return (isAdmin && isAdminMode) ? null : '/';
}

/// Redirects users who haven't completed onboarding
Future<String?> onboardingGuard(BuildContext context, GoRouterState state) async {
  final container = ProviderScope.containerOf(context);
  final onboardingService = container.read(onboardingSettingsServiceProvider);

  final hasCompleted = await onboardingService.hasCompletedOnboarding();
  return hasCompleted ? null : '/onboarding';
}

/// Redirects access to certain features (e.g. bonus content, leaderboard perks) for premium users.
Future<String?> premiumGuard(BuildContext context, GoRouterState state) async {
  final container = ProviderScope.containerOf(context);
  final userProfile = container.read(playerProfileServiceProvider);
  final isPremium = await userProfile.isPremiumUser();

  return isPremium ? null : '/upgrade';
}

/// Enables routes based on roles like moderator, editor, tester or superAdmin
Future<String?> roleGuard(BuildContext context, GoRouterState state, String requiredRole) async {
  final container = ProviderScope.containerOf(context);
  final userProfile = container.read(playerProfileServiceProvider);
  final roles = await userProfile.getUserRoles();

  return roles.contains(requiredRole) ? null : '/unauthorized';
}

