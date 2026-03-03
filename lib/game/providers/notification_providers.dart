import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../../admin/providers/admin_auth_providers.dart';
import '../services/channel_prefs.dart';
import 'notification_history_store.dart';
import 'notification_template_store.dart';
import 'riverpod_providers.dart';

/// Permission status
final permissionAllowedProvider = FutureProvider<bool>((ref) async {
  return NotificationService().isAllowed();
});

/// All scheduled notifications
final scheduledProvider = FutureProvider<List<NotificationModel>>((ref) async {
  return NotificationService().listScheduled();
});

/// Available channels (from Awesome Notifications)
/// Channels, filtered by enabled flag.
final notificationChannelsProvider = FutureProvider<List<NotificationChannel>>((ref) async {
  final known = NotificationService().knownChannels;
  final prefs = ChannelPrefs.instance;
  final List<NotificationChannel> enabledOnly = [];
  for (final c in known) {
    final key = c.channelKey ?? '';
    if (key.isEmpty) continue;
    if (await prefs.getEnabled(key)) {
      enabledOnly.add(c);
    }
  }
  // Fallback: ensure admin channels exist even if init hasn't run
  if (enabledOnly.isEmpty) {
    enabledOnly.addAll([
      NotificationChannel(
        channelKey: NotificationService.adminBasicChannel,
        channelName: 'Admin Basic',
        channelDescription: 'General admin notifications',
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelKey: NotificationService.adminPromosChannel,
        channelName: 'Admin Promotions',
        channelDescription: 'Promotional messages',
        importance: NotificationImportance.Default,
      ),
    ]);
  }
  return enabledOnly;
});

/// Convenience notifier for admin actions that should refresh lists/permissions after running.
class NotificationAdminActions extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> requestPermission() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await NotificationService().requestPermission();
      ref.invalidate(permissionAllowedProvider);
    });
  }

  Future<void> sendNow({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final serviceManager = ref.read(serviceManagerProvider);
      await serviceManager.apiService.post(
        '/admin/notifications/send',
        body: {
          'id': id,
          'channelKey': channelKey,
          'title': title,
          'body': body,
          if (payload != null) 'payload': payload,
        },
      );

      await NotificationService().sendNow(
        id: id,
        channelKey: channelKey,
        title: title,
        body: body,
        payload: payload,
      );
      // No scheduled refresh needed for instant notifications
      NotificationHistoryStore.instance.addNow(
        title: title,
        body: body,
        channelKey: channelKey,
        payload: payload,
      );
    });
  }

  Future<void> scheduleAt({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required DateTime scheduledAt,
    Map<String, String>? payload,
    bool repeats = false,
    int? weeklyWeekday,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final serviceManager = ref.read(serviceManagerProvider);
      await serviceManager.apiService.post(
        '/admin/notifications/schedule',
        body: {
          'id': id,
          'channelKey': channelKey,
          'title': title,
          'body': body,
          'scheduledAt': scheduledAt.toUtc().toIso8601String(),
          'repeats': repeats,
          if (repeats && weeklyWeekday != null) 'weekday': weeklyWeekday,
          if (payload != null) 'payload': payload,
        },
      );

      if (repeats) {
        // Schedule repeat-only notifications without creating an extra one-off schedule.
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            channelKey: channelKey,
            title: title,
            body: body,
            payload: payload,
          ),
          schedule: NotificationCalendar(
            year: null,
            month: null,
            day: null,
            hour: scheduledAt.hour,
            minute: scheduledAt.minute,
            second: 0,
            millisecond: 0,
            weekday: weeklyWeekday,
            repeats: true,
            allowWhileIdle: true,
          ),
        );
      } else {
        await NotificationService().scheduleAt(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          scheduledAt: scheduledAt,
          payload: payload,
          precise: true,
        );
      }
      ref.invalidate(scheduledProvider);
    });
  }

  Future<void> cancel(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await NotificationService().cancel(id);
      ref.invalidate(scheduledProvider);
    });
  }

  Future<void> cancelAll() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await NotificationService().cancelAll();
      ref.invalidate(scheduledProvider);
    });
  }
}

final notificationAdminActionsProvider =
AutoDisposeAsyncNotifierProvider<NotificationAdminActions, void>(() {
  return NotificationAdminActions();
});

/// Templates
final templateStoreProvider = Provider<NotificationTemplateStore>((ref) {
  return NotificationTemplateStore.instance;
});

final templatesProvider = StreamProvider((ref) {
  return NotificationTemplateStore.instance.watchAll();
});

/// History (from listeners + manual sends)
final notificationHistoryProvider = StreamProvider((ref) {
  return NotificationHistoryStore.instance.stream;
});

/// Unified admin role provider sourced from backend admin claims.
final isAdminProvider = FutureProvider<bool>((ref) async {
  return ref.watch(unifiedIsAdminProvider.future);
});
