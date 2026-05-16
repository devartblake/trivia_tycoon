import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

/// Identifies a player authenticated via a native game platform.
///
/// On iOS this is Apple Game Center; on Android it is Google Play Games Services.
/// The [platform] field is `'ios'` or `'android'`.
class GamePlatformIdentity {
  final String platform;
  final String playerId;
  final String displayName;

  const GamePlatformIdentity({
    required this.platform,
    required this.playerId,
    required this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'playerId': playerId,
        'displayName': displayName,
      };
}

/// Wraps Apple Game Center (iOS) and Google Play Games Services (Android)
/// via the `games_services` Flutter plugin.
///
/// Web is not supported; all methods return null / false on web.
///
/// **Backend verification note:**
/// Both Game Center and Play Games identity verification requires the backend
/// to call platform-specific certificate/token validation APIs.  Coordinate
/// with your backend team to implement the `/auth/mobile-game-login` and
/// `/auth/link-game-account` endpoints documented in the auth service.
class GamePlatformAuthService {
  static const _iosPlatform = 'ios';
  static const _androidPlatform = 'android';

  /// Silently attempt to sign the user in to the native game platform.
  ///
  /// Returns a [GamePlatformIdentity] on success, or `null` if the user is not
  /// signed in to Game Center / Play Games, or if the platform is unsupported.
  Future<GamePlatformIdentity?> signInSilently() async {
    if (kIsWeb) return null;

    try {
      await GamesServices.signIn();

      final playerId = await GamesServices.getPlayerID() ?? '';
      final playerName = await GamesServices.getPlayerName() ?? '';

      if (playerId.isEmpty) return null;

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? _iosPlatform
          : _androidPlatform;

      return GamePlatformIdentity(
        platform: platform,
        playerId: playerId,
        displayName: playerName,
      );
    } catch (e) {
      debugPrint('[GamePlatformAuthService] silent sign-in failed: $e');
      return null;
    }
  }

  /// Returns `true` if the user is currently signed in to the game platform.
  Future<bool> isSignedIn() async {
    if (kIsWeb) return false;
    try {
      await GamesServices.signIn();
      final id = await GamesServices.getPlayerID();
      return id != null && id.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns the current platform label (`'ios'` or `'android'`).
  String get currentPlatform => defaultTargetPlatform == TargetPlatform.iOS
      ? _iosPlatform
      : _androidPlatform;
}
