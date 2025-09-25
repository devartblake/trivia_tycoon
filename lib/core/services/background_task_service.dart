import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';

/// Background task service to handle mission reminders and notifications
class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  static const String _backgroundTasksBox = 'background_tasks';
  static const String _lastCheckKey = 'last_mission_check';
  static const String _userIdKey = 'current_user_id';
  static const String _dailyReminderKey = 'daily_reminder_scheduled';
  static const String _lastActivityKey = 'last_game_activity';
  static const String _lastInactivityReminderKey = 'last_inactivity_reminder';

  Timer? _periodicTimer;
  Timer? _dailyTimer;
  final NotificationService _notificationService = NotificationService();
  String? _currentUserId;
  Box? _backgroundBox;

  /// Initialize background tasks
  Future<void> initialize(String userId) async {
    try {
      // Ensure notification service is initialized
      await _notificationService.initialize();

      // Open or get the background tasks box
      _backgroundBox = await _getBackgroundBox();

      _currentUserId = userId;
      await _saveUserId(userId);

      // Start periodic tasks
      _startPeriodicTasks();
      _scheduleDailyReminders();

      debugPrint('[BackgroundTaskService] Initialized for user: $userId');
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to initialize: $e');
    }
  }

  /// Stop all background tasks
  void dispose() {
    _periodicTimer?.cancel();
    _dailyTimer?.cancel();
    debugPrint('[BackgroundTaskService] Disposed');
  }

  /// Get or open the background tasks box
  Future<Box> _getBackgroundBox() async {
    if (_backgroundBox != null && _backgroundBox!.isOpen) {
      return _backgroundBox!;
    }

    try {
      if (Hive.isBoxOpen(_backgroundTasksBox)) {
        _backgroundBox = Hive.box(_backgroundTasksBox);
      } else {
        _backgroundBox = await Hive.openBox(_backgroundTasksBox);
      }
      return _backgroundBox!;
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to open box: $e');
      // Try to delete and recreate the box if corrupted
      try {
        await Hive.deleteBoxFromDisk(_backgroundTasksBox);
        _backgroundBox = await Hive.openBox(_backgroundTasksBox);
        return _backgroundBox!;
      } catch (e2) {
        debugPrint('[BackgroundTaskService] Failed to recreate box: $e2');
        rethrow;
      }
    }
  }

  /// Start periodic mission checks (every 30 minutes)
  void _startPeriodicTasks() {
    _periodicTimer?.cancel();

    _periodicTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _performBackgroundCheck();
    });

    // Perform initial check
    _performBackgroundCheck();
  }

  /// Schedule daily reminders
  void _scheduleDailyReminders() {
    _dailyTimer?.cancel();

    // Calculate time until next 9 AM
    final now = DateTime.now();
    var nextReminderTime = DateTime(now.year, now.month, now.day, 9, 0);

    if (now.isAfter(nextReminderTime)) {
      nextReminderTime = nextReminderTime.add(const Duration(days: 1));
    }

    final timeUntilReminder = nextReminderTime.difference(now);

    _dailyTimer = Timer(timeUntilReminder, () {
      _sendDailyReminder();
      // Schedule the next reminder
      _scheduleDailyReminders();
    });

    debugPrint('[BackgroundTaskService] Next daily reminder at: $nextReminderTime');
  }

  /// Perform background mission checks
  Future<void> _performBackgroundCheck() async {
    if (_currentUserId == null) return;

    try {
      final box = await _getBackgroundBox();
      final lastCheck = box.get(_lastCheckKey, defaultValue: 0) as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Only check if more than 15 minutes have passed
      if (now - lastCheck < (15 * 60 * 1000)) return;

      await _checkExpiringSoonMissions();
      await _checkInactiveMissions();

      await box.put(_lastCheckKey, now);

      debugPrint('[BackgroundTaskService] Background check completed');
    } catch (e) {
      debugPrint('[BackgroundTaskService] Background check failed: $e');
    }
  }

  /// Check for missions expiring soon
  Future<void> _checkExpiringSoonMissions() async {
    if (_currentUserId == null) return;

    try {
      // In a real implementation, you would:
      // 1. Fetch user missions from your service/repository
      // 2. Filter for missions expiring in next 2 hours
      // 3. Send notifications for those missions

      // For demonstration, simulating mission check
      final hasExpiringSoon = await _hasExpiringSoonMissions();

      if (hasExpiringSoon) {
        await _notificationService.showBasicNotification(
          title: 'Missions Expiring Soon!',
          body: 'Some of your missions expire in less than 2 hours. Complete them now!',
          payload: {
            'type': 'expiring_soon',
            'user_id': _currentUserId!,
            'screen': 'missions',
          },
        );
      }
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to check expiring missions: $e');
    }
  }

  /// Check for inactive missions (user hasn't played for a while)
  Future<void> _checkInactiveMissions() async {
    if (_currentUserId == null) return;

    try {
      final box = await _getBackgroundBox();
      final lastActivity = box.get(_lastActivityKey, defaultValue: 0) as int;
      final lastInactivityReminder = box.get(_lastInactivityReminderKey, defaultValue: 0) as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // If user hasn't been active for 6+ hours
      final inactiveHours = (now - lastActivity) / (1000 * 60 * 60);
      final hoursSinceLastReminder = (now - lastInactivityReminder) / (1000 * 60 * 60);

      // Only send reminder if inactive for 6+ hours and haven't sent reminder in 12+ hours
      if (inactiveHours >= 6 && hoursSinceLastReminder >= 12) {
        await _notificationService.showBasicNotification(
          title: 'Your missions await!',
          body: 'Complete your daily missions to earn rewards and XP',
          payload: {
            'type': 'inactivity_reminder',
            'user_id': _currentUserId!,
            'hours_inactive': inactiveHours.round().toString(),
            'screen': 'missions',
          },
        );

        // Update last reminder time to avoid spam
        await box.put(_lastInactivityReminderKey, now);
      }
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to check inactive missions: $e');
    }
  }

  /// Send daily reminder at 9 AM
  Future<void> _sendDailyReminder() async {
    if (_currentUserId == null) return;

    try {
      final box = await _getBackgroundBox();
      final today = DateTime.now();
      final todayKey = '${_dailyReminderKey}_${today.year}_${today.month}_${today.day}';

      // Check if we already sent reminder today
      final sentToday = box.get(todayKey, defaultValue: false) as bool;
      if (sentToday) return;

      await _notificationService.showMissionNotification(
        title: 'Good Morning!',
        body: 'New daily missions are available. Start your day with some challenges!',
        payload: {
          'type': 'daily_reminder',
          'user_id': _currentUserId!,
          'screen': 'missions',
        },
      );

      // Mark as sent for today
      await box.put(todayKey, true);

      debugPrint('[BackgroundTaskService] Daily reminder sent');
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to send daily reminder: $e');
    }
  }

  /// Schedule a one-time reminder
  Future<void> scheduleOneTimeReminder({
    required Duration delay,
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    Timer(delay, () async {
      await _notificationService.showBasicNotification(
        title: title,
        body: body,
        payload: {
          'type': 'scheduled_reminder',
          'user_id': _currentUserId ?? 'unknown',
          ...?payload,
        },
      );
    });
  }

  /// Update user activity timestamp
  Future<void> recordUserActivity() async {
    try {
      final box = await _getBackgroundBox();
      await box.put(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to record activity: $e');
    }
  }

  /// Schedule mission completion celebration
  Future<void> scheduleMissionCompletionCelebration({
    required String missionTitle,
    required int reward,
    required String missionId,
  }) async {
    // Send immediate celebration
    await _notificationService.showMissionNotification(
      title: 'Mission Complete!',
      body: '$missionTitle completed! You earned $reward XP!',
      reward: reward,
      payload: {
        'type': 'completion_celebration',
        'mission_id': missionId,
        'user_id': _currentUserId ?? 'unknown',
        'screen': 'missions',
      },
    );

    // Schedule a follow-up reminder after 1 hour
    scheduleOneTimeReminder(
      delay: const Duration(hours: 1),
      title: 'Keep the momentum!',
      body: 'Great job completing that mission! Ready for the next challenge?',
      payload: {
        'type': 'momentum_reminder',
        'screen': 'missions',
      },
    );
  }

  /// Store mission statistics for analytics
  Future<void> storeMissionStatistic({
    required String eventType,
    required Map<String, dynamic> data,
  }) async {
    try {
      final box = await _getBackgroundBox();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final statisticKey = 'mission_stat_${timestamp}_$eventType';

      final statistic = {
        'event_type': eventType,
        'timestamp': timestamp,
        'user_id': _currentUserId,
        'data': data,
      };

      await box.put(statisticKey, statistic);
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to store statistic: $e');
    }
  }

  /// Get mission statistics for analytics
  Future<List<Map<String, dynamic>>> getMissionStatistics({
    String? eventType,
    DateTime? since,
  }) async {
    try {
      final box = await _getBackgroundBox();
      final statistics = <Map<String, dynamic>>[];
      final sinceTimestamp = since?.millisecondsSinceEpoch ?? 0;

      for (final key in box.keys) {
        if (key.toString().startsWith('mission_stat_')) {
          final stat = box.get(key) as Map<String, dynamic>?;
          if (stat != null) {
            final timestamp = stat['timestamp'] as int? ?? 0;
            final type = stat['event_type'] as String? ?? '';

            // Filter by timestamp
            if (timestamp >= sinceTimestamp) {
              // Filter by event type if specified
              if (eventType == null || type == eventType) {
                statistics.add(Map<String, dynamic>.from(stat));
              }
            }
          }
        }
      }

      // Sort by timestamp (newest first)
      statistics.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      return statistics;
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to get statistics: $e');
      return [];
    }
  }

  /// Clear old statistics (keep only last 30 days)
  Future<void> cleanupOldStatistics() async {
    try {
      final box = await _getBackgroundBox();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      final keysToDelete = <String>[];

      for (final key in box.keys) {
        if (key.toString().startsWith('mission_stat_')) {
          final stat = box.get(key) as Map<String, dynamic>?;
          if (stat != null) {
            final timestamp = stat['timestamp'] as int? ?? 0;
            if (timestamp < thirtyDaysAgo) {
              keysToDelete.add(key.toString());
            }
          }
        }
      }

      for (final key in keysToDelete) {
        await box.delete(key);
      }

      debugPrint('[BackgroundTaskService] Cleaned up ${keysToDelete.length} old statistics');
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to cleanup statistics: $e');
    }
  }

  /// Helper methods
  Future<void> _saveUserId(String userId) async {
    try {
      final box = await _getBackgroundBox();
      await box.put(_userIdKey, userId);
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to save user ID: $e');
    }
  }

  Future<String?> _loadUserId() async {
    try {
      final box = await _getBackgroundBox();
      return box.get(_userIdKey) as String?;
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to load user ID: $e');
      return null;
    }
  }

  /// Simulate checking for expiring missions
  /// In real implementation, this would query your mission service
  Future<bool> _hasExpiringSoonMissions() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation, you would:
    // final missions = await missionService.getUserMissions(_currentUserId!);
    // return missions.any((mission) => mission.isExpiringSoon());

    // For demo, randomly return true 20% of the time
    return DateTime.now().millisecond % 5 == 0;
  }

  /// Get current status
  Map<String, dynamic> getStatus() {
    return {
      'isActive': _periodicTimer?.isActive ?? false,
      'currentUserId': _currentUserId,
      'periodicTaskActive': _periodicTimer != null,
      'dailyReminderActive': _dailyTimer != null,
      'boxOpen': _backgroundBox?.isOpen ?? false,
    };
  }

  /// Get detailed analytics
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final box = await _getBackgroundBox();
      final now = DateTime.now();

      // Get activity data
      final lastActivity = box.get(_lastActivityKey, defaultValue: 0) as int;
      final lastCheck = box.get(_lastCheckKey, defaultValue: 0) as int;

      // Get recent statistics
      final recentStats = await getMissionStatistics(
        since: now.subtract(const Duration(days: 7)),
      );

      final completionStats = recentStats.where((s) => s['event_type'] == 'mission_completed').length;
      final swapStats = recentStats.where((s) => s['event_type'] == 'mission_swapped').length;

      return {
        'last_activity': lastActivity > 0
            ? DateTime.fromMillisecondsSinceEpoch(lastActivity).toString()
            : 'Never',
        'last_check': lastCheck > 0
            ? DateTime.fromMillisecondsSinceEpoch(lastCheck).toString()
            : 'Never',
        'missions_completed_week': completionStats,
        'missions_swapped_week': swapStats,
        'total_statistics': recentStats.length,
        'background_tasks_active': _periodicTimer?.isActive ?? false,
        'daily_reminders_active': _dailyTimer?.isActive ?? false,
      };
    } catch (e) {
      debugPrint('[BackgroundTaskService] Failed to get analytics: $e');
      return {'error': e.toString()};
    }
  }
}

/// Extension to integrate with existing mission system
extension BackgroundTaskIntegration on BackgroundTaskService {
  /// Call this when user completes a mission
  Future<void> handleMissionCompletion({
    required String missionId,
    required String missionTitle,
    required int reward,
  }) async {
    await recordUserActivity();

    // Send celebration notification
    await scheduleMissionCompletionCelebration(
      missionTitle: missionTitle,
      reward: reward,
      missionId: missionId,
    );

    // Use the mission notification method
    await _notificationService.showMissionNotification(
      title: 'Mission Complete!',
      body: '$missionTitle completed! You earned $reward XP!',
      reward: reward,
      payload: {
        'type': 'completion_celebration',
        'mission_id': missionId,
        'user_id': _currentUserId ?? 'unknown',
        'screen': 'missions',
      },
    );

    // Schedule follow-up reminder
    Timer(const Duration(hours: 1), () async {
      await _notificationService.showBasicNotification(
        title: 'Keep the momentum!',
        body: 'Great job completing that mission! Ready for the next challenge?',
        payload: {
          'type': 'momentum_reminder',
          'screen': 'missions',
        },
      );
    });

    // Store completion statistic
    await storeMissionStatistic(
      eventType: 'mission_completed',
      data: {
        'mission_id': missionId,
        'mission_title': missionTitle,
        'reward': reward,
      },
    );
  }

  /// Call this when user swaps a mission
  Future<void> handleMissionSwap({
    required String missionId,
    required String newMissionTitle,
  }) async {
    await recordUserActivity();

    await _notificationService.showBasicNotification(
      title: 'Mission Swapped!',
      body: 'New mission: $newMissionTitle - Let\'s tackle this challenge!',
      payload: {
        'type': 'swap_notification',
        'mission_id': missionId,
        'screen': 'missions',
      },
    );

    // Store swap statistic
    await storeMissionStatistic(
      eventType: 'mission_swapped',
      data: {
        'mission_id': missionId,
        'new_mission_title': newMissionTitle,
      },
    );
  }

  /// Call this when user starts a game session
  Future<void> handleGameSessionStart() async {
    await recordUserActivity();

    // Store session statistic
    await storeMissionStatistic(
      eventType: 'game_session_started',
      data: {
        'session_start': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Call this when user opens the missions screen
  Future<void> handleMissionsScreenVisit() async {
    await recordUserActivity();

    // Store visit statistic
    await storeMissionStatistic(
      eventType: 'missions_screen_visited',
      data: {
        'visit_time': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
