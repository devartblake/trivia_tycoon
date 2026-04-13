import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';

import '../../game/providers/notification_history_store.dart';
import '../../game/services/channel_prefs.dart' show kNotifDraftsKey, kNotifEnabledPrefix;
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class NotificationService {
  // -------- Singleton (keeps your original pattern) --------
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // -------- State (kept from your version) --------
  bool _initialized = false;
  bool _permissionsChecked = false;
  bool _hasPermissions = false;

  // -------- Channel group & keys (your existing + admin) --------
  static const String _groupKey = 'trivia_tycoon_group';

  // Existing channels (do not rename—keeps other services stable)
  static const String basicChannelKey = 'basic_channel';
  static const String missionChannelKey = 'mission_channel';
  static const String reminderChannelKey = 'reminder_channel';
  static const String spinChannelKey = 'spin_channel';

  // New admin channels (added; non-breaking)
  static const String adminBasicChannel = 'admin_basic';
  static const String adminPromosChannel = 'admin_promos';

  // Cached list of the channels we actually register at initialize()
  final List<NotificationChannel> _knownChannels = [];
  List<NotificationChannel> get knownChannels =>
      List.unmodifiable(_knownChannels);

  // ============================================================
  // Init
  // ============================================================
  /// Initialize the notification service with channels (merged set)
  Future<bool> initialize() async {
    if (_initialized) return _hasPermissions;

    try {
      final channels = <NotificationChannel>[
        // ---- Existing channels (unchanged keys) ----
        NotificationChannel(
          channelGroupKey: _groupKey,
          channelKey: basicChannelKey,
          channelName: 'Basic Notifications',
          channelDescription: 'Basic notifications for Synaptix',
          defaultColor: const Color(0xFF6C5CE7),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          onlyAlertOnce: true,
          playSound: true,
          criticalAlerts: false,
        ),
        NotificationChannel(
          channelGroupKey: _groupKey,
          channelKey: missionChannelKey,
          channelName: 'Mission Updates',
          channelDescription:
              'Notifications about mission progress and rewards',
          defaultColor: const Color(0xFF52B788),
          ledColor: Colors.green,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          onlyAlertOnce: false,
          playSound: true,
        ),
        NotificationChannel(
          channelGroupKey: _groupKey,
          channelKey: reminderChannelKey,
          channelName: 'Game Reminders',
          channelDescription: 'Reminders to play and continue your progress',
          defaultColor: const Color(0xFFFFB366),
          ledColor: Colors.orange,
          importance: NotificationImportance.Default,
          channelShowBadge: false,
          onlyAlertOnce: true,
          playSound: false,
        ),
        NotificationChannel(
          channelGroupKey: _groupKey,
          channelKey: spinChannelKey,
          channelName: 'Spin Notifications',
          channelDescription: 'Notifications when spin cooldown is ready',
          defaultColor: const Color(0xFF8E44AD),
          ledColor: Colors.purple,
          importance: NotificationImportance.Default,
          channelShowBadge: false,
          onlyAlertOnce: true,
        ),

        // ---- Added admin channels (non-breaking) ----
        NotificationChannel(
          channelGroupKey: _groupKey,
          channelKey: adminBasicChannel,
          channelName: 'Admin Basic',
          channelDescription: 'General admin notifications from control panel',
          defaultColor: const Color(0xFF3D6AF2),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelGroupKey: _groupKey,
          channelKey: adminPromosChannel,
          channelName: 'Admin Promotions',
          channelDescription: 'Promotional/marketing announcements',
          defaultColor: const Color(0xFF22C55E),
          ledColor: Colors.white,
          importance: NotificationImportance.Default,
          channelShowBadge: true,
        ),
      ];

      await AwesomeNotifications().initialize(
        null, // default app icon (or provide resource url)
        channels,
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: _groupKey,
            channelGroupName: 'Synaptix',
          ),
        ],
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
              final name = (map['name'] as String?) ?? key;
              final desc = (map['description'] as String?) ?? 'Dynamic channel';
              final importanceStr = (map['importance'] as String?)?.trim();
               final imp = NotificationImportance.values.firstWhere(
                 (v) => v.toString().split('.').last == importanceStr,
                 orElse: () => NotificationImportance.Default,
               );
              final duplicate = channels.any((c) => (c.channelKey ?? '') == key);
              if (!duplicate) {
                channels.add(NotificationChannel(
                  channelGroupKey: _groupKey,
                  channelKey: key,
                  channelName: name,
                  channelDescription: desc,
                  importance: imp,
                  defaultColor: const Color(0xFF111827),
                  ledColor: Colors.white,
                  channelShowBadge: true,
                ));
              }
            }
          }
        } catch (_) {/* ignore malformed */}
      }

      _knownChannels
        ..clear()
        ..addAll(channels);

      // Optional: listeners for logging or deep-link routing
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onActionReceived,
        onNotificationCreatedMethod: _onCreated,
        onNotificationDisplayedMethod: _onDisplayed,
        onDismissActionReceivedMethod: _onDismissed,
      );

      LogManager.debug('[NotificationService] Channels initialized successfully');

      // Check permissions but don't request yet
      await _checkPermissions();

      _initialized = true;
      return _hasPermissions;
    } catch (e) {
      LogManager.debug('[NotificationService] Initialization failed: $e');
      _initialized = true;
      _hasPermissions = false;
      return false;
    }
  }

  // ============================================================
  // Permissions (kept + added silent helpers)
  // ============================================================
  Future<bool> _ensurePermissions() async {
    if (!_initialized) {
      await initialize();
    }
    if (!_permissionsChecked) {
      await _checkPermissions();
    }

    // If not allowed, try a silent request (no dialog)
    if (!_hasPermissions) {
      try {
        _hasPermissions =
            await AwesomeNotifications().requestPermissionToSendNotifications();
        LogManager.debug(
            '[NotificationService] Permission request result: $_hasPermissions');
      } on PlatformException catch (e) {
        _markPermissionsDenied(e);
        LogManager.debug(
            '[NotificationService] Silent permission request blocked: ${e.code} ${e.message}');
      } catch (e) {
        LogManager.debug(
            '[NotificationService] Silent permission request failed: $e');
        _hasPermissions = false;
      }
    }
    return _hasPermissions;
  }

  Future<void> _checkPermissions() async {
    try {
      _hasPermissions = await AwesomeNotifications().isNotificationAllowed();
      _permissionsChecked = true;
      LogManager.debug('[NotificationService] Permission status: $_hasPermissions');
    } catch (e) {
      LogManager.debug('[NotificationService] Permission check failed: $e');
      _hasPermissions = false;
      _permissionsChecked = true;
    }
  }

  /// New: direct permission helpers for admin UI (non-breaking additions)
  Future<bool> isAllowed() => AwesomeNotifications().isNotificationAllowed();
  Future<bool> isAllowedSafe() async {
    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } on PlatformException catch (e) {
      _markPermissionsDenied(e);
      LogManager.debug(
          '[NotificationService] Permission status unavailable: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      LogManager.debug('[NotificationService] Permission status unavailable: $e');
      return false;
    }
  }

  Future<void> requestPermission() async {
    if (!_initialized) await initialize();
    try {
      final granted =
          await AwesomeNotifications().requestPermissionToSendNotifications();
      _hasPermissions = granted;
      _permissionsChecked = true;
    } on PlatformException catch (e) {
      _markPermissionsDenied(e);
      LogManager.debug(
          '[NotificationService] requestPermission() blocked: ${e.code} ${e.message}');
    } catch (e) {
      LogManager.debug('[NotificationService] requestPermission() failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Back-compat aliases (used by existing app code)
  // ---------------------------------------------------------------------------
  /// Legacy name kept for older call sites in app_init.dart and settings_screen.dart.
  /// Internally forwards to [isAllowed()].
  Future<bool> isNotificationEnabled() => isAllowed();

  /// Optional: legacy-style "enable" that silently requests permission
  /// without showing a custom dialog. Keep if older code calls it.
  Future<bool> enableNotificationsSilently() async {
    await requestPermission();
    return _hasPermissions;
  }

  // ============================================================
  // Immediate & Scheduled (existing kept + generic admin helpers)
  // ============================================================

  /// Existing: Show a basic notification (kept as-is)
  Future<bool> showBasicNotification({required String title, required String body, String? bigPicture,Map<String, String>? payload}) async {
    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        LogManager.debug(
            '[NotificationService] No notification permissions - skipping basic notification');
        return false;
      }

      await AwesomeNotifications().createNotification(
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
      );
      LogManager.debug('[NotificationService] Basic notification sent: $title');
      return true;
    } on PlatformException catch (e) {
      _markPermissionsDenied(e);
      LogManager.debug(
          '[NotificationService] Basic notification skipped: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      LogManager.debug('[NotificationService] Failed to show basic notification: $e');
      return false;
    }
  }

  /// Existing: Mission notification (kept as-is)
  Future<bool> showMissionNotification({
    required String title,
    required String body,
    int? reward,
    Map<String, String>? payload,
  }) async {
    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        LogManager.debug(
            '[NotificationService] No notification permissions - skipping mission notification');
        return false;
      }

      await AwesomeNotifications().createNotification(
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

      LogManager.debug('[NotificationService] Mission notification sent: $title');
      return true;
    } on PlatformException catch (e) {
      _markPermissionsDenied(e);
      LogManager.debug(
          '[NotificationService] Mission notification skipped: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      LogManager.debug(
          '[NotificationService] Failed to show mission notification: $e');
      return false;
    }
  }

  /// Existing: Spin ready after cooldown (kept as-is)
  Future<bool> scheduleSpinReadyNotification(Duration cooldownDuration) async {
    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        LogManager.debug(
            '[NotificationService] No notification permissions - skipping spin notification');
        return false;
      }

      final readyTime = DateTime.now().add(cooldownDuration);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 101, // Fixed ID so we can cancel previous ones
          channelKey: spinChannelKey,
          title: 'Your spin is ready!',
          body: 'Come back and spin the wheel for rewards.',
          payload: {'type': 'spin_ready'},
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

      LogManager.debug(
          '[NotificationService] Spin notification scheduled for: $readyTime');
      return true;
    } on PlatformException catch (e) {
      _markPermissionsDenied(e);
      LogManager.debug(
          '[NotificationService] Spin notification skipped: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      LogManager.debug(
          '[NotificationService] Failed to schedule spin notification: $e');
      return false;
    }
  }

  /// Existing: Scheduled reminder (kept as-is)
  Future<bool> scheduleReminderNotification({required String title, required String body, required DateTime scheduledDate, Map<String, String>? payload}) async {
    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        LogManager.debug(
            '[NotificationService] No notification permissions - skipping reminder');
        return false;
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: reminderChannelKey,
          title: title,
          body: body,
          payload: payload,
        ),
        schedule: NotificationCalendar(
          year: scheduledDate.year,
          month: scheduledDate.month,
          day: scheduledDate.day,
          hour: scheduledDate.hour,
          minute: scheduledDate.minute,
          second: 0,
          millisecond: 0,
          allowWhileIdle: true,
        ),
      );

      LogManager.debug('[NotificationService] Reminder scheduled at: $scheduledDate');
      return true;
    } on PlatformException catch (e) {
      _markPermissionsDenied(e);
      LogManager.debug(
          '[NotificationService] Reminder skipped: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      LogManager.debug('[NotificationService] Failed to schedule reminder: $e');
      return false;
    }
  }

  Future<bool> _isChannelEnabled(String channelKey) async {
    final v = await AppSettings.getBool('$kNotifEnabledPrefix$channelKey');
    return v ?? true; // default enabled
  }

  // ---- New, generic helpers used by Admin UI (non-breaking additions) ----
  Future<void> sendNow({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    Map<String, String>? payload,
    NotificationLayout layout = NotificationLayout.Default,
    List<NotificationActionButton>? actionButtons,
  }) async {
    final hasPermission = await _ensurePermissions();
    if (!hasPermission) {
      LogManager.debug(
          '[NotificationService] No notification permissions - skipping sendNow.');
      return;
    }
    if (!await _isChannelEnabled(channelKey)) {
      LogManager.debug('[NotificationService] Channel "$channelKey" is disabled. Skipping sendNow.');
      return;
    }
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          payload: payload,
          notificationLayout: layout,
        ),
        actionButtons: actionButtons,
      );
    } on PlatformException catch (e) {
      _markPermissionsDenied(e);
      LogManager.debug(
          '[NotificationService] sendNow skipped: ${e.code} ${e.message}');
    }
  }

  Future<void> scheduleAt({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required DateTime scheduledAt,
    Map<String, String>? payload,
    bool precise = true,
    List<NotificationActionButton>? actionButtons,
  }) async {
    final hasPermission = await _ensurePermissions();
    if (!hasPermission) {
      LogManager.debug(
          '[NotificationService] No notification permissions - skipping scheduleAt.');
      return;
    }
    if (!await _isChannelEnabled(channelKey)) {
      LogManager.debug('[NotificationService] Channel "$channelKey" is disabled. Skipping sendNow.');
      return;
    }
    try {
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
        actionButtons: actionButtons,
      );
    } on PlatformException catch (e) {
      _markPermissionsDenied(e);
      LogManager.debug(
          '[NotificationService] scheduleAt skipped: ${e.code} ${e.message}');
    }
  }

  Future<List<NotificationModel>> listScheduled() {
    return AwesomeNotifications().listScheduledNotifications();
  }

  // Aliases added for admin UI (keeps your originals too)
  Future<void> cancel(int id) => cancelNotification(id);
  Future<void> cancelAll() => cancelAllNotifications();

  Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
      LogManager.debug('[NotificationService] All notifications cancelled');
    } catch (e) {
      LogManager.debug('[NotificationService] Failed to cancel notifications: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
      LogManager.debug('[NotificationService] Notification $id cancelled');
    } catch (e) {
      LogManager.debug('[NotificationService] Failed to cancel notification $id: $e');
    }
  }

  Future<void> cancelSpinNotifications() async {
    await cancelNotification(101); // Fixed spin ID
  }

  /// Compute next scheduled fire time for a given schedule (for UI display)
  Future<DateTime?> getNextFireTime(NotificationSchedule schedule) {
    return AwesomeNotifications().getNextDate(schedule);
  }

  // ============================================================
  // Permission dialog (kept from your version)
  // ============================================================
  Future<bool> requestPermissionsWithDialog(BuildContext context) async {
    if (!_initialized) await initialize();

    try {
      final isAllowed = await isAllowedSafe();
      if (isAllowed) {
        _hasPermissions = true;
        return true;
      }

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
              child: Text('Maybe Later',
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Enable',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        final granted =
            await AwesomeNotifications().requestPermissionToSendNotifications();
        _hasPermissions = granted;
        _permissionsChecked = true;
        return granted;
      }

      return false;
    } on PlatformException catch (e) {
      _markPermissionsDenied(e);
      LogManager.debug(
          '[NotificationService] Permission dialog blocked: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      LogManager.debug('[NotificationService] Permission dialog failed: $e');
      return false;
    }
  }

  bool get hasPermissions => _hasPermissions;
  bool get isInitialized => _initialized;

  Future<void> refreshPermissionStatus() async {
    _permissionsChecked = false;
    await _checkPermissions();
  }

  void _markPermissionsDenied([PlatformException? exception]) {
    _hasPermissions = false;
    _permissionsChecked = true;
    if (exception != null) {
      LogManager.debug(
          '[NotificationService] Notifications unavailable: ${exception.code} ${exception.message}');
    }
  }

  // ============================================================
  // Listeners (optional)
  // ============================================================
  static Future<void> _onCreated(ReceivedNotification n) async {
    await NotificationHistoryStore.instance.add(NotificationHistoryEntry(
      timestamp: DateTime.now(),
      title: n.title ?? '',
      body: n.body ?? '',
      channelKey: n.channelKey ?? '',
      payload: n.payload?.map((k, v) => MapEntry(k, v.toString())),
      type: 'created',
    ));
  }

  static Future<void> _onDisplayed(ReceivedNotification n) async {
    await NotificationHistoryStore.instance.add(NotificationHistoryEntry(
      timestamp: DateTime.now(),
      title: n.title ?? '',
      body: n.body ?? '',
      channelKey: n.channelKey ?? '',
      payload: n.payload?.map((k, v) => MapEntry(k, v.toString())),
      type: 'displayed',
    ));
  }

  static Future<void> _onDismissed(ReceivedAction a) async {
    await NotificationHistoryStore.instance.add(NotificationHistoryEntry(
      timestamp: DateTime.now(),
      title: a.title ?? '',
      body: a.body ?? '',
      channelKey: a.channelKey ?? '',
      payload: a.payload?.map((k, v) => MapEntry(k, v.toString())),
      type: 'dismissed',
    ));
  }

  static Future<void> _onActionReceived(ReceivedAction a) async {
    await NotificationHistoryStore.instance.add(NotificationHistoryEntry(
      timestamp: DateTime.now(),
      title: a.title ?? '',
      body: a.body ?? '',
      channelKey: a.channelKey ?? '',
      payload: a.payload?.map((k, v) => MapEntry(k, v.toString())),
      type: 'action',
    ));
  }
}

// Small helper row (kept visually identical to your dialog)
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

