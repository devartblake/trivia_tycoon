import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import 'mission_service.dart';

class MissionReminderService {
  final NotificationService _notificationService = NotificationService();
  final MissionService _missionService;

  MissionReminderService(this._missionService);

  Future<void> scheduleExpiringSoonReminder(String userId) async {
    try {
      final missions = await _missionService.getUserMissions(userId);
      final expiringSoon = missions.where((m) {
        if (m.mission.expiresAt == null) return false;
        final hoursLeft = m.mission.expiresAt!.difference(DateTime.now()).inHours;
        return hoursLeft <= 2 && hoursLeft > 0 && !m.isCompleted;
      }).toList();

      for (final mission in expiringSoon) {
        await _notificationService.showBasicNotification(
          title: 'Mission Expiring Soon! ⏰',
          body: '${mission.mission.title} expires in less than 2 hours',
          payload: {
            'mission_id': mission.id,
            'type': 'expiring_soon',
          },
        );
      }
    } catch (e) {
      debugPrint('Failed to send expiring mission reminders: $e');
    }
  }

  Future<void> scheduleInactivityReminder(String userId) async {
    final reminderTime = DateTime.now().add(const Duration(hours: 24));

    await _notificationService.scheduleReminderNotification(
      title: 'Your missions await! 🎮',
      body: 'Complete your daily missions to earn rewards and XP',
      scheduledDate: reminderTime,
      payload: {
        'user_id': userId,
        'type': 'inactivity_reminder',
      },
    );
  }
}
