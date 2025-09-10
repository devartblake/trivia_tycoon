import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';

/// River-pod providers
final profileServiceProvider = Provider<ProfileService>((ref) {
  // TODO: replace these with your real auth/user source
  // TODO: actual implementation: final auth = ref.watch(authServiceProvider);
  const playerId = 'local-guest';
  const displayName = 'Guest';

  return ProfileService(
    ref,
    playerId: playerId, // TODO: auth.userId,
    displayName: displayName, // TODO: auth.displayName ?? 'player',
  );
});

