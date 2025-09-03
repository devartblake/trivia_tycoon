import 'package:flutter/foundation.dart';
import '../../game/models/achievement.dart';
import '../../core/services/api_service.dart';
import '../../game/services/achievement_service.dart';

class AchievementController extends ChangeNotifier {
  final AchievementService _achievementService;

  AchievementController({required ApiService apiService})
      : _achievementService = AchievementService(apiService: apiService);

  List<Achievement> _achievements = [];

  List<Achievement> get achievements => _achievements;

  /// Loads achievements from the API and updates the state.
  Future<void> loadAchievements(String playerName) async {
    _achievements = await _achievementService.fetchAchievements(playerName);
    notifyListeners();
  }

  /// Unlocks an achievement if not already unlocked.
  Future<void> unlockAchievement(String id, String playerName) async {
    final index = _achievements.indexWhere((ach) => ach.id == id);

    if (index != -1 && !_achievements[index].isUnlocked) {
      _achievements[index] = _achievements[index].unlock();

      await _achievementService.unlockAchievement(_achievements[index], playerName);
      notifyListeners();
    }
  }
}
