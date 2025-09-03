import 'package:hive/hive.dart';

/// A service for managing achievement-related settings.
class AchievementSettingsService {
  static const _boxName = 'settings';
  static const _unlockedBadgesKey = 'badges';

  /// Retrieves a list of unlocked badge identifiers.
  Future<List<String>> getUnlockedBadges() async {
    final box = await Hive.openBox(_boxName);
    return List<String>.from(box.get(_unlockedBadgesKey, defaultValue: []));
  }

  /// Unlocks a badge and stores it if not already present.
  Future<void> unlockBadge(String badge) async {
    final box = await Hive.openBox(_boxName);
    List<String> current = List<String>.from(box.get(_unlockedBadgesKey, defaultValue: []));
    if (!current.contains(badge)) {
      current.add(badge);
      await box.put(_unlockedBadgesKey, current);
    }
  }
}
