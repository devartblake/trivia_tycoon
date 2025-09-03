import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/xp_service.dart';

final xpServiceProvider = Provider<XPService>((ref) => XPService());

final playerXPProvider = StateProvider<int>((ref) {
  final xpService = ref.read(xpServiceProvider);
  return xpService.playerXP;
});

void incrementXP(WidgetRef ref, int amount) {
  final xpService = ref.read(xpServiceProvider);
  xpService.addXP(amount);
  ref.read(playerXPProvider.notifier).state = xpService.playerXP;
}
