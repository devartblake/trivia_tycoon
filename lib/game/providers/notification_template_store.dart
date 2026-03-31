import 'dart:async';
import 'dart:convert';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';

class NotificationTemplate {
  final String id; // slug
  final String title;
  final String body;
  final Map<String, String>? payload;

  NotificationTemplate({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'payload': payload,
  };

  static NotificationTemplate fromJson(Map<String, dynamic> json) {
    final p = json['payload'];
    return NotificationTemplate(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      payload: p == null ? null : Map<String, String>.from(p),
    );
  }
}

class NotificationTemplateStore {
  NotificationTemplateStore._();
  static final NotificationTemplateStore instance = NotificationTemplateStore._();

  static const String _indexKey = 'notif.template.__index';
  static String _templateKey(String id) => 'notif.template.$id';

  final _controller = StreamController<List<NotificationTemplate>>.broadcast();
  final Map<String, NotificationTemplate> _templates = {};

  Stream<List<NotificationTemplate>> watchAll() => _controller.stream;

  List<NotificationTemplate> getAll() => _templates.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  void _emit() => _controller.add(getAll());

  Future<void> save(NotificationTemplate t) async {
    _templates[t.id] = t;
    await AppSettings.setString(_templateKey(t.id), jsonEncode(t.toJson()));
    await _persistIndex();
    _emit();
  }

  Future<void> delete(String id) async {
    _templates.remove(id);
    // Remove the stored JSON for this template
    await AppSettings.setString(_templateKey(id), '');
    await _persistIndex();
    _emit();
  }

  /// Load all persisted templates from AppSettings into memory.
  /// Call once during app startup (e.g. from AppInit or a provider initializer).
  Future<void> loadAllFromSettings() async {
    _templates.clear();
    final indexRaw = await AppSettings.getString(_indexKey);
    if (indexRaw == null || indexRaw.isEmpty) {
      _emit();
      return;
    }
    final ids = List<String>.from(jsonDecode(indexRaw) as List);
    for (final id in ids) {
      final raw = await AppSettings.getString(_templateKey(id));
      if (raw == null || raw.isEmpty) continue;
      try {
        final t = NotificationTemplate.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map));
        _templates[t.id] = t;
      } catch (_) {
        // Skip malformed entries
      }
    }
    _emit();
  }

  NotificationTemplate? getById(String id) => _templates[id];

  /// Convenience for quick save by raw fields.
  Future<void> saveRaw(
      String id, String title, String body, Map<String, String>? payload) {
    return save(
        NotificationTemplate(id: id, title: title, body: body, payload: payload));
  }

  // ---------- helpers ----------

  Future<void> _persistIndex() async {
    final ids = _templates.keys.toList();
    await AppSettings.setString(_indexKey, jsonEncode(ids));
  }
}
