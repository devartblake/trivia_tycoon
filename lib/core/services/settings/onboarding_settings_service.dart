import 'package:hive/hive.dart';

/// Manages onboarding flow state such as completion flags
class OnboardingSettingsService {
  static const _boxName = 'settings';
  static const _key = 'onboarding_completed';

  /// Saves onboarding completed flag (legacy method)
  Future<void> setHasCompletedOnboarding(bool value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_key, value);
  }

  /// Retrieves onboarding completed flag
  Future<bool> hasCompletedOnboarding() async {
    final box = await Hive.openBox(_boxName);
    return box.get(_key, defaultValue: false);
  }

  /// Alias for setting onboarding completed
  Future<void> setOnboardingCompleted() async =>
      await setHasCompletedOnboarding(true);

  /// Gets onboarding completed state
  Future<bool> getOnboardingStatus() async => await hasCompletedOnboarding();
}
