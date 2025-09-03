import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../models/prize_entry.dart';
import '../models/wheel_segment.dart';
import '../models/spin_result.dart';
import '../ui/widgets/result_dialog.dart';
import '../services/spin_tracker.dart';
import '../services/prize_log_provider.dart';
import '../services/rewards/reward_probability.dart';

final spinningControllerProvider = ChangeNotifierProvider<SpinningController>((ref) {
  return SpinningController(ref);
});

class SpinningController extends ChangeNotifier {
  final Ref ref;
  final Random _random = Random();
  bool isSpinning = false;
  WheelSegment? lastResult;

  SpinningController(this.ref);

  /// Util to define fixed reward types (loosely coupled logic)
  WheelSegment getRewardByType(String rewardType) {
    switch (rewardType) {
      case 'jackpot':
        return WheelSegment(label: "Ultimate Diamond", rewardType: "jackpot", reward: 500, imagePath: "assets/images/diamond.png", color: Colors.purple);
      case 'large':
        return WheelSegment(label: "Gold Chest", rewardType: "large", reward: 250, imagePath: "assets/images/gold.png", color: Colors.orange);
      case 'medium':
        return WheelSegment(label: "Silver Crate", rewardType: "medium", reward: 100, imagePath: "assets/images/silver.png", color: Colors.grey);
      default:
        return WheelSegment(label: "Small Prize", rewardType: "small", reward: 50, imagePath: "assets/images/small.png", color: Colors.green);
    }
  }

  /// Main spin function with loosely coupled reward logic.
  Future<void> spin(List<WheelSegment> segments, BuildContext context) async {
    if (isSpinning) return;
    isSpinning = true;
    notifyListeners();

    final prefs = ref.read(appCacheServiceProvider);
    final spinTracker = SpinTracker();

    // Check cooldown and limit
    if (await SpinTracker.canSpin()) {
      // Optionally show cooldown message
      isSpinning = false;
      notifyListeners();
      return;
    }

    // Visual spin result only
    final visualResult = segments[_random.nextInt(segments.length)];
    lastResult = visualResult;
    notifyListeners();

    // Simulate spin duration
    await Future.delayed(const Duration(seconds: 2));
    SpinTracker.registerSpin();

    // --- Reward Calculation (Loosely Coupled) ---
    final userLevel = await AppSettings.getInt("userLevel") ?? 1;
    final exclusiveCurrency = await AppSettings.getInt(
        "exclusiveCurrency") ?? 0;
    final winStreak = await AppSettings.getWinStreak();
    final lastJackpot = await AppSettings.getJackpotTime();

    final rewardEngine = RewardProbability()
      ..userLevel = userLevel
      ..exclusiveCurrency = exclusiveCurrency
      ..winStreak = winStreak
      ..recentlyWonJackpot = false
      ..lastJackpotWin = lastJackpot;

    final rewardType = rewardEngine.spinWheel();
    final prize = getRewardByType(rewardType);

    // Handle win streak updates
    if (rewardType == "jackpot") {
      await AppSettings.setJackpotTime(DateTime.now());
    }

    await AppSettings.setWinStreak(rewardType == "nothing" ? 0 : winStreak + 1);

    // Save to prize log
    PrizeLogNotifier().addEntry(PrizeEntry(prize: prize.label, timestamp: DateTime.now()));

    // Update coins with animation
    ref.read(coinNotifierProvider).add(prize.reward);

    // Trigger confetti
    ref.read(confettiControllerProvider).play();

    isSpinning = false;
    notifyListeners();

    // Guarded dialog display after async gap
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => ResultDialog(
          result: SpinResult(
            label: prize.label,
            imagePath: prize.imagePath,
            reward: prize.reward,
            timestamp: DateTime.now(),
          ),
        ),
      );
    }
  }
}