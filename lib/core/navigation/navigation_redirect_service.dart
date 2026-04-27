import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/auth_providers.dart';
import '../../game/providers/onboarding_providers.dart'
    show onboardingCompleteProvider;
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Navigation redirect service that determines where users should be redirected
class NavigationRedirectService {
  final Ref ref;

  NavigationRedirectService(this.ref);

  String? determineRedirect(String currentPath) {
    final isLoggedIn = ref.read(isLoggedInSyncProvider);
    final profileSelected = ref.read(profileSelectedProvider);
    final isOnboardingComplete = ref.read(onboardingCompleteProvider);

    LogManager.debug(
        'REDIRECT DEBUG: isLoggedIn=$isLoggedIn, profileSelected=$profileSelected, '
        'onboardingComplete=$isOnboardingComplete, path=$currentPath');

    // 1) Always allow splash / root
    if (currentPath == '/') return null;

    // 2) Not logged in → auth screens only
    if (!isLoggedIn) {
      if (currentPath == '/login' || currentPath == '/signup') return null;
      return '/login';
    }

    // 3) Logged in but no profile chosen this session → profile selection gate.
    //    This runs on every cold start / crash recovery because profileSelectedProvider
    //    is runtime-only and always initialises to false.
    if (!profileSelected) {
      if (currentPath == '/profile-selection') return null;
      return '/profile-selection';
    }

    // 4) Profile chosen but onboarding not done → gate to /onboarding
    if (!isOnboardingComplete) {
      if (currentPath == '/onboarding') return null;
      return '/onboarding';
    }

    // 5) Fully onboarded → redirect away from auth/onboarding/profile-selection
    if (currentPath == '/onboarding' ||
        currentPath == '/login' ||
        currentPath == '/signup' ||
        currentPath == '/profile-selection') {
      return '/home';
    }

    return null;
  }
}

/// Provider for the navigation redirect service
final navigationRedirectServiceProvider =
    Provider<NavigationRedirectService>((ref) {
  return NavigationRedirectService(ref);
});

/// Provider that watches for navigation state changes and triggers router rebuilds.
final navigationStateProvider = Provider<NavigationState>((ref) {
  final isLoggedIn = ref.watch(isLoggedInSyncProvider);
  final profileSelected = ref.watch(profileSelectedProvider);
  final isOnboardingComplete = ref.watch(onboardingCompleteProvider);

  return NavigationState(
    isLoggedIn: isLoggedIn,
    profileSelected: profileSelected,
    isOnboardingComplete: isOnboardingComplete,
  );
});

class NavigationState {
  final bool isLoggedIn;
  final bool profileSelected;
  final bool isOnboardingComplete;

  const NavigationState({
    required this.isLoggedIn,
    required this.profileSelected,
    required this.isOnboardingComplete,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationState &&
          runtimeType == other.runtimeType &&
          isLoggedIn == other.isLoggedIn &&
          profileSelected == other.profileSelected &&
          isOnboardingComplete == other.isOnboardingComplete;

  @override
  int get hashCode =>
      isLoggedIn.hashCode ^ profileSelected.hashCode ^ isOnboardingComplete.hashCode;
}
