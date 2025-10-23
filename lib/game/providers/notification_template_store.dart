import 'dart:async';
import 'dart:convert';

/// Minimal persistence facade.
/// Replace the in-memory map with your AppSettings/AppCacheService calls.
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

  final _controller = StreamController<List<NotificationTemplate>>.broadcast();
  final Map<String, NotificationTemplate> _templates = {};

  Stream<List<NotificationTemplate>> watchAll() => _controller.stream;

  List<NotificationTemplate> getAll() => _templates.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  void _emit() => _controller.add(getAll());

  Future<void> save(NotificationTemplate t) async {
    _templates[t.id] = t;
    // TODO: persist: await AppSettings().setString('notif.template.${t.id}', jsonEncode(t.toJson()));
    _emit();
  }

  Future<void> delete(String id) async {
    _templates.remove(id);
    // TODO: remove from AppSettings
    _emit();
  }

  Future<void> loadAllFromSettings() async {
    // TODO: read keys from AppSettings cache and populate _templates
    _emit();
  }

  NotificationTemplate? getById(String id) => _templates[id];

  // Convenience for quick save by raw fields
  Future<void> saveRaw(String id, String title, String body, Map<String, String>? payload) {
    return save(NotificationTemplate(id: id, title: title, body: body, payload: payload));
  }
}
