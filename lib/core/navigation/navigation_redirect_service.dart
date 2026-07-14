import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/auth_providers.dart';
import '../../game/providers/onboarding_providers.dart'
    show onboardingCompleteProvider;
import 'package:synaptix/core/manager/log_manager.dart';
import 'canonical_routes.dart';

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

    final isAuthPath = currentPath == canonicalLoginRoute ||
        currentPath == canonicalRegisterRoute ||
        currentPath == '/auth' ||
        currentPath == '/signup';
    final isOnboardingPath = currentPath == canonicalOnboardingRoute;
    final hasAccountIdentity =
        identityState.kind == PlayerIdentityKind.fullAccount ||
            identityState.kind == PlayerIdentityKind.platformLinked;

    if (!identityState.hasPlayableIdentity) {
      if (isOnboardingPath) return null;
      if (isAuthPath) return null;
      return canonicalLoginRoute;
    }

    if (!isOnboardingComplete) {
      if (isOnboardingPath || isAuthPath) return null;
      return hasAccountIdentity
          ? canonicalOnboardingRoute
          : canonicalLoginRoute;
    }

    if (hasAccountIdentity && !profileSelected) {
      if (currentPath == '/profile-selection') return null;
      return '/profile-selection';
    }

    if (isOnboardingPath || currentPath == '/profile-selection') {
      return canonicalHomeRoute;
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
