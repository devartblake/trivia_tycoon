import 'package:synaptix/core/manager/log_manager.dart';
import 'package:synaptix/core/services/guest_api_gate.dart';
import 'package:synaptix/core/services/settings/app_settings.dart';

/// Persists guest-session metadata used for API gating, toasts, and wipe timers.
class GuestSessionStore {
  GuestSessionStore._();

  static const String guestActiveKey = 'guest_session_active';
  static const String sessionStartedAtKey = 'guest_session_started_at';
  static const String leftAtKey = 'guest_session_left_at';
  static const String warned25mKey = 'guest_session_warned_25m';

  /// Load persisted guest flag into [GuestApiGate.isGuestSession].
  static Future<void> hydrate() async {
    try {
      final active = await AppSettings.getString(guestActiveKey);
      final isGuest = active == 'true';
      GuestApiGate.isGuestSession = isGuest;
    } catch (e) {
      LogManager.debug('[GuestSessionStore] hydrate failed: $e');
    }
  }

  static Future<void> startGuestSession() async {
    final now = DateTime.now().toUtc();
    GuestApiGate.isGuestSession = true;
    await AppSettings.setString(guestActiveKey, 'true');
    await AppSettings.setString(sessionStartedAtKey, now.toIso8601String());
    await AppSettings.setString(leftAtKey, '');
    await AppSettings.setString(warned25mKey, 'false');
    LogManager.debug('[GuestSessionStore] Guest session started');
  }

  static Future<void> clearGuestSession() async {
    GuestApiGate.isGuestSession = false;
    await AppSettings.setString(guestActiveKey, 'false');
    await AppSettings.setString(sessionStartedAtKey, '');
    await AppSettings.setString(leftAtKey, '');
    await AppSettings.setString(warned25mKey, 'false');
    LogManager.debug('[GuestSessionStore] Guest session cleared');
  }

  static Future<bool> isGuestSessionActive() async {
    final active = await AppSettings.getString(guestActiveKey);
    return active == 'true';
  }

  static Future<DateTime?> sessionStartedAt() async {
    final raw = await AppSettings.getString(sessionStartedAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  static Future<void> markLeft() async {
    final now = DateTime.now().toUtc();
    await AppSettings.setString(leftAtKey, now.toIso8601String());
  }

  static Future<void> clearLeft() async {
    await AppSettings.setString(leftAtKey, '');
  }

  static Future<DateTime?> leftAt() async {
    final raw = await AppSettings.getString(leftAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  static Future<bool> hasWarned25m() async {
    final raw = await AppSettings.getString(warned25mKey);
    return raw == 'true';
  }

  static Future<void> markWarned25m() async {
    await AppSettings.setString(warned25mKey, 'true');
  }
}
