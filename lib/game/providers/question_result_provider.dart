import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/question_result_service.dart';
import '../services/xp_service.dart';
import '../services/wallet_service.dart';

/// Provides the XP service instance
final xpServiceProvider = Provider((ref) {
  return XPService();
});

/// Provides the Wallet service instance
final walletServiceProvider = Provider((ref) {
  return WalletService();
});

/// Provides the Question Result service with dependencies injected
final questionResultServiceProvider = Provider((ref) {
  final xpService = ref.watch(xpServiceProvider);
  final walletService = ref.watch(walletServiceProvider);

  return QuestionResultService(
    xpService: xpService,
    walletService: walletService,
  );
});

/// Provides current player streak count
final playerStreakProvider = Provider((ref) {
  final resultService = ref.watch(questionResultServiceProvider);
  return resultService.streak;
});

/// Provides whether player has an active streak
final streakActiveProvider = Provider((ref) {
  final resultService = ref.watch(questionResultServiceProvider);
  return resultService.isStreakActive;
});
