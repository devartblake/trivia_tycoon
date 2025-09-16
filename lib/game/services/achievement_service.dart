import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../core/services/api_service.dart';
import '../../game/models/achievement.dart';

class AchievementService {
  final ApiService apiService;

  // Enhanced storage and caching
  static const _achievementBoxName = 'achievement_data';
  static const _lastSyncKey = 'last_achievement_sync';
  static const _achievementStatsKey = 'achievement_stats';

  // Cache for performance
  List<Achievement>? _cachedAchievements;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 10);

  AchievementService({required this.apiService});

  /// Initialize achievement service storage
  Future<void> initialize() async {
    try {
      await Hive.openBox(_achievementBoxName);
      debugPrint('AchievementService initialized');
    } catch (e) {
      debugPrint('Failed to initialize AchievementService: $e');
    }
  }

  Future<List<Achievement>> fetchAchievements(String playerName) async {
    final List<Map<String, dynamic>> response = await apiService.fetchAchievements(playerName);
    final achievements = response.map((data) => Achievement.fromJson(data)).toList();

    // Update cache
    _cachedAchievements = achievements;
    _lastCacheUpdate = DateTime.now();

    return achievements;
  }

  /// Saves a list of unlocked achievements (original method with List<Achievement> parameter)
  Future<void> saveAchievements(List<Achievement> achievements) async {
    try {
      // Save using your original AppSettings method
      final achievementData = achievements.map((a) => a.toJson()).toList();
      await AppSettings.saveUnlockedAchievements(achievementData.cast<String>());

      // Enhanced: Also save to Hive for better data integrity
      final box = await Hive.openBox(_achievementBoxName);
      await box.put('unlocked_achievements', achievementData);
      await box.put('last_save', DateTime.now().toIso8601String());

      // Update cache
      _cachedAchievements = achievements;
      _lastCacheUpdate = DateTime.now();

      debugPrint('Achievements saved: ${achievements.length} items');
    } catch (e) {
      debugPrint('Failed to save achievements: $e');
      rethrow;
    }
  }

  /// Retrieves the list of unlocked achievements.
  Future<List<Achievement>> getUnlockedAchievements() async {
    // Return cached if valid
    if (_isCacheValid() && _cachedAchievements != null) {
      return List<Achievement>.from(_cachedAchievements!);
    }

    try {
      // Try enhanced storage first
      final box = await Hive.openBox(_achievementBoxName);
      final enhancedData = box.get('unlocked_achievements');

      if (enhancedData != null) {
        final achievements = (enhancedData as List)
            .map<Achievement>((data) => Achievement.fromJson(Map<String, dynamic>.from(data)))
            .toList();

        _cachedAchievements = achievements;
        _lastCacheUpdate = DateTime.now();
        return achievements;
      }

      // Fallback to your original AppSettings method
      final storedData = await AppSettings.getUnlockedAchievements();
      final achievements = storedData.map<Achievement>((data) => Achievement.fromJson(data as Map<String, dynamic>)).toList();

      _cachedAchievements = achievements;
      _lastCacheUpdate = DateTime.now();
      return achievements;
    } catch (e) {
      debugPrint('Failed to get unlocked achievements: $e');
      return [];
    }
  }

  /// Unlocks a new achievement and saves it locally and remotely.
  Future<void> unlockAchievement(Achievement achievement, String playerName) async {
    try {
      final unlockedAchievements = await getUnlockedAchievements();

      if (!unlockedAchievements.any((a) => a.id == achievement.id)) {
        final updatedAchievement = achievement.unlock();
        unlockedAchievements.add(updatedAchievement);

        await saveAchievements(unlockedAchievements);

        // Track achievement unlock
        await _recordAchievementUnlock(achievement.id, playerName);

        try {
          await apiService.unlockAchievement(playerName, achievement.id);
        } catch (e) {
          debugPrint('Failed to sync achievement unlock to server: $e');
          // Achievement is still saved locally
        }
      }
    } catch (e) {
      debugPrint('Failed to unlock achievement: $e');
      rethrow;
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
      await _updateLastSync();

      debugPrint('Achievements synced successfully');
    } catch (e) {
      debugPrint('Error syncing achievements: $e');
      if (kDebugMode) {
        debugPrint('Error syncing achievements: $e');
      }
    }
  }

  /// LIFECYCLE METHOD: Saves achievement data when app backgrounded (no parameters)
  /// Called by AppLifecycleObserver when app goes to background
  Future<void> saveAchievementData() async {
    try {
      final box = await Hive.openBox(_achievementBoxName);

      // Force flush all achievement data to disk
      await box.flush();

      // Create snapshot for recovery
      final achievements = await getUnlockedAchievements();
      final stats = await getAchievementStats();

      final snapshot = {
        'achievements': achievements.map((a) => a.toJson()).toList(),
        'stats': stats,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await box.put('achievement_snapshot', snapshot);

      debugPrint('Achievement data saved successfully');
    } catch (e) {
      debugPrint('Failed to save achievement data: $e');
      rethrow;
    }
  }

  /// LIFECYCLE METHOD: Checks for new achievements when app resumes
  /// Called by AppLifecycleObserver when app resumes from background
  Future<void> checkForNewAchievements() async {
    try {
      // Validate data integrity first
      await _validateAchievementIntegrity();

      // Check if sync is needed
      if (await _needsSync()) {
        debugPrint('Achievement sync needed (will require playerName in actual implementation)');
        // Note: In real implementation, you'd need to get playerName from user service
        // await syncAchievements(playerName);
      }

      // Update cache timestamp
      _lastCacheUpdate = DateTime.now();

      debugPrint('Achievement check completed');
    } catch (e) {
      debugPrint('Achievement check failed: $e');
    }
  }

  /// Records achievement unlock for statistics
  Future<void> _recordAchievementUnlock(String achievementId, String playerName) async {
    try {
      final box = await Hive.openBox(_achievementBoxName);
      final stats = Map<String, dynamic>.from(box.get(_achievementStatsKey, defaultValue: {}));

      stats[achievementId] = {
        'unlocked_at': DateTime.now().toIso8601String(),
        'player_name': playerName,
      };

      await box.put(_achievementStatsKey, stats);
    } catch (e) {
      debugPrint('Failed to record achievement unlock: $e');
    }
  }

  /// Get achievement statistics
  Future<Map<String, dynamic>> getAchievementStats() async {
    try {
      final box = await Hive.openBox(_achievementBoxName);
      return Map<String, dynamic>.from(box.get(_achievementStatsKey, defaultValue: {}));
    } catch (e) {
      return {};
    }
  }

  /// Validate achievement data integrity
  Future<void> _validateAchievementIntegrity() async {
    try {
      final box = await Hive.openBox(_achievementBoxName);
      bool needsRepair = false;

      // Check achievements data
      final achievementsData = box.get('unlocked_achievements');
      if (achievementsData != null && achievementsData is! List) {
        await box.delete('unlocked_achievements');
        needsRepair = true;
      }

      // Check stats data
      final stats = box.get(_achievementStatsKey);
      if (stats != null && stats is! Map) {
        await box.put(_achievementStatsKey, {});
        needsRepair = true;
      }

      if (needsRepair) {
        debugPrint('Achievement data integrity restored');
      }
    } catch (e) {
      debugPrint('Achievement integrity validation failed: $e');
      await _resetAchievementData();
    }
  }

  /// Reset achievement data if corrupted
  Future<void> _resetAchievementData() async {
    try {
      final box = await Hive.openBox(_achievementBoxName);
      await box.clear();
      _invalidateCache();
      debugPrint('Achievement data reset to defaults');
    } catch (e) {
      debugPrint('Failed to reset achievement data: $e');
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSync() async {
    try {
      final box = await Hive.openBox(_achievementBoxName);
      await box.put(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Failed to update last sync: $e');
    }
  }

  /// Check if sync is needed
  Future<bool> _needsSync() async {
    try {
      final box = await Hive.openBox(_achievementBoxName);
      final lastSyncStr = box.get(_lastSyncKey);

      if (lastSyncStr == null) return true;

      final lastSync = DateTime.parse(lastSyncStr);
      final timeSinceSync = DateTime.now().difference(lastSync);

      return timeSinceSync > const Duration(hours: 1);
    } catch (e) {
      return true; // Default to sync needed
    }
  }

  /// Cache management helpers
  bool _isCacheValid() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }

  void _invalidateCache() {
    _cachedAchievements = null;
    _lastCacheUpdate = null;
  }

  /// Clear all achievement data
  Future<void> clearAllAchievementData() async {
    final box = await Hive.openBox(_achievementBoxName);
    await box.clear();
    _invalidateCache();
    debugPrint('All achievement data cleared');
  }
}
