import 'dart:async';
import 'dart:convert';

import 'package:trivia_tycoon/core/services/settings/app_settings.dart';

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

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'title': title,
        'body': body,
        'channelKey': channelKey,
        'payload': payload,
        'type': type,
      };

  static NotificationHistoryEntry fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return NotificationHistoryEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      channelKey: json['channelKey'] as String? ?? '',
      type: json['type'] as String? ?? 'sentNow',
      payload: payload == null ? null : Map<String, String>.from(payload as Map),
    );
  }
}

class NotificationHistoryStore {
  NotificationHistoryStore._();
  static final NotificationHistoryStore instance = NotificationHistoryStore._();
  static const String _storageKey = 'notif.history.entries';
  static const int _maxEntries = 100;

  final _controller = StreamController<List<NotificationHistoryEntry>>.broadcast();
  final List<NotificationHistoryEntry> _entries = [];

  Stream<List<NotificationHistoryEntry>> get stream => _controller.stream;
  List<NotificationHistoryEntry> get entries => List.unmodifiable(_entries);

  Future<void> add(NotificationHistoryEntry e) async {
    _entries.insert(0, e);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    _controller.add(List.unmodifiable(_entries));
    await _persist();
  }

  Future<void> addNow({
    required String title,
    required String body,
    required String channelKey,
    Map<String, String>? payload,
  }) async {
    await add(NotificationHistoryEntry(
      timestamp: DateTime.now(),
      title: title,
      body: body,
      channelKey: channelKey,
      payload: payload,
      type: 'sentNow',
    ));
  }

  Future<void> loadAllFromSettings() async {
    _entries.clear();

    final raw = await AppSettings.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _controller.add(List.unmodifiable(_entries));
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          _entries.add(
            NotificationHistoryEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          );
        }
      }
    } catch (_) {
      // Ignore malformed persisted history and start fresh.
    }

    _controller.add(List.unmodifiable(_entries));
  }

  Future<void> _persist() async {
    final raw = jsonEncode(_entries.map((entry) => entry.toJson()).toList());
    await AppSettings.setString(_storageKey, raw);
  }
}
