import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/auth_providers.dart';
import '../../game/providers/onboarding_providers.dart' show onboardingCompleteProvider;
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Navigation redirect service that determines where users should be redirected
class NavigationRedirectService {
  final Ref ref;

  NavigationRedirectService(this.ref);

  String? determineRedirect(String currentPath) {
    final isLoggedIn = ref.read(isLoggedInSyncProvider);
    final isOnboardingComplete = ref.read(onboardingCompleteProvider);

    LogManager.debug(
      'REDIRECT DEBUG: isLoggedIn=$isLoggedIn, onboardingComplete=$isOnboardingComplete, path=$currentPath');

    // 1) Always allow splash / root
    if (currentPath == '/') return null;

    // 2) Not logged in → auth screens only
    if (!isLoggedIn) {
      if (currentPath == '/login' || currentPath == '/signup') return null;
      return '/login';
    }

    // 3) Logged in but onboarding not done → gate to /onboarding
    if (!isOnboardingComplete) {
      if (currentPath == '/onboarding') return null;
      return '/onboarding';
      }

      // 4) Fully onboarded → redirect away from auth/onboarding screens
      if (currentPath == '/onboarding' ||
          currentPath == '/login' ||
          currentPath == '/signup') {
        return '/home';
      }

      return null;
    }
  }
}

/// Provider for the navigation redirect service
final navigationRedirectServiceProvider = Provider<NavigationRedirectService>((ref) {
  return NavigationRedirectService(ref);
});

/// Provider that watches for navigation state changes and triggers router rebuilds.
final navigationStateProvider = Provider<NavigationState>((ref) {
  final isLoggedIn = ref.watch(isLoggedInSyncProvider);
  final isOnboardingComplete = ref.watch(onboardingCompleteProvider);

  return NavigationState(
    isLoggedIn: isLoggedIn,
    isOnboardingComplete: isOnboardingComplete,
  );
});

class NavigationState {
  final bool isLoggedIn;
  final bool isOnboardingComplete;

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
