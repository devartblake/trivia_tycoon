import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/xp_service.dart';
import 'core_providers.dart';

final xpServiceProvider = Provider<XPService>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  return XPService(storage: storage);
});

final playerXPProvider = StateProvider<int>((ref) {
  final xpService = ref.read(xpServiceProvider);
  return xpService.playerXP;
});

/// Canonical XP write path (used by Arcade, Trivia, Missions, etc.)
void incrementXP(WidgetRef ref, int amount) {
  if (amount <= 0) return;

  final xpService = ref.read(xpServiceProvider);
  xpService.addXP(amount);

  ref.read(playerXPProvider.notifier).state = xpService.playerXP;
}
