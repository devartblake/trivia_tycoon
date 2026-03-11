import 'package:flutter/foundation.dart';

import '../manager/service_manager.dart';

class UserIdentityResolver {
  static bool _hasLoggedUnknownUserWarning = false;

  static Future<String> resolveUserId(ServiceManager serviceManager) async {
    final profileUserId = await serviceManager.playerProfileService.getUserId();
    if (profileUserId != null && profileUserId.isNotEmpty) {
      return profileUserId;
    }

    final secureUserId = await serviceManager.secureStorage.getSecret('user_id');
    if (secureUserId != null && secureUserId.isNotEmpty) {
      return secureUserId;
    }

    if (!_hasLoggedUnknownUserWarning) {
      _hasLoggedUnknownUserWarning = true;
      debugPrint('[UserIdentityResolver] Unable to resolve user_id; falling back to "unknown".');
    }

    return 'unknown';
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
