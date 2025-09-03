import 'dart:async';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';

class SpinTracker {
  static const String _lastSpinKey = 'lastSpinTime';
  static const String _dailyCountKey = 'dailySpinCount';
  static const int maxSpinsPerDay = 5;
  static const Duration cooldown = Duration(hours: 3);

  static Future<DateTime?> getLastSpinTime() async {
    return await AppSettings.getDateTime(_lastSpinKey);
  }

  static Future<int> getDailyCount() async {
    return await AppSettings.getInt(_dailyCountKey);
  }

  static Future<bool> canSpin() async {
    final count = await getDailyCount();
    final lastSpin = await getLastSpinTime();

    if (count >= maxSpinsPerDay) return false;
    if (lastSpin == null) return true;

    return DateTime.now().difference(lastSpin) >= cooldown;
  }

  static Future<void> registerSpin() async {
    final now = DateTime.now();
    final last = await getLastSpinTime();
    int count = await getDailyCount();

    if (last != null && last.day != now.day) {
      count = 1;
    } else {
      count++;
    }

    await AppSettings.setInt(_dailyCountKey, count);
    await AppSettings.setDateTime(_lastSpinKey, now);
  }

  static Future<Duration> timeLeft() async {
    final lastSpin = await getLastSpinTime();
    if (lastSpin == null) return Duration.zero;

    final remaining = cooldown - DateTime.now().difference(lastSpin);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static int getMaxSpins() => maxSpinsPerDay;
}
