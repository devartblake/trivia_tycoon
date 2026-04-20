import '../../models/notifications/player_inbox_item.dart';
import '../api_service.dart';

class PlayerNotificationsService {
  final ApiService apiService;

  PlayerNotificationsService(this.apiService);

  Future<List<InboxItem>> getInbox({
    bool unreadOnly = false,
    String? type,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await apiService.get(
      '/notifications/inbox',
      queryParameters: <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (unreadOnly) 'unreadOnly': true,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );

    final envelope = apiService.parsePageEnvelope<InboxItem>(
      response,
      InboxItem.fromJson,
    );
    return envelope.items;
  }

  Future<int> getUnreadCount() async {
    final response = await apiService.get('/notifications/unread-count');
    final count =
        response['unreadCount'] ?? response['count'] ?? response['total'];
    if (count is int) return count;
    if (count is String) return int.tryParse(count) ?? 0;
    return 0;
  }

  Future<void> markAsRead(String notificationId) async {
    await apiService.post(
      '/notifications/$notificationId/read',
      body: const <String, dynamic>{},
    );
  }

  Future<void> markAllAsRead() async {
    await apiService.post(
      '/notifications/read-all',
      body: const <String, dynamic>{},
    );
  }

  Future<void> dismiss(String notificationId) async {
    await apiService.delete('/notifications/$notificationId');
  }
}
