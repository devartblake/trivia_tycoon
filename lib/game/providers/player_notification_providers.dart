import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/notifications/player_inbox_item.dart';
import '../../core/services/notifications/player_notifications_service.dart';
import 'core_providers.dart';
import 'hub_providers.dart';

final playerNotificationsServiceProvider =
    Provider<PlayerNotificationsService>((ref) {
  return PlayerNotificationsService(ref.watch(apiServiceProvider));
});

final playerNotificationInboxProvider =
    FutureProvider<List<InboxItem>>((ref) async {
  final service = ref.watch(playerNotificationsServiceProvider);
  return service.getInbox();
});

final playerNotificationUnreadCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(playerNotificationsServiceProvider);
  return service.getUnreadCount();
});

final notificationRealtimeSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<dynamic>>(playerNotificationStreamProvider, (_, next) {
    next.whenData((_) {
      ref.invalidate(playerNotificationInboxProvider);
      ref.invalidate(playerNotificationUnreadCountProvider);
    });
  });
});

class PlayerNotificationActions {
  final Ref ref;

  PlayerNotificationActions(this.ref);

  Future<void> markRead(String notificationId) async {
    await ref
        .read(playerNotificationsServiceProvider)
        .markAsRead(notificationId);
    ref.invalidate(playerNotificationInboxProvider);
    ref.invalidate(playerNotificationUnreadCountProvider);
  }

  Future<void> markAllRead() async {
    await ref.read(playerNotificationsServiceProvider).markAllAsRead();
    ref.invalidate(playerNotificationInboxProvider);
    ref.invalidate(playerNotificationUnreadCountProvider);
  }

  Future<void> dismiss(String notificationId) async {
    await ref.read(playerNotificationsServiceProvider).dismiss(notificationId);
    ref.invalidate(playerNotificationInboxProvider);
    ref.invalidate(playerNotificationUnreadCountProvider);
  }
}

final playerNotificationActionsProvider =
    Provider<PlayerNotificationActions>((ref) {
  return PlayerNotificationActions(ref);
});
