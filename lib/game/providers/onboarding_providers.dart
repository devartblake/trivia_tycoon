import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for tracking if user has seen the intro carousel
/// TODO: Replace StateProvider with your persisted service when ready
/// Example: ref.read(onboardingSettingsServiceProvider).hasSeenIntro()
final hasSeenIntroProvider = StateProvider<bool>((ref) => false);

/// Provider for tracking if user has completed profile setup
/// TODO: Replace StateProvider with your persisted service when ready
/// Example: ref.read(onboardingSettingsServiceProvider).hasCompletedProfile()
final hasCompletedProfileProvider = StateProvider<bool>((ref) => false);

/// Enum for different onboarding phases
enum OnboardingPhase {
  intro,        // User needs to see intro carousel
  profileSetup, // User needs to complete profile setup
  done          // User has completed all onboarding
}

/// Provider that determines current onboarding phase based on completion flags
final onboardingPhaseProvider = Provider<OnboardingPhase>((ref) {
  final seenIntro = ref.watch(hasSeenIntroProvider);
  final completedProfile = ref.watch(hasCompletedProfileProvider);

  if (!seenIntro) return OnboardingPhase.intro;
  if (!completedProfile) return OnboardingPhase.profileSetup;
  return OnboardingPhase.done;
});

/// Provider for onboarding state management
final onboardingStateProvider = StateNotifierProvider<OnboardingStateNotifier, OnboardingState>((ref) {
  return OnboardingStateNotifier();
});

/// Onboarding state model
class OnboardingState {
  final bool hasSeenIntro;
  final bool hasCompletedProfile;
  final String? selectedAvatar;
  final String? username;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.hasSeenIntro = false,
    this.hasCompletedProfile = false,
    this.selectedAvatar,
    this.username,
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    bool? hasSeenIntro,
    bool? hasCompletedProfile,
    String? selectedAvatar,
    String? username,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      hasSeenIntro: hasSeenIntro ?? this.hasSeenIntro,
      hasCompletedProfile: hasCompletedProfile ?? this.hasCompletedProfile,
      selectedAvatar: selectedAvatar ?? this.selectedAvatar,
      username: username ?? this.username,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  OnboardingPhase get phase {
    if (!hasSeenIntro) return OnboardingPhase.intro;
    if (!hasCompletedProfile) return OnboardingPhase.profileSetup;
    return OnboardingPhase.done;
  }
}

/// Onboarding state notifier for managing onboarding flow
class OnboardingStateNotifier extends StateNotifier<OnboardingState> {
  OnboardingStateNotifier() : super(const OnboardingState());

  void completeIntro() {
    state = state.copyWith(hasSeenIntro: true);
  }

  void setUsername(String username) {
    state = state.copyWith(username: username);
  }

  void setAvatar(String avatarId) {
    state = state.copyWith(selectedAvatar: avatarId);
  }

  Future<void> completeProfileSetup() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Save profile data to your services
      // await ref.read(profileService).saveProfile(state.username, state.selectedAvatar);

      state = state.copyWith(
        hasCompletedProfile: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void resetOnboarding() {
    state = const OnboardingState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
