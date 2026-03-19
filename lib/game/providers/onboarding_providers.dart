import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/settings/onboarding_settings_service.dart';
import 'riverpod_providers.dart';

final onboardingProgressProvider =
StateNotifierProvider<OnboardingProgressNotifier, OnboardingProgressState>((
    ref,
    ) {
  return OnboardingProgressNotifier(ref);
});

/// Provider for tracking if user has seen the intro carousel.
/// Backed by persisted onboarding progress.
final hasSeenIntroProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProgressProvider).progress.hasSeenIntro;
});

/// Provider for tracking if user has completed profile setup.
/// Backed by persisted onboarding progress.
final hasCompletedProfileProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProgressProvider).progress.hasCompletedProfile;
});

/// Single-flag provider: true once the user has finished all onboarding steps.
final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProgressProvider).progress.completed;
});

/// Enum for different onboarding phases
enum OnboardingPhase {
  intro,        // User needs to see intro carousel
  profileSetup, // User needs to complete profile setup
  done          // User has completed all onboarding
}

/// Provider that determines current onboarding phase based on completion flags
final onboardingPhaseProvider = Provider<OnboardingPhase>((ref) {
  final progress = ref.watch(onboardingProgressProvider).progress;

  if (!progress.hasSeenIntro) return OnboardingPhase.intro;
  if (!progress.hasCompletedProfile) return OnboardingPhase.profileSetup;
  return OnboardingPhase.done;
});

/// Provider for onboarding state management
final onboardingStateProvider =
StateNotifierProvider<OnboardingStateNotifier, OnboardingState>((ref) {
  return OnboardingStateNotifier(ref);
});

class OnboardingProgressState {
  final OnboardingProgress progress;
  final bool isLoading;
  final String? error;

  const OnboardingProgressState({
    this.progress = const OnboardingProgress(),
    this.isLoading = true,
    this.error,
  });

  OnboardingProgressState copyWith({
    OnboardingProgress? progress,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingProgressState(
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OnboardingProgressNotifier extends StateNotifier<OnboardingProgressState> {
  final Ref ref;

  OnboardingProgressNotifier(this.ref) : super(const OnboardingProgressState()) {
    load();
  }

  OnboardingSettingsService get _service => ref.read(onboardingSettingsServiceProvider);

  Future<void> load() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final progress = await _service.getOnboardingProgress();
      state = state.copyWith(progress: progress, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateProgress({
    bool? completed,
    bool? hasSeenIntro,
    bool? hasCompletedProfile,
    int? currentStep,
    String? username,
    String? ageGroup,
    String? country,
    List<String>? categories,
  }) async {
    try {
      await _service.updateOnboardingProgress(
        completed: completed,
        hasSeenIntro: hasSeenIntro,
        hasCompletedProfile: hasCompletedProfile,
        currentStep: currentStep,
        username: username,
        ageGroup: ageGroup,
        country: country,
        categories: categories,
      );
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markIntroSeen([bool value = true]) async {
    await updateProgress(hasSeenIntro: value);
  }

  Future<void> markProfileCompleted([bool value = true]) async {
    await updateProgress(hasCompletedProfile: value);
  }

  Future<void> markOnboardingCompleted([bool value = true]) async {
    await updateProgress(
      completed: value,
      hasSeenIntro: value ? true : state.progress.hasSeenIntro,
      hasCompletedProfile: value ? true : state.progress.hasCompletedProfile,
    );
  }

  Future<void> reset() async {
    await _service.resetOnboardingProgress();
    await load();
  }
}

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
  final Ref ref;

  OnboardingStateNotifier(this.ref) : super(const OnboardingState()) {
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    await ref.read(onboardingProgressProvider.notifier).load();
    final persisted = ref.read(onboardingProgressProvider).progress;
    state = state.copyWith(
      hasSeenIntro: persisted.hasSeenIntro,
      hasCompletedProfile: persisted.hasCompletedProfile,
      username: persisted.username,
    );
  }

  Future<void> completeIntro() async {
    state = state.copyWith(hasSeenIntro: true);
    await ref.read(onboardingProgressProvider.notifier).markIntroSeen(true);
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
      await ref.read(onboardingProgressProvider.notifier).updateProgress(
        hasCompletedProfile: true,
        username: state.username,
      );

      state = state.copyWith(hasCompletedProfile: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> resetOnboarding() async {
    await ref.read(onboardingProgressProvider.notifier).reset();
    state = const OnboardingState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
