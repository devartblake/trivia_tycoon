import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/auth_providers.dart';
import '../../game/providers/onboarding_providers.dart'
    show onboardingCompleteProvider;
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Navigation redirect service that determines where users should be redirected.
class NavigationRedirectService {
  final Ref ref;

  NavigationRedirectService(this.ref);

  String? determineRedirect(String currentPath) {
    final isLoggedIn = ref.read(isLoggedInSyncProvider);
    final profileSelected = ref.read(profileSelectedProvider);
    final identityState = ref.read(playerIdentityProvider);
    final isOnboardingComplete = ref.read(onboardingCompleteProvider);

    LogManager.debug(
      'REDIRECT DEBUG: isLoggedIn=$isLoggedIn, profileSelected=$profileSelected, '
      'identityReady=${identityState.isReady}, onboardingComplete=$isOnboardingComplete, path=$currentPath',
    );

    if (currentPath == '/') return null;

    final isAuthPath = currentPath == '/login' ||
        currentPath == '/signup' ||
        currentPath == '/register';

    if (!identityState.hasPlayableIdentity) {
      if (currentPath == '/onboarding') return null;
      if (isAuthPath) return null;
      return '/onboarding';
    }

    if (!isOnboardingComplete) {
      if (currentPath == '/onboarding' || isAuthPath) return null;
      return '/onboarding';
    }

    if (isLoggedIn && !profileSelected) {
      if (currentPath == '/profile-selection') return null;
      return '/profile-selection';
    }

    if (currentPath == '/onboarding' || currentPath == '/profile-selection') {
      return '/home';
    }

    return null;
  }
}

final navigationRedirectServiceProvider =
    Provider<NavigationRedirectService>((ref) {
  return NavigationRedirectService(ref);
});

final navigationStateProvider = Provider<NavigationState>((ref) {
  final isLoggedIn = ref.watch(isLoggedInSyncProvider);
  final profileSelected = ref.watch(profileSelectedProvider);
  final identityState = ref.watch(playerIdentityProvider);
  final isOnboardingComplete = ref.watch(onboardingCompleteProvider);

  return NavigationState(
    isLoggedIn: isLoggedIn,
    profileSelected: profileSelected,
    identityReady: identityState.isReady,
    identityKind: identityState.kind,
    isOnboardingComplete: isOnboardingComplete,
  );
});

class NavigationState {
  final bool isLoggedIn;
  final bool profileSelected;
  final bool identityReady;
  final PlayerIdentityKind identityKind;
  final bool isOnboardingComplete;

  const NavigationState({
    required this.isLoggedIn,
    required this.profileSelected,
    required this.identityReady,
    required this.identityKind,
    required this.isOnboardingComplete,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationState &&
          runtimeType == other.runtimeType &&
          isLoggedIn == other.isLoggedIn &&
          profileSelected == other.profileSelected &&
          identityReady == other.identityReady &&
          identityKind == other.identityKind &&
          isOnboardingComplete == other.isOnboardingComplete;

  @override
  int get hashCode =>
      isLoggedIn.hashCode ^
      profileSelected.hashCode ^
      identityReady.hashCode ^
      identityKind.hashCode ^
      isOnboardingComplete.hashCode;
}
