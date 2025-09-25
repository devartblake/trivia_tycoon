import 'dart:async';
import '../services/notification_service.dart';
import '../services/background_task_service.dart';

/// Helper class to integrate notifications with your existing mission system
class MissionNotificationHelper {
  static final MissionNotificationHelper _instance = MissionNotificationHelper._internal();
  factory MissionNotificationHelper() => _instance;
  MissionNotificationHelper._internal();

  final NotificationService _notificationService = NotificationService();
  final BackgroundTaskService _backgroundTaskService = BackgroundTaskService();

  /// Integration points for your existing mission system

  /// Call this from your MissionProvider when a mission is completed
  Future<void> onMissionCompleted({
    required String missionId,
    required String missionTitle,
    required int reward,
    required String userId,
  }) async {
    // Send immediate notification
    await _notificationService.showMissionNotification(
      title: 'Mission Complete! 🎉',
      body: '$missionTitle completed! You earned $reward XP!',
      reward: reward,
      payload: {
        'mission_id': missionId,
        'user_id': userId,
        'type': 'completion',
        'screen': 'missions',
      },
    );

    // Handle background task integration
    await _backgroundTaskService.handleMissionCompletion(
      missionId: missionId,
      missionTitle: missionTitle,
      reward: reward,
    );
  }

  /// Call this from your MissionProvider when a mission is swapped
  Future<void> onMissionSwapped({
    required String oldMissionId,
    required String newMissionId,
    required String newMissionTitle,
    required String userId,
  }) async {
    // Send swap notification
    await _notificationService.showBasicNotification(
      title: 'Mission Swapped! 🔄',
      body: 'New mission: $newMissionTitle',
      payload: {
        'old_mission_id': oldMissionId,
        'new_mission_id': newMissionId,
        'user_id': userId,
        'type': 'swap',
        'screen': 'missions',
      },
    );

    // Handle background task integration
    await _backgroundTaskService.handleMissionSwap(
      missionId: newMissionId,
      newMissionTitle: newMissionTitle,
    );
  }

  /// Call this when mission progress is updated
  Future<void> onMissionProgressUpdated({
    required String missionId,
    required String missionTitle,
    required int oldProgress,
    required int newProgress,
    required int total,
    required String userId,
  }) async {
    // Record user activity
    await _backgroundTaskService.recordUserActivity();

    // Send milestone notifications for significant progress
    final oldPercentage = (oldProgress / total * 100).round();
    final newPercentage = (newProgress / total * 100).round();

    // Notify on 25%, 50%, 75% milestones
    final milestones = [25, 50, 75];
    for (final milestone in milestones) {
      if (oldPercentage < milestone && newPercentage >= milestone) {
        await _notificationService.showBasicNotification(
          title: 'Great Progress! 📈',
          body: '$missionTitle is $milestone% complete!',
          payload: {
            'mission_id': missionId,
            'user_id': userId,
            'type': 'progress_milestone',
            'milestone': milestone.toString(),
            'screen': 'missions',
          },
        );
        break;
      }
    }
  }

  /// Call this when user assigns a new daily mission
  Future<void> onDailyMissionsGenerated({
    required List<Map<String, dynamic>> newMissions,
    required String userId,
  }) async {
    if (newMissions.isEmpty) return;

    await _notificationService.showBasicNotification(
      title: 'New Daily Missions! 📋',
      body: '${newMissions.length} fresh challenges await you!',
      payload: {
        'user_id': userId,
        'type': 'daily_missions_generated',
        'mission_count': newMissions.length.toString(),
        'screen': 'missions',
      },
    );
  }

  /// Call this when user opens the missions screen
  Future<void> onMissionsScreenVisited({required String userId}) async {
    await _backgroundTaskService.handleMissionsScreenVisit();
  }

  /// Call this when user starts playing the game
  Future<void> onGameSessionStarted({required String userId}) async {
    await _backgroundTaskService.handleGameSessionStart();
  }

  /// Schedule custom mission reminders
  Future<void> scheduleCustomReminder({
    required Duration delay,
    required String title,
    required String body,
    Map<String, String>? additionalPayload,
  }) async {
    await _backgroundTaskService.scheduleOneTimeReminder(
      delay: delay,
      title: title,
      body: body,
      payload: {
        'type': 'custom_reminder',
        ...?additionalPayload,
      },
    );
  }

  /// Get background service status for debugging
  Map<String, dynamic> getBackgroundServiceStatus() {
    return _backgroundTaskService.getStatus();
  }

  /// Handle notification taps/interactions
  Future<void> handleNotificationTap({
    required Map<String, String?> payload,
    required Function(String route) navigateToScreen,
  }) async {
    final type = payload['type'];
    final screen = payload['screen'] ?? 'missions';

    switch (type) {
      case 'completion':
      case 'swap':
      case 'progress_milestone':
        navigateToScreen('/missions');
        break;
      case 'daily_missions_generated':
        navigateToScreen('/missions');
        break;
      case 'expiring_soon':
        navigateToScreen('/missions');
        break;
      case 'inactivity_reminder':
        navigateToScreen('/home'); // Or your main game screen
        break;
      case 'daily_reminder':
        navigateToScreen('/missions');
        break;
      default:
        if (screen.isNotEmpty) {
          navigateToScreen('/$screen');
        }
        break;
    }
  }
}
