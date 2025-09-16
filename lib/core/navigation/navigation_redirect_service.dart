import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/auth_providers.dart';
import '../../game/providers/onboarding_providers.dart';

/// Navigation redirect service that determines where users should be redirected
class NavigationRedirectService {
  final Ref ref;

  NavigationRedirectService(this.ref);

  String? determineRedirect(String currentPath) {
    final isLoggedIn = ref.read(isLoggedInSyncProvider);
    final onboardingPhase = ref.read(onboardingPhaseProvider);

    // Debug logging
    debugPrint('REDIRECT DEBUG: isLoggedIn = $isLoggedIn, path = $currentPath, phase = $onboardingPhase');

    // 1) Always allow splash screen
    if (currentPath == '/') return null;

    // 2) If not logged in -> force auth (except on auth screens)
    if (!isLoggedIn) {
      if (currentPath == '/login' || currentPath == '/signup') return null;
      return '/login';
    }

    // 3) Logged in → gate by onboarding phase
    switch (onboardingPhase) {
      case OnboardingPhase.intro:
        if (currentPath != '/intro') return '/intro';
        return null;
      case OnboardingPhase.profileSetup:
        if (currentPath != '/profile-setup') return '/profile-setup';
        return null;
      case OnboardingPhase.done:
      // Redirect away from auth/onboarding screens if already complete
        if (['/intro', '/profile-setup', '/login', '/signup'].contains(currentPath)) {
          return '/main';
        }
        return null;
    }
  }
}

/// Provider for the navigation redirect service
final navigationRedirectServiceProvider = Provider<NavigationRedirectService>((ref) {
  return NavigationRedirectService(ref);
});

/// Provider that watches for navigation state changes
final navigationStateProvider = Provider<NavigationState>((ref) {
  final isLoggedIn = ref.watch(isLoggedInSyncProvider);
  final onboardingPhase = ref.watch(onboardingPhaseProvider);

  return NavigationState(
    isLoggedIn: isLoggedIn,
    onboardingPhase: onboardingPhase,
  );
});

class NavigationState {
  final bool isLoggedIn;
  final OnboardingPhase onboardingPhase;

  const NavigationState({
    required this.isLoggedIn,
    required this.onboardingPhase,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is NavigationState &&
              runtimeType == other.runtimeType &&
              isLoggedIn == other.isLoggedIn &&
              onboardingPhase == other.onboardingPhase;

  @override
  int get hashCode => isLoggedIn.hashCode ^ onboardingPhase.hashCode;
}
