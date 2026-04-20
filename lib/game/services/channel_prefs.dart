import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../core/services/settings/app_settings.dart';

/// Keys (same as before to keep behavior stable)
const String kNotifEnabledPrefix = 'notif.channel.enabled.'; // + <key> -> bool
const String kNotifDraftsKey = 'notif.channels.drafts'; // JSON list

/// Single-purpose adapter around AppSettings for channels.
class ChannelPrefs {
  ChannelPrefs._();
  static final ChannelPrefs instance = ChannelPrefs._();

  //AppSettings get _settings => AppSettings.instance; // adjust if your singleton differs

  Future<bool> getEnabled(String key) async {
    final v = await AppSettings.getBool(
        '$kNotifEnabledPrefix$key'); // bool? or dynamic?
    if (v == null) return true; // default enabled
    return v;
  }

  Future<void> setEnabled(String key, bool value) async {
    await AppSettings.setBool('$kNotifEnabledPrefix$key', value);
  }

  Future<List<Map<String, dynamic>>> getDrafts() async {
    final raw = await AppSettings.getString(kNotifDraftsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list
            .cast<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> addDraft({
    required String key,
    required String name,
    required String description,
    NotificationImportance importance = NotificationImportance.Default,
  }) async {
    final drafts = await getDrafts();
    drafts.removeWhere((e) => (e['key'] as String?) == key); // de-dupe
    drafts.add({
      'key': key,
      'name': name,
      'description': description,
      'importance': importance.toString().split('.').last,
    });
    await AppSettings.setString(kNotifDraftsKey, jsonEncode(drafts));
  }

  Future<void> removeDraft(String key) async {
    final drafts = await getDrafts();
    drafts.removeWhere((e) => (e['key'] as String?) == key);
    await AppSettings.setString(kNotifDraftsKey, jsonEncode(drafts));
  }
}
