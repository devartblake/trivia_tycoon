import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'auth_providers.dart';
import 'onboarding_providers.dart';

/// Bridge providers that connect your existing services with the new provider system
/// This allows the new routing logic to work with your existing service architecture

/// Provider that reads auth state from your existing AuthService
final authStatusProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isLoggedIn();
});

/// Provider that reads onboarding state from your existing OnboardingService
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final onboardingService = ref.watch(onboardingSettingsServiceProvider);
  return await onboardingService.hasCompletedOnboarding();
});

/// Provider that bridges auth state for router consumption
/// This replaces the simple StateProvider with actual service integration
final bridgedIsLoggedInProvider = Provider<bool>((ref) {
  // Watch both the simple state provider (for immediate updates)
  // and the service provider (for persistence)
  final simpleState = ref.watch(isLoggedInSyncProvider);
  final authStatus = ref.watch(authStatusProvider);

  // If simple state is true (user just logged in), use that
  if (simpleState) return true;

  // Otherwise, check the persisted state
  return authStatus.maybeWhen(
    data: (isLoggedIn) => isLoggedIn,
    orElse: () => false,
  );
});

/// Provider that bridges onboarding intro state
final bridgedHasSeenIntroProvider = Provider<bool>((ref) {
  final simpleState = ref.watch(hasSeenIntroProvider);

  // For intro, we can rely on the simple state since it's session-based
  // Your existing onboarding service tracks overall completion
  return simpleState;
});

/// Provider that bridges onboarding profile state
final bridgedHasCompletedProfileProvider = Provider<bool>((ref) {
  final simpleState = ref.watch(hasCompletedProfileProvider);

  // For profile setup, we can rely on the simple state since it's session-based
  return simpleState;
});

/// Provider that calculates onboarding phase using bridged providers
final bridgedOnboardingPhaseProvider = Provider<OnboardingPhase>((ref) {
  final seenIntro = ref.watch(bridgedHasSeenIntroProvider);
  final completedProfile = ref.watch(bridgedHasCompletedProfileProvider);
  final isLoggedIn = ref.watch(bridgedIsLoggedInProvider);
  final onboardingStatus = ref.watch(onboardingStatusProvider);

  // If user has previously completed onboarding (returning user)
  final hasCompletedOnboarding = onboardingStatus.maybeWhen(
    data: (completed) => completed,
    orElse: () => false,
  );

  if (isLoggedIn && hasCompletedOnboarding) {
    return OnboardingPhase.done;
  }

  // For new users or incomplete onboarding, follow the flow
  if (!seenIntro) return OnboardingPhase.intro;
  if (!completedProfile) return OnboardingPhase.profileSetup;
  return OnboardingPhase.done;
});

/// State notifier that manages the bridge between services and providers
final providerBridgeStateProvider = StateNotifierProvider<ProviderBridgeNotifier, ProviderBridgeState>((ref) {
  return ProviderBridgeNotifier(ref);
});

class ProviderBridgeState {
  final bool isInitialized;
  final String? error;

  const ProviderBridgeState({
    this.isInitialized = false,
    this.error,
  });

  ProviderBridgeState copyWith({
    bool? isInitialized,
    String? error,
  }) {
    return ProviderBridgeState(
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
    );
  }
}

class ProviderBridgeNotifier extends StateNotifier<ProviderBridgeState> {
  final Ref ref;

  ProviderBridgeNotifier(this.ref) : super(const ProviderBridgeState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize the bridge by checking existing service states
      final authService = ref.read(authServiceProvider);
      final onboardingService = ref.read(onboardingSettingsServiceProvider);

      // Check if user is already logged in
      final isLoggedIn = await authService.isLoggedIn();
      if (isLoggedIn) {
        ref.read(isLoggedInSyncProvider.notifier).state = true;

        // Check if they've completed onboarding
        final hasCompletedOnboarding = await onboardingService.hasCompletedOnboarding();
        if (hasCompletedOnboarding) {
          ref.read(hasSeenIntroProvider.notifier).state = true;
          ref.read(hasCompletedProfileProvider.notifier).state = true;
        }
      }

      state = state.copyWith(isInitialized: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Call this when user completes profile setup to persist the state
  Future<void> completeOnboarding() async {
    try {
      final onboardingService = ref.read(onboardingSettingsServiceProvider);
      await onboardingService.setHasCompletedOnboarding(true);

      // Update provider states
      ref.read(hasSeenIntroProvider.notifier).state = true;
      ref.read(hasCompletedProfileProvider.notifier).state = true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Call this when user logs out to clear all states
  Future<void> clearAllStates() async {
    ref.read(isLoggedInSyncProvider.notifier).state = false;
    ref.read(hasSeenIntroProvider.notifier).state = false;
    ref.read(hasCompletedProfileProvider.notifier).state = false;
  }
}
