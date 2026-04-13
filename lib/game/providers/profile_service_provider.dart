import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../services/profile_service.dart';
import 'auth_providers.dart';

/// Provides a [ProfileService] wired to the current authenticated user.
///
/// Watches [isLoggedInSyncProvider] so it rebuilds automatically when the
/// user logs in or out. Identity is read synchronously from the already-open
/// Hive 'settings' box (guaranteed open by AppInit before providers are used).
final profileServiceProvider = Provider<ProfileService>((ref) {
  // Rebuild this provider whenever auth state changes.
  ref.watch(isLoggedInSyncProvider);

  // Sync-read identity from the Hive settings box opened during AppInit.
  String playerId = 'local-guest';
  String displayName = 'Guest';

  if (Hive.isBoxOpen('settings')) {
    final box = Hive.box('settings');
    final storedId = box.get('userId') as String?;
    final storedName = box.get('playerName') as String?;
    if (storedId != null && storedId.isNotEmpty) playerId = storedId;
    if (storedName != null && storedName.isNotEmpty) displayName = storedName;
  }

  return ProfileService(
    ref,
    playerId: playerId,
    displayName: displayName,
  );
});
