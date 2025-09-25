import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../../ui_components/spin_wheel/services/spin_tracker.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  bool _permissionsChecked = false;
  bool _hasPermissions = false;

  /// Initialize the notification service with channels
  Future<bool> initialize() async {
    if (_initialized) return _hasPermissions;

    try {
      await AwesomeNotifications().initialize(
        null, // Use default app icon
        [
          NotificationChannel(
            channelGroupKey: 'trivia_tycoon_group',
            channelKey: 'basic_channel',
            channelName: 'Basic Notifications',
            channelDescription: 'Basic notifications for Trivia Tycoon',
            defaultColor: const Color(0xFF6C5CE7),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            onlyAlertOnce: true,
            playSound: true,
            criticalAlerts: false,
          ),
          NotificationChannel(
            channelGroupKey: 'trivia_tycoon_group',
            channelKey: 'mission_channel',
            channelName: 'Mission Updates',
            channelDescription: 'Notifications about mission progress and rewards',
            defaultColor: const Color(0xFF52B788),
            ledColor: Colors.green,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            onlyAlertOnce: false,
            playSound: true,
          ),
          NotificationChannel(
            channelGroupKey: 'trivia_tycoon_group',
            channelKey: 'reminder_channel',
            channelName: 'Game Reminders',
            channelDescription: 'Reminders to play and continue your progress',
            defaultColor: const Color(0xFFFFB366),
            ledColor: Colors.orange,
            importance: NotificationImportance.Default,
            channelShowBadge: false,
            onlyAlertOnce: true,
            playSound: false,
          ),
          // Add spin-specific channel
          NotificationChannel(
            channelGroupKey: 'trivia_tycoon_group',
            channelKey: 'spin_channel',
            channelName: 'Spin Notifications',
            channelDescription: 'Notifications when spin cooldown is ready',
            defaultColor: const Color(0xFF8E44AD),
            ledColor: Colors.purple,
            importance: NotificationImportance.Default,
            channelShowBadge: false,
            onlyAlertOnce: true,
            playSound: true,
          ),
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'trivia_tycoon_group',
            channelGroupName: 'Trivia Tycoon',
          )
        ],
        debug: false, // Set to false in production
      );

      _initialized = true;
      debugPrint('[NotificationService] Channels initialized successfully');

      // Check permissions but don't request them yet
      await _checkPermissions();
      return _hasPermissions;

    } catch (e) {
      debugPrint('[NotificationService] Initialization failed: $e');
      _initialized = true;
      _hasPermissions = false;
      return false;
    }
  }

  /// Check if notifications are enabled and handle permission gracefully
  Future<bool> _ensurePermissions() async {
    if (!_initialized) {
      await initialize();
    }

    if (!_permissionsChecked) {
      await _checkPermissions();
    }

    // If we don't have permissions, try to request them silently (no UI)
    if (!_hasPermissions) {
      try {
        _hasPermissions = await AwesomeNotifications().requestPermissionToSendNotifications();
        debugPrint('[NotificationService] Permission request result: $_hasPermissions');
      } catch (e) {
        debugPrint('[NotificationService] Silent permission request failed: $e');
        _hasPermissions = false;
      }
    }

    return _hasPermissions;
  }

  /// Check current permission status
  Future<void> _checkPermissions() async {
    try {
      _hasPermissions = await AwesomeNotifications().isNotificationAllowed();
      _permissionsChecked = true;
      debugPrint('[NotificationService] Permission status: $_hasPermissions');
    } catch (e) {
      debugPrint('[NotificationService] Permission check failed: $e');
      _hasPermissions = false;
      _permissionsChecked = true;
    }
  }

  /// Show a basic notification with permission handling
  Future<bool> showBasicNotification({
    required String title,
    required String body,
    String? bigPicture,
    Map<String, String>? payload,
  }) async {
    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        debugPrint('[NotificationService] No notification permissions - skipping basic notification');
        return false;
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: title,
          body: body,
          bigPicture: bigPicture,
          payload: payload,
          notificationLayout: bigPicture != null
              ? NotificationLayout.BigPicture
              : NotificationLayout.Default,
        ),
      );

      debugPrint('[NotificationService] Basic notification sent: $title');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Failed to show basic notification: $e');
      return false;
    }
  }

  /// Show a mission-related notification
  Future<bool> showMissionNotification({
    required String title,
    required String body,
    int? reward,
    Map<String, String>? payload,
  }) async {
    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        debugPrint('[NotificationService] No notification permissions - skipping mission notification');
        return false;
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'mission_channel',
          title: title,
          body: body,
          payload: {
            ...?payload,
            'type': 'mission',
            if (reward != null) 'reward': reward.toString(),
          },
        ),
      );

      debugPrint('[NotificationService] Mission notification sent: $title');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Failed to show mission notification: $e');
      return false;
    }
  }

  /// Schedule spin ready notification - NEW METHOD
  Future<bool> scheduleSpinReadyNotification(Duration cooldownDuration) async {
    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        debugPrint('[NotificationService] No notification permissions - skipping spin notification');
        return false;
      }

      final readyTime = DateTime.now().add(cooldownDuration);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 101, // Fixed ID so we can cancel previous ones
          channelKey: 'spin_channel',
          title: 'Your spin is ready!',
          body: 'Come back and spin the wheel for more rewards!',
          payload: {
            'type': 'spin_ready',
            'screen': 'wheel',
          },
        ),
        schedule: NotificationCalendar(
          year: readyTime.year,
          month: readyTime.month,
          day: readyTime.day,
          hour: readyTime.hour,
          minute: readyTime.minute,
          second: 0,
          millisecond: 0,
          allowWhileIdle: true,
        ),
      );

      debugPrint('[NotificationService] Spin notification scheduled for: $readyTime');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule spin notification: $e');
      return false;
    }
  }

  /// Show a scheduled reminder notification
  Future<bool> scheduleReminderNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, String>? payload,
  }) async {
    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        debugPrint('[NotificationService] No notification permissions - skipping reminder');
        return false;
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'reminder_channel',
          title: title,
          body: body,
          payload: {
            ...?payload,
            'type': 'reminder',
          },
        ),
        schedule: NotificationCalendar.fromDate(date: scheduledDate),
      );

      debugPrint('[NotificationService] Reminder scheduled for: $scheduledDate');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule reminder: $e');
      return false;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
      debugPrint('[NotificationService] All notifications cancelled');
    } catch (e) {
      debugPrint('[NotificationService] Failed to cancel notifications: $e');
    }
  }

  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
      debugPrint('[NotificationService] Notification $id cancelled');
    } catch (e) {
      debugPrint('[NotificationService] Failed to cancel notification $id: $e');
    }
  }

  /// Cancel spin notifications specifically
  Future<void> cancelSpinNotifications() async {
    await cancelNotification(101); // Cancel the spin ready notification
  }

  /// Check current notification status
  Future<bool> isNotificationEnabled() async {
    if (!_initialized) await initialize();

    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } catch (e) {
      debugPrint('[NotificationService] Failed to check notification status: $e');
      return false;
    }
  }

  /// Request permissions with custom dialog
  Future<bool> requestPermissionsWithDialog(BuildContext context) async {
    if (!_initialized) await initialize();

    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (isAllowed) {
        _hasPermissions = true;
        return true;
      }

      // Show custom dialog explaining benefits
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Enable Notifications'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Get notified when your game activities are ready!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotificationFeature('Spin wheel ready', Icons.casino),
                    const SizedBox(height: 8),
                    _buildNotificationFeature('Mission updates', Icons.emoji_events),
                    const SizedBox(height: 8),
                    _buildNotificationFeature('Daily reminders', Icons.schedule),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You can disable notifications anytime in your device settings.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Maybe Later', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Enable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        final granted = await AwesomeNotifications().requestPermissionToSendNotifications();
        _hasPermissions = granted;
        _permissionsChecked = true;
        return granted;
      }

      return false;
    } catch (e) {
      debugPrint('[NotificationService] Permission dialog failed: $e');
      return false;
    }
  }

  Widget _buildNotificationFeature(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  /// Get permission status without requesting
  bool get hasPermissions => _hasPermissions;
  bool get isInitialized => _initialized;

  /// Force refresh permission status
  Future<void> refreshPermissionStatus() async {
    _permissionsChecked = false;
    await _checkPermissions();
  }
}

// Updated wheel_screen.dart method
// Replace your _scheduleCooldownNotification method with this:

void _scheduleCooldownNotification() async {
  // Cancel any existing spin notifications first
  await NotificationService().cancelSpinNotifications();

  // Schedule new notification
  final success = await NotificationService().scheduleSpinReadyNotification(
    SpinTracker.cooldown,
  );

  if (!success) {
    debugPrint('[WheelScreen] Notification not scheduled - permissions may be disabled');
    // App continues normally without notifications
  } else {
    debugPrint('[WheelScreen] Spin ready notification scheduled');
  }
}
