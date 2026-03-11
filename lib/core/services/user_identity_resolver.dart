import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../manager/service_manager.dart';

class UserIdentityResolver {
  static bool _hasLoggedUnknownUserWarning = false;
  static const String _generatedLocalUserIdKey = 'generated_local_user_id';

  static Future<String> resolveUserId(ServiceManager serviceManager) async {
    // 1) Profile service (preferred app-level identity)
    final profileUserId = await serviceManager.playerProfileService.getUserId();
    if (profileUserId != null && profileUserId.isNotEmpty) {
      return profileUserId;
    }

    // 2) Secure storage session id (set during login flows)
    final secureUserId = await serviceManager.secureStorage.getSecret('user_id');
    if (secureUserId != null && secureUserId.isNotEmpty) {
      await serviceManager.playerProfileService.saveUserId(secureUserId);
      return secureUserId;
    }

    // 3) Core auth token storage fallback (auth_tokens Hive box)
    String? tokenStoreUserId;
    try {
      if (Hive.isBoxOpen('auth_tokens')) {
        final authBox = Hive.box('auth_tokens');
        tokenStoreUserId = authBox.get('auth_user_id') as String?;
      }
    } catch (_) {
      // ignore - best effort only
    }

    if (tokenStoreUserId != null && tokenStoreUserId.isNotEmpty) {
      await serviceManager.secureStorage.setSecret('user_id', tokenStoreUserId);
      await serviceManager.playerProfileService.saveUserId(tokenStoreUserId);
      return tokenStoreUserId;
    }

    // 4) Stable generated local fallback when backend id is unavailable.
    final existingGenerated =
        await serviceManager.secureStorage.getSecret(_generatedLocalUserIdKey);
    if (existingGenerated != null && existingGenerated.isNotEmpty) {
      await serviceManager.playerProfileService.saveUserId(existingGenerated);
      return existingGenerated;
    }

    final seedEmail = await serviceManager.secureStorage.getSecret('user_email');
    final seed = (seedEmail != null && seedEmail.isNotEmpty)
        ? seedEmail.toLowerCase()
        : DateTime.now().toIso8601String();
    final generatedLocalUserId = 'local_${const Uuid().v5(Uuid.NAMESPACE_URL, seed)}';

    await serviceManager.secureStorage
        .setSecret(_generatedLocalUserIdKey, generatedLocalUserId);
    await serviceManager.playerProfileService.saveUserId(generatedLocalUserId);

    if (!_hasLoggedUnknownUserWarning) {
      _hasLoggedUnknownUserWarning = true;
      debugPrint(
          '[UserIdentityResolver] Backend user_id unavailable; using generated local id.');
    }

    return generatedLocalUserId;
  }

  static Future<String> resolveUserName(ServiceManager serviceManager) async {
    final username = await serviceManager.playerProfileService.getUsername();
    if (username != null && username.trim().isNotEmpty) {
      return username.trim().toLowerCase();
    }

    final userName = await serviceManager.playerProfileService.getPlayerName();
    if (userName.isNotEmpty && userName != 'Player') {
      return userName;
    }

    // Final fallback: derive a stable lowercase username-like label.
    final generated = userName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return generated.isNotEmpty ? generated : 'unknown_user';
  }
}
