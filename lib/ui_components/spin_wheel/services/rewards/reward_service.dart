import 'dart:ui';
import '../../../../core/services/settings/app_settings.dart';
import 'reward_probability.dart';
import '../../models/wheel_segment.dart';

class RewardService {
  static Future<WheelSegment> generateReward() async {
    final userLevel = await AppSettings.getInt("userLevel") ?? 1;
    final exclusiveCurrency = await AppSettings.getInt("exclusiveCurrency") ?? 0;
    final winStreak = await AppSettings.getWinStreak();
    final lastJackpot = await AppSettings.getJackpotTime();

    final engine = RewardProbability()
      ..userLevel = userLevel
      ..exclusiveCurrency = exclusiveCurrency
      ..winStreak = winStreak
      ..recentlyWonJackpot = false
      ..lastJackpotWin = lastJackpot;

    final type = engine.spinWheel();
    final segment = _getPrizeByType(type);

    // Persist streak and jackpot data
    if (type == "jackpot") await AppSettings.setJackpotTime(DateTime.now());
    await AppSettings.setWinStreak(type == "nothing" ? 0 : winStreak + 1);
    await AppSettings.incrementTotalSpins();

    return segment;
  }

  Future<void> checkAndUnlockBadges() async {
    final spins = await AppSettings.getTotalSpins();
    final badges = <String>[];

    if (spins >= 10) badges.add("10-Spins");
    if (spins >= 50) badges.add("50-Spins");

    final winStreak = await AppSettings.getWinStreak();
    if (winStreak >= 5) badges.add("Streak-Champion");

    for (final b in badges) {
      await AppSettings.unlockBadge(b);
    }
  }

  static WheelSegment _getPrizeByType(String rewardType) {
    switch (rewardType) {
      case 'jackpot':
        return WheelSegment(label: "Ultimate Diamond", rewardType: "jackpot", reward: 500, imagePath: "assets/images/diamond.png", color: const Color(0xFF8E44AD));
      case 'large':
        return WheelSegment(label: "Gold Chest", rewardType: "large", reward: 250, imagePath: "assets/images/gold.png", color: const Color(0xFFF39C12));
      case 'medium':
        return WheelSegment(label: "Silver Crate", rewardType: "medium", reward: 100, imagePath: "assets/images/silver.png", color: const Color(0xFFBDC3C7));
      default:
        return WheelSegment(label: "Small Prize", rewardType: "small", reward: 50, imagePath: "assets/images/small.png", color: const Color(0xFF27AE60));
    }
  }
}
