import 'package:hive/hive.dart';

/// A singleton service to manage feature flags and configuration.
/// Backed by Hive for persistence.
class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;

  AppConfigService._internal();

  static const String _boxName = 'app_config';

  late Box _box;

  /// Call this during app startup
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Generic setter
  Future<void> setBool(String key, bool value) async {
    await _box.put(key, value);
  }

  /// Generic getter
  bool getBool(String key, {bool defaultValue = false}) {
    return _box.get(key, defaultValue: defaultValue);
  }

  /// Example usage: Check if onboarding is enabled
  bool get enableOnboarding => getBool('enable_onboarding', defaultValue: true);

  /// Example usage: Toggle onboarding for dev testing
  Future<void> toggleOnboarding(bool isEnabled) async {
    await setBool('enable_onboarding', isEnabled);
  }

  /// Example: Load simulated remote config (can be replaced with real one)
  Future<void> loadMockRemoteConfig() async {
    await _box.putAll({
      'enable_onboarding': true,
      'enable_confetti': false,
      'force_dark_theme': false,
    });
  }

  /// Clear all dev overrides (for testing)
  Future<void> resetAll() async {
    await _box.clear();
  }
}
