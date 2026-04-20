import 'package:hive/hive.dart';

class OnboardingProgress {
  final bool completed;
  final bool hasSeenIntro;
  final bool hasCompletedProfile;
  final int currentStep;
  final String? username;
  final String? ageGroup;
  final String? country;
  final List<String> categories;
  final String? intent;
  final String? playStyle;
  final String? synaptixMode;
  final bool hasCompletedFirstChallenge;
  final bool hasSeenRewardReveal;
  final DateTime? lastUpdatedAt;

  const OnboardingProgress({
    this.completed = false,
    this.hasSeenIntro = false,
    this.hasCompletedProfile = false,
    this.currentStep = 0,
    this.username,
    this.ageGroup,
    this.country,
    this.categories = const <String>[],
    this.intent,
    this.playStyle,
    this.synaptixMode,
    this.hasCompletedFirstChallenge = false,
    this.hasSeenRewardReveal = false,
    this.lastUpdatedAt,
  });

  OnboardingProgress copyWith({
    bool? completed,
    bool? hasSeenIntro,
    bool? hasCompletedProfile,
    int? currentStep,
    String? username,
    String? ageGroup,
    String? country,
    List<String>? categories,
    String? intent,
    String? playStyle,
    String? synaptixMode,
    bool? hasCompletedFirstChallenge,
    bool? hasSeenRewardReveal,
    DateTime? lastUpdatedAt,
  }) {
    return OnboardingProgress(
      completed: completed ?? this.completed,
      hasSeenIntro: hasSeenIntro ?? this.hasSeenIntro,
      hasCompletedProfile: hasCompletedProfile ?? this.hasCompletedProfile,
      currentStep: currentStep ?? this.currentStep,
      username: username ?? this.username,
      ageGroup: ageGroup ?? this.ageGroup,
      country: country ?? this.country,
      categories: categories ?? this.categories,
      intent: intent ?? this.intent,
      playStyle: playStyle ?? this.playStyle,
      synaptixMode: synaptixMode ?? this.synaptixMode,
      hasCompletedFirstChallenge:
          hasCompletedFirstChallenge ?? this.hasCompletedFirstChallenge,
      hasSeenRewardReveal: hasSeenRewardReveal ?? this.hasSeenRewardReveal,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'has_seen_intro': hasSeenIntro,
      'has_completed_profile': hasCompletedProfile,
      'current_step': currentStep,
      'username': username,
      'age_group': ageGroup,
      'country': country,
      'categories': categories,
      'intent': intent,
      'play_style': playStyle,
      'synaptix_mode': synaptixMode,
      'has_completed_first_challenge': hasCompletedFirstChallenge,
      'has_seen_reward_reveal': hasSeenRewardReveal,
      'last_updated_at': lastUpdatedAt?.toIso8601String(),
    };
  }

  factory OnboardingProgress.fromMap(Map<dynamic, dynamic> map) {
    return OnboardingProgress(
      completed: map['completed'] as bool? ?? false,
      hasSeenIntro: map['has_seen_intro'] as bool? ?? false,
      hasCompletedProfile: map['has_completed_profile'] as bool? ?? false,
      currentStep: map['current_step'] as int? ?? 0,
      username: map['username'] as String?,
      ageGroup: map['age_group'] as String?,
      country: map['country'] as String?,
      categories: List<String>.from(map['categories'] ?? const <String>[]),
      intent: map['intent'] as String?,
      playStyle: map['play_style'] as String?,
      synaptixMode: map['synaptix_mode'] as String?,
      hasCompletedFirstChallenge:
          map['has_completed_first_challenge'] as bool? ?? false,
      hasSeenRewardReveal: map['has_seen_reward_reveal'] as bool? ?? false,
      lastUpdatedAt: map['last_updated_at'] != null
          ? DateTime.tryParse(map['last_updated_at'] as String)
          : null,
    );
  }
}

/// Manages onboarding flow state and persisted progress.
class OnboardingSettingsService {
  static const _boxName = 'settings';
  static const _completedKey = 'onboarding_completed';
  static const _legacyCompletedKey = 'onboarding_complete';
  static const _progressKey = 'onboarding_progress';

  Future<Box> _openBox() async => Hive.openBox(_boxName);

  Future<void> _migrateLegacyCompletionKey(Box box) async {
    final legacyValue = box.get(_legacyCompletedKey);
    if (legacyValue is bool) {
      if (legacyValue) {
        await box.put(_completedKey, true);
      } else if (!box.containsKey(_completedKey)) {
        await box.put(_completedKey, false);
      }
      await box.delete(_legacyCompletedKey);
    }
  }

  Future<OnboardingProgress> getOnboardingProgress() async {
    final box = await _openBox();
    await _migrateLegacyCompletionKey(box);

    final rawProgress = box.get(_progressKey);
    final completed = box.get(_completedKey, defaultValue: false) as bool;

    if (rawProgress is Map) {
      final progress = OnboardingProgress.fromMap(rawProgress)
          .copyWith(completed: completed, lastUpdatedAt: DateTime.now());
      await box.put(_progressKey, progress.toMap());
      return progress;
    }

    final migrated = OnboardingProgress(
      completed: completed,
      hasSeenIntro: completed,
      hasCompletedProfile: completed,
      currentStep: completed ? 10 : 0,
      lastUpdatedAt: DateTime.now(),
    );
    await box.put(_progressKey, migrated.toMap());
    return migrated;
  }

  Future<void> saveOnboardingProgress(OnboardingProgress progress) async {
    final box = await _openBox();
    await _migrateLegacyCompletionKey(box);

    final normalized = progress.copyWith(lastUpdatedAt: DateTime.now());
    await box.put(_progressKey, normalized.toMap());
    await box.put(_completedKey, normalized.completed);
  }

  Future<void> updateOnboardingProgress({
    bool? completed,
    bool? hasSeenIntro,
    bool? hasCompletedProfile,
    int? currentStep,
    String? username,
    String? ageGroup,
    String? country,
    List<String>? categories,
    String? intent,
    String? playStyle,
    String? synaptixMode,
    bool? hasCompletedFirstChallenge,
    bool? hasSeenRewardReveal,
  }) async {
    final current = await getOnboardingProgress();
    await saveOnboardingProgress(
      current.copyWith(
        completed: completed,
        hasSeenIntro: hasSeenIntro,
        hasCompletedProfile: hasCompletedProfile,
        currentStep: currentStep,
        username: username,
        ageGroup: ageGroup,
        country: country,
        categories: categories,
        intent: intent,
        playStyle: playStyle,
        synaptixMode: synaptixMode,
        hasCompletedFirstChallenge: hasCompletedFirstChallenge,
        hasSeenRewardReveal: hasSeenRewardReveal,
      ),
    );
  }

  /// Saves onboarding completed flag (legacy method)
  Future<void> setHasCompletedOnboarding(bool value) async {
    final current = await getOnboardingProgress();
    await saveOnboardingProgress(
      current.copyWith(
        completed: value,
        hasSeenIntro: value ? true : current.hasSeenIntro,
        hasCompletedProfile: value ? true : current.hasCompletedProfile,
        currentStep: value ? 10 : current.currentStep,
      ),
    );
  }

  /// Retrieves onboarding completed flag
  Future<bool> hasCompletedOnboarding() async {
    final progress = await getOnboardingProgress();
    return progress.completed;
  }

  /// Alias for setting onboarding completed
  Future<void> setOnboardingCompleted(bool value) async =>
      setHasCompletedOnboarding(value);

  /// Gets onboarding completed state
  Future<bool> getOnboardingStatus() async => hasCompletedOnboarding();

  Future<void> resetOnboardingProgress() async {
    await saveOnboardingProgress(const OnboardingProgress());
  }
}
