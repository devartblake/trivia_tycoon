import 'package:hive/hive.dart';

/// Service to manage quiz session data, onboarding flags, and player metadata.
class QuizProgressService {
  static const String _settingsBox = 'settings';
  static const String _quizProgressKey = 'quizProgress';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _playerNameKey = 'playerName';
  static const String _playerProgressKey = 'playerProgress';

  late final Box _box;

  QuizProgressService._(this._box);

  /// Factory initializer for use in ServiceManager
  static Future<QuizProgressService> initialize() async {
    final box = await Hive.openBox(_settingsBox);
    return QuizProgressService._(box);
  }

  /// Saves progress data of an ongoing quiz session.
  Future<void> saveQuizProgress(Map<String, dynamic> progress) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(_quizProgressKey, progress);
  }

  /// Retrieves the stored quiz progress data.
  Future<Map<String, dynamic>> getQuizProgress() async {
    final box = await Hive.openBox(_settingsBox);
    return Map<String, dynamic>.from(box.get(_quizProgressKey, defaultValue: {}));
  }

  /// Marks the onboarding screen as completed.
  Future<void> setOnboardingCompleted() async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(_onboardingCompleteKey, true);
  }

  /// Returns whether onboarding is completed.
  Future<bool> getOnboardingStatus() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get(_onboardingCompleteKey, defaultValue: false);
  }

  /// Saves the player's display name.
  Future<void> savePlayerName(String name) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(_playerNameKey, name);
  }

  /// Returns the saved player name or default.
  Future<String> getPlayerName() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get(_playerNameKey, defaultValue: 'Player');
  }

  /// Saves score and streak progress.
  Future<void> savePlayerProgress(Map<String, dynamic> progress) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(_playerProgressKey, progress);
  }

  /// Loads score and streak progress.
  Future<Map<String, dynamic>> getPlayerProgress() async {
    final box = await Hive.openBox(_settingsBox);
    return Map<String, dynamic>.from(box.get(_playerProgressKey, defaultValue: {}));
  }
}
