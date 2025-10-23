import 'dart:async';

class NotificationHistoryEntry {
  final DateTime timestamp;
  final String title;
  final String body;
  final String channelKey;
  final Map<String, String>? payload;
  final String type; // created|displayed|action|dismissed|sentNow|scheduled

  NotificationHistoryEntry({
    required this.timestamp,
    required this.title,
    required this.body,
    required this.channelKey,
    required this.type,
    this.payload,
  });
}

class NotificationHistoryStore {
  NotificationHistoryStore._();
  static final NotificationHistoryStore instance = NotificationHistoryStore._();

  final _controller = StreamController<List<NotificationHistoryEntry>>.broadcast();
  final List<NotificationHistoryEntry> _entries = [];

  Stream<List<NotificationHistoryEntry>> get stream => _controller.stream;

  void add(NotificationHistoryEntry e) {
    _entries.insert(0, e);
    _controller.add(List.unmodifiable(_entries));
  }

  void addNow({
    required String title,
    required String body,
    required String channelKey,
    Map<String, String>? payload,
  }) {
    add(NotificationHistoryEntry(
      timestamp: DateTime.now(),
      title: title,
      body: body,
      channelKey: channelKey,
      payload: payload,
      type: 'sentNow',
    ));
  }
}
