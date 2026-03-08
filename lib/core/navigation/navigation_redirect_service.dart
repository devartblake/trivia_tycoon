import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/settings/onboarding_settings_service.dart';
import '../../game/providers/auth_providers.dart';
import '../../game/providers/onboarding_providers.dart';

/// Navigation redirect service that determines where users should be redirected.
class NavigationRedirectService {
  final Ref ref;

  NavigationRedirectService(this.ref);

  static OnboardingPhase _phaseFromProgress(OnboardingProgress progress) {
    if (progress.completed) return OnboardingPhase.done;
    if (!progress.hasSeenIntro) return OnboardingPhase.intro;
    if (!progress.hasCompletedProfile) return OnboardingPhase.profileSetup;
    return OnboardingPhase.done;
  }

  static String? resolveOnboardingRedirect({
    required String currentPath,
    required bool isLoggedIn,
    required OnboardingPhase phase,
  }) {
    // Not authenticated: allow auth paths, block protected paths.
    if (!isLoggedIn) {
      if (currentPath == '/login' || currentPath == '/signup') return null;
      return '/login';
    }

    // Authenticated users should not stay on auth screens.
    if (currentPath == '/login' || currentPath == '/signup') {
      return '/home';
    }

    // Onboarding policy.
    switch (phase) {
      case OnboardingPhase.done:
        // Keep completed users away from onboarding-only routes.
        if (currentPath == '/onboarding' ||
            currentPath == '/profile-selection' ||
            currentPath == '/avatar-selection') {
          return '/home';
        }
        return null;
      case OnboardingPhase.intro:
      case OnboardingPhase.profileSetup:
        // During onboarding, keep user in onboarding flow routes.
        const allowed = {
          '/onboarding',
          '/profile-selection',
          '/avatar-selection',
        };
        if (allowed.contains(currentPath)) return null;
        return '/onboarding';
    }
  }

  String? determineRedirect(String currentPath) {
    final isLoggedIn = ref.read(isLoggedInSyncProvider);
    final progress = ref.read(onboardingProgressProvider).progress;
    final phase = _phaseFromProgress(progress);

    final redirect = resolveOnboardingRedirect(
      currentPath: currentPath,
      isLoggedIn: isLoggedIn,
      phase: phase,
    );

    debugPrint(
      '[NavRedirect] path=$currentPath, isLoggedIn=$isLoggedIn, phase=$phase, '
      'completed=${progress.completed}, step=${progress.currentStep}, redirect=$redirect',
    );

    return redirect;
  }
}

/// Provider for the navigation redirect service
final navigationRedirectServiceProvider = Provider<NavigationRedirectService>((ref) {
  return NavigationRedirectService(ref);
});

/// Provider that watches for navigation state changes
final navigationStateProvider = Provider<NavigationState>((ref) {
  final isLoggedIn = ref.watch(isLoggedInSyncProvider);
  final progress = ref.watch(onboardingProgressProvider).progress;

  return NavigationState(
    isLoggedIn: isLoggedIn,
    onboardingPhase: NavigationRedirectService._phaseFromProgress(progress),
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
