import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../core/services/api_service.dart';
import '../../game/models/achievement.dart';

class AchievementService {
  final ApiService apiService;

  AchievementService({required this.apiService});

  Future<List<Achievement>> fetchAchievements(String playerName) async {
    final List<Map<String, dynamic>> response = await apiService.fetchAchievements(playerName);
    return response.map((data) => Achievement.fromJson(data)).toList();
  }

  /// Saves a list of unlocked achievements.
  Future<void> saveAchievements(List<Achievement> achievements) async {
    final achievementData = achievements.map((a) => a.toJson()).toList();
    await AppSettings.saveUnlockedAchievements(achievementData.cast<String>());
  }

  /// Retrieves the list of unlocked achievements.
  Future<List<Achievement>> getUnlockedAchievements() async {
    final storedData = await AppSettings.getUnlockedAchievements();
    return storedData.map<Achievement>((data) => Achievement.fromJson(data as Map<String, dynamic>)).toList();
  }

  /// Unlocks a new achievement and saves it locally and remotely.
  Future<void> unlockAchievement(Achievement achievement, String playerName) async {
    final unlockedAchievements = await getUnlockedAchievements();

    if (!unlockedAchievements.any((a) => a.id == achievement.id)) {
      final updatedAchievement = achievement.unlock();
      unlockedAchievements.add(updatedAchievement);

      await saveAchievements(unlockedAchievements);
      await apiService.unlockAchievement(playerName, achievement.id);
    }
  }

  /// Checks if an achievement is unlocked.
  Future<bool> isAchievementUnlocked(String achievementId) async {
    final unlockedAchievements = await getUnlockedAchievements();
    return unlockedAchievements.any((a) => a.id == achievementId);
  }

  /// Syncs achievements with the API.
  Future<void> syncAchievements(String playerName) async {
    try {
      final List<Map<String, dynamic>> achievementsData = await apiService.fetchAchievements(playerName);
      final List<Achievement> achievements = achievementsData.map(Achievement.fromJson).toList();

      await saveAchievements(achievements);
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing achievements: $e');
      }
    }
  }
}
