import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:synaptix/core/services/settings/app_settings.dart';
import 'package:synaptix/synaptix/mode/synaptix_mode.dart';
import 'package:synaptix/game/providers/notification_history_store.dart';
import 'package:synaptix/game/services/channel_prefs.dart'
    show kNotifDraftsKey;
import 'package:synaptix/core/manager/log_manager.dart';

/// Modernized Notification Service for Synaptix.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  bool _hasPermissions = false;

  static const String _groupKey = 'synaptix_group';

  // Standard channels
  static const String basicChannelKey = 'basic_channel';
  static const String missionChannelKey = 'mission_channel';
  static const String reminderChannelKey = 'reminder_channel';
  static const String spinChannelKey = 'spin_channel';
  static const String criticalChannelKey = 'critical_channel';

  // Admin channels
  static const String adminBasicChannel = 'admin_basic';
  static const String adminPromosChannel = 'admin_promos';

  final List<NotificationChannel> _knownChannels = [];
  List<NotificationChannel> get knownChannels =>
      List.unmodifiable(_knownChannels);

  // ============================================================
  // Listeners (Must be STATIC and marked with @pragma)
  // ============================================================

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    await NotificationHistoryStore.instance.add(NotificationHistoryEntry(
      timestamp: DateTime.now(),
      title: receivedNotification.title ?? '',
      body: receivedNotification.body ?? '',
      channelKey: receivedNotification.channelKey ?? '',
      payload: receivedNotification.payload
          ?.map((k, v) => MapEntry(k, v.toString())),
      type: 'created',
    ));
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    await NotificationHistoryStore.instance.add(NotificationHistoryEntry(
      timestamp: DateTime.now(),
      title: receivedNotification.title ?? '',
      body: receivedNotification.body ?? '',
      channelKey: receivedNotification.channelKey ?? '',
      payload: receivedNotification.payload
          ?.map((k, v) => MapEntry(k, v.toString())),
      type: 'displayed',
    ));
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    await NotificationHistoryStore.instance.add(NotificationHistoryEntry(
      timestamp: DateTime.now(),
      title: receivedAction.title ?? '',
      body: receivedAction.body ?? '',
      channelKey: receivedAction.channelKey ?? '',
      payload:
          receivedAction.payload?.map((k, v) => MapEntry(k, v.toString())),
      type: 'dismissed',
    ));
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    await NotificationHistoryStore.instance.add(NotificationHistoryEntry(
      timestamp: DateTime.now(),
      title: receivedAction.title ?? '',
      body: receivedAction.body ?? '',
      channelKey: receivedAction.channelKey ?? '',
      payload:
          receivedAction.payload?.map((k, v) => MapEntry(k, v.toString())),
      type: 'action',
    ));
  }

  // ============================================================
  // Initialization
  // ============================================================

  Future<bool> initialize({SynaptixMode mode = SynaptixMode.teen}) async {
    if (_initialized) return _hasPermissions;

    try {
      final channels = _buildChannels(mode);

      await AwesomeNotifications().initialize(
        null,
        channels,
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: _groupKey,
            channelGroupName: mode == SynaptixMode.kids ? 'Quest Central' : 'Synaptix',
          ),
        ],
        debug: true,
      );

      final rawDrafts = await AppSettings.getString(kNotifDraftsKey);
      if (rawDrafts != null && rawDrafts.isNotEmpty) {
        try {
          final list = jsonDecode(rawDrafts);
          if (list is List) {
            for (final e in list) {
              final map = Map<String, dynamic>.from(e as Map);
              final key = (map['key'] as String?)?.trim();
              if (key == null || key.isEmpty) continue;
              if (!channels.any((c) => c.channelKey == key)) {
                channels.add(NotificationChannel(
                  channelGroupKey: _groupKey,
                  channelKey: key,
                  channelName: map['name'] ?? key,
                  channelDescription: map['description'] ?? 'Dynamic channel',
                  importance: NotificationImportance.Default,
                  defaultColor: const Color(0xFF111827),
                  ledColor: Colors.white,
                ));
              }
            }
          }
        } catch (_) {}
      }

      _knownChannels
        ..clear()
        ..addAll(channels);

      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod,
      );

      await _checkPermissions();
      _initialized = true;
      LogManager.debug('[NotificationService] Revamped system initialized');
      return _hasPermissions;
    } catch (e) {
      LogManager.error('[NotificationService] Initialization failed: $e');
      _initialized = true;
      return false;
    }
  }

  List<NotificationChannel> _buildChannels(SynaptixMode mode) {
    final isKids = mode == SynaptixMode.kids;
    final isAdult = mode == SynaptixMode.adult;

    return [
      NotificationChannel(
        channelGroupKey: _groupKey,
        channelKey: basicChannelKey,
        channelName: isKids ? 'Fun Alerts' : 'Basic Notifications',
        channelDescription: isAdult ? 'General system updates' : 'General notifications',
        defaultColor: isKids ? Colors.orange : const Color(0xFF6C5CE7),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
      ),
      NotificationChannel(
        channelGroupKey: _groupKey,
        channelKey: missionChannelKey,
        channelName: isKids ? 'Treasure Quests' : 'Mission Updates',
        channelDescription: 'Progress and rewards',
        defaultColor: isKids ? Colors.green : const Color(0xFF52B788),
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelGroupKey: _groupKey,
        channelKey: criticalChannelKey,
        channelName: 'High Priority Alerts',
        channelDescription: 'Critical events and Boss challenges',
        defaultColor: Colors.red,
        importance: NotificationImportance.Max,
        criticalAlerts: true,
        onlyAlertOnce: true,
      ),
      NotificationChannel(
        channelGroupKey: _groupKey,
        channelKey: spinChannelKey,
        channelName: 'Cooldown Alerts',
        channelDescription: 'Notifications for ready activities',
        defaultColor: const Color(0xFF8E44AD),
        importance: NotificationImportance.Default,
      ),
      NotificationChannel(
        channelGroupKey: _groupKey,
        channelKey: adminBasicChannel,
        channelName: 'Command Center',
        channelDescription: 'Admin announcements',
        defaultColor: const Color(0xFF3D6AF2),
        importance: NotificationImportance.High,
      ),
    ];
  }

  // ============================================================
  // Notifications logic
  // ============================================================

  Future<bool> showBasicNotification({
    required String title,
    required String body,
    String? bigPicture,
    Map<String, String>? payload,
    List<NotificationActionButton>? actionButtons,
  }) async {
    try {
      final allowed = await _ensurePermissions();
      if (!allowed) return false;

      return await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: basicChannelKey,
          title: title,
          body: body,
          bigPicture: bigPicture,
          payload: payload,
          notificationLayout: bigPicture != null
              ? NotificationLayout.BigPicture
              : NotificationLayout.Default,
        ),
        actionButtons: actionButtons,
      );
    } catch (e) {
      LogManager.error('[NotificationService] Failed to send: $e');
      return false;
    }
  }

  Future<bool> showMissionNotification({
    required String title,
    required String body,
    int? reward,
    Map<String, String>? payload,
  }) async {
    try {
      final allowed = await _ensurePermissions();
      if (!allowed) return false;

      return await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: missionChannelKey,
          title: title,
          body: body,
          payload: {
            ...?payload,
            if (reward != null) 'reward': reward.toString(),
          },
        ),
      );
    } catch (e) {
      LogManager.error('[NotificationService] Mission notification failed: $e');
      return false;
    }
  }

  Future<bool> scheduleReminderNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, String>? payload,
  }) async {
    try {
      final allowed = await _ensurePermissions();
      if (!allowed) return false;

      return await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: reminderChannelKey,
          title: title,
          body: body,
          payload: payload,
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledDate,
          allowWhileIdle: true,
        ),
      );
    } catch (e) {
      LogManager.error('[NotificationService] Reminder scheduling failed: $e');
      return false;
    }
  }

  Future<bool> scheduleSpinReadyNotification(Duration cooldown) async {
    try {
      final allowed = await _ensurePermissions();
      if (!allowed) return false;

      final scheduledAt = DateTime.now().add(cooldown);
      return await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 101,
          channelKey: spinChannelKey,
          title: 'Spin Ready! 🎡',
          body: 'Your cooldown has finished. Tap to spin for rewards!',
          payload: {'route': '/spin-earn', 'type': 'spin_ready'},
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledAt,
          allowWhileIdle: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'SPIN_NOW',
            label: 'Spin Now',
            color: Colors.purple,
          ),
        ],
      );
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // Helper methods
  // ============================================================

  Future<bool> _ensurePermissions() async {
    if (!_initialized) await initialize();
    if (!await isAllowed()) {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return true;
  }

  Future<void> _checkPermissions() async {
    _hasPermissions = await AwesomeNotifications().isNotificationAllowed();
  }

  Future<bool> isAllowed() => AwesomeNotifications().isNotificationAllowed();
  
  Future<void> requestPermission() async {
    _hasPermissions = await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<void> cancel(int id) => AwesomeNotifications().cancel(id);
  Future<void> cancelAll() => AwesomeNotifications().cancelAll();
  
  Future<List<NotificationModel>> listScheduled() =>
      AwesomeNotifications().listScheduledNotifications();

  Future<void> sendNow({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    Map<String, String>? payload,
    List<NotificationActionButton>? actionButtons,
  }) async {
    if (!await _ensurePermissions()) return;
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: title,
        body: body,
        payload: payload,
      ),
      actionButtons: actionButtons,
    );
  }

  Future<void> scheduleAt({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required DateTime scheduledAt,
    Map<String, String>? payload,
    bool precise = true,
  }) async {
    if (!await _ensurePermissions()) return;
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: title,
        body: body,
        payload: payload,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledAt,
        preciseAlarm: precise,
        allowWhileIdle: true,
      ),
    );
  }

  Future<bool> isNotificationEnabled() => isAllowed();

  Future<DateTime?> getNextFireTime(NotificationSchedule schedule) {
    return AwesomeNotifications().getNextDate(schedule);
  }

  Future<void> cancelSpinNotifications() async {
    await cancel(101);
  }

  Future<bool> requestPermissionsWithDialog(BuildContext context) async {
    if (!_initialized) await initialize();

    try {
      final allowed = await isAllowed();
      if (allowed) {
        _hasPermissions = true;
        return true;
      }

      if (!context.mounted) return false;
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.notifications, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text('Enable Notifications'),
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
                  children: const [
                    _NotificationFeatureRow('Spin wheel ready', Icons.casino),
                    SizedBox(height: 8),
                    _NotificationFeatureRow(
                        'Mission updates', Icons.emoji_events),
                    SizedBox(height: 8),
                    _NotificationFeatureRow('Daily reminders', Icons.schedule),
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
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Enable', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        await requestPermission();
        return _hasPermissions;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}

class _NotificationFeatureRow extends StatelessWidget {
  final String text;
  final IconData icon;
  const _NotificationFeatureRow(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
