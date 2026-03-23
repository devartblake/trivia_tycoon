import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../manager/service_manager.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class UserIdentityResolver {
  static bool _hasLoggedUnknownUserWarning = false;
  static const String _generatedLocalUserIdKey = 'generated_local_user_id';

  @visibleForTesting
  static void resetWarningForTests() {
    _hasLoggedUnknownUserWarning = false;
  }

  static Future<String> resolveUserId(ServiceManager serviceManager) async {
    return resolveUserIdFromSources(
      getProfileUserId: () => serviceManager.playerProfileService.getUserId(),
      saveProfileUserId: (id) => serviceManager.playerProfileService.saveUserId(id),
      getSecureSecret: (key) => serviceManager.secureStorage.getSecret(key),
      setSecureSecret: (key, value) => serviceManager.secureStorage.setSecret(key, value),
      readAuthTokenStoreUserId: () {
        if (Hive.isBoxOpen('auth_tokens')) {
          final authBox = Hive.box('auth_tokens');
          return authBox.get('auth_user_id') as String?;
        }
        return null;
      },
      seedNowIso: () => DateTime.now().toIso8601String(),
      onCanonicalPromotion: (previousId, canonicalId) async {
        try {
          await serviceManager.analyticsService.trackEvent(
            'identity_user_id_promoted',
            {
              'previous_user_id': previousId,
              'new_user_id': canonicalId,
              'timestamp': DateTime.now().toIso8601String(),
              'source': 'user_identity_resolver',
            },
          );
        } catch (_) {
          // Best effort only: identity resolution should not fail due to telemetry.
        }
      },
      onResolutionSource: (source, userId) async {
        try {
          await serviceManager.analyticsService.trackEvent(
            'identity_user_id_resolved',
            {
              'identity_source': source,
              'user_id_source': source,
              'user_id': userId,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        } catch (_) {
          // Best effort only.
        }
      },
      onGeneratedFallback: (generatedUserId) async {
        try {
          await serviceManager.analyticsService.trackEvent(
            'identity_user_id_generated_local',
            {
              'user_id': generatedUserId,
              'timestamp': DateTime.now().toIso8601String(),
              'source': 'user_identity_resolver',
            },
          );
        } catch (_) {
          // Best effort only.
        }
      },
    );
  }

  @visibleForTesting
  static Future<String> resolveUserIdFromSources({
    required Future<String?> Function() getProfileUserId,
    required Future<void> Function(String userId) saveProfileUserId,
    required Future<String?> Function(String key) getSecureSecret,
    required Future<void> Function(String key, String value) setSecureSecret,
    required String? Function() readAuthTokenStoreUserId,
    required String Function() seedNowIso,
    Future<void> Function(String previousId, String canonicalId)? onCanonicalPromotion,
    Future<void> Function(String source, String userId)? onResolutionSource,
    Future<void> Function(String generatedUserId)? onGeneratedFallback,
  }) async {
    // Load known sources
    final profileUserId = await getProfileUserId();
    final secureUserId = await getSecureSecret('user_id');
    String? tokenStoreUserId;
    try {
      tokenStoreUserId = readAuthTokenStoreUserId();
    } catch (_) {
      // ignore - best effort only
    }

    // Prefer canonical backend IDs over generated local IDs.
    final canonical = _firstNonEmptyCanonical(
      [profileUserId, secureUserId, tokenStoreUserId],
    );

    if (canonical != null) {
      final previous = _firstNonEmpty([profileUserId, secureUserId]);
      if (previous != null && previous != canonical && _isGeneratedLocalId(previous)) {
        await onCanonicalPromotion?.call(previous, canonical);
      }

      await setSecureSecret('user_id', canonical);
      await saveProfileUserId(canonical);
      await onResolutionSource?.call(
        _canonicalSource(profileUserId, secureUserId, tokenStoreUserId, canonical),
        canonical,
      );
      return canonical;
    }

    // Fall back to existing generated/local IDs in known sources.
    final existingLocal = _firstNonEmpty(
      [profileUserId, secureUserId],
    );
    if (existingLocal != null) {
      await setSecureSecret('user_id', existingLocal);
      await saveProfileUserId(existingLocal);
      await onResolutionSource?.call(
        _existingLocalSource(profileUserId, secureUserId),
        existingLocal,
      );
      return existingLocal;
    }

    // Stable generated local fallback when backend id is unavailable.
    final existingGenerated = await getSecureSecret(_generatedLocalUserIdKey);
    if (existingGenerated != null && existingGenerated.isNotEmpty) {
      await saveProfileUserId(existingGenerated);
      await onResolutionSource?.call('generated_local', existingGenerated);
      return existingGenerated;
    }

    final seedEmail = await getSecureSecret('user_email');
    final seed = (seedEmail != null && seedEmail.isNotEmpty)
        ? seedEmail.toLowerCase()
        : seedNowIso();
    final generatedLocalUserId = 'local_${const Uuid().v5(Uuid.NAMESPACE_URL, seed)}';

    await setSecureSecret(_generatedLocalUserIdKey, generatedLocalUserId);
    await saveProfileUserId(generatedLocalUserId);
    await onGeneratedFallback?.call(generatedLocalUserId);
    await onResolutionSource?.call('generated_local', generatedLocalUserId);

    if (!_hasLoggedUnknownUserWarning) {
      _hasLoggedUnknownUserWarning = true;
      LogManager.debug(
          '[UserIdentityResolver] Backend user_id unavailable; using generated local id.');
    }

    return generatedLocalUserId;
  }

  static String? _firstNonEmptyCanonical(List<String?> ids) {
    for (final id in ids) {
      if (id != null && id.isNotEmpty && !_isGeneratedLocalId(id)) {
        return id;
      }
    }
    return null;
  }

  static String? _firstNonEmpty(List<String?> ids) {
    for (final id in ids) {
      if (id != null && id.isNotEmpty) {
        return id;
      }
    }
    return null;
  }

  static bool _isGeneratedLocalId(String id) => id.startsWith('local_');

  static String _canonicalSource(
    String? profileUserId,
    String? secureUserId,
    String? tokenStoreUserId,
    String canonical,
  ) {
    if (profileUserId == canonical && !_isGeneratedLocalId(profileUserId!)) {
      return 'profile';
    }
    if (secureUserId == canonical && !_isGeneratedLocalId(secureUserId!)) {
      return 'secure';
    }
    if (tokenStoreUserId == canonical && !_isGeneratedLocalId(tokenStoreUserId!)) {
      return 'token_store';
    }
    return 'token_store';
  }

  static String _existingLocalSource(String? profileUserId, String? secureUserId) {
    if (profileUserId != null && profileUserId.isNotEmpty) {
      return 'profile';
    }
    if (secureUserId != null && secureUserId.isNotEmpty) {
      return 'secure';
    }
    return 'generated_local';
  }

  static Future<String> resolveUserName(ServiceManager serviceManager) async {
    final username = await serviceManager.playerProfileService.getUsername();
    final playerName = await serviceManager.playerProfileService.getPlayerName();
    return resolveUserNameFromValues(username: username, playerName: playerName);
  }

  @visibleForTesting
  static String resolveUserNameFromValues({
    required String? username,
    required String playerName,
  }) {
    if (username != null && username.trim().isNotEmpty) {
      return username.trim().toLowerCase();
    }

    if (playerName.isNotEmpty && playerName != 'Player') {
      return playerName;
    }

    // Final fallback: derive a stable lowercase username-like label.
    final generated = playerName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return generated.isNotEmpty ? generated : 'unknown_user';
  }
}
