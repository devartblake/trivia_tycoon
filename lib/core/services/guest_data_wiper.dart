import 'package:hive/hive.dart';
import 'package:synaptix/core/manager/log_manager.dart';
import 'package:synaptix/core/manager/service_manager.dart';
import 'package:synaptix/core/services/guest_session_store.dart';

/// Wipes ephemeral guest play data after an extended leave.
///
/// **Kept (so returning guests are not forced through setup again):**
/// - onboarding progress / completion flags
/// - profile prefs set during onboarding (name, age group, country, avatar, …)
/// - stable device id
///
/// **Cleared:** auth tokens, wallets/caches, session queues, synthetic local ids.
class GuestDataWiper {
  GuestDataWiper(this._serviceManager);

  final ServiceManager _serviceManager;

  /// Play / economy / queue boxes only — not settings or onboarding.
  static const List<String> _sessionScopedBoxes = <String>[
    'app_persistence',
    'cache',
    'store_cache',
    'wallet_data',
    'purchased_items',
    'referral_box',
    'offline_analytics_events',
    'analytics_session_data',
    'event_queue',
    'event_queue_metadata',
    'educational_stats',
    'profile_sync_queue',
    'store_data',
  ];

  Future<void> wipeAllGuestData() async {
    LogManager.info('[GuestDataWiper] Wiping guest play session data',
        source: 'GuestDataWiper');

    try {
      await _serviceManager.authTokenStore.clear();
    } catch (e) {
      LogManager.debug('[GuestDataWiper] authTokenStore.clear failed: $e');
    }

    try {
      await _serviceManager.secureChannelService.clearSession();
    } catch (e) {
      LogManager.debug('[GuestDataWiper] secureChannel clear failed: $e');
    }

    // Do NOT clearPlayerProfile / reset onboarding — prefs + setup stay.

    try {
      await _serviceManager.appCacheService.clearTemporaryData();
    } catch (e) {
      LogManager.debug('[GuestDataWiper] clearTemporaryData failed: $e');
    }

    try {
      await _serviceManager.secureStorage.setLoggedIn(false);
    } catch (e) {
      LogManager.debug('[GuestDataWiper] setLoggedIn(false) failed: $e');
    }

    // Drop synthetic identity so the next guest session re-resolves cleanly.
    // Device id is left intact. Onboarding/profile prefs remain in Hive settings.
    try {
      await _serviceManager.secureStorage.removeSecret('user_id');
      await _serviceManager.secureStorage
          .removeSecret('generated_local_user_id');
      await _serviceManager.secureStorage.removeSecret('user_email');
    } catch (e) {
      LogManager.debug('[GuestDataWiper] secret cleanup failed: $e');
    }

    for (final name in _sessionScopedBoxes) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).clear();
        } else if (await Hive.boxExists(name)) {
          final box = await Hive.openBox(name);
          await box.clear();
        }
      } catch (e) {
        LogManager.debug('[GuestDataWiper] box clear $name failed: $e');
      }
    }

    await GuestSessionStore.clearGuestSession();

    LogManager.info(
        '[GuestDataWiper] Guest play wipe complete (onboarding preserved)',
        source: 'GuestDataWiper');
  }
}
