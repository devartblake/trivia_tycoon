import 'package:hive/hive.dart';

/// SpinWheelSettingsService handles logic for storing and retrieving spin wheel-related data.
class SpinWheelSettingsService {
  static const _boxName = 'settings';

  static const String _winStreakKey = 'winStreak';
  static const String _totalSpinsKey = 'totalSpins';
  static const String _lastJackpotWinKey = 'lastJackpotWin';
  static const String _lastSegmentFetchTimeKey = 'lastSegmentFetchTime';

  /// Saves the last jackpot win timestamp.
  Future<void> setJackpotTime(DateTime time) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_lastJackpotWinKey, time.toIso8601String());
  }

  /// Retrieves the last jackpot win timestamp.
  Future<DateTime> getJackpotTime() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_lastJackpotWinKey);
    return raw != null ? DateTime.parse(raw) : DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Saves the current win streak.
  Future<void> setWinStreak(int streak) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_winStreakKey, streak);
  }

  /// Retrieves the current win streak.
  Future<int> getWinStreak() async {
    final box = await Hive.openBox(_boxName);
    return box.get(_winStreakKey, defaultValue: 0);
  }

  /// Saves the total number of spins.
  Future<void> setTotalSpins(int count) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_totalSpinsKey, count);
  }

  /// Retrieves the total number of spins.
  Future<int> getTotalSpins() async {
    final box = await Hive.openBox(_boxName);
    return box.get(_totalSpinsKey, defaultValue: 0);
  }

  /// Increments the total number of spins by 1.
  Future<void> incrementTotalSpins() async {
    final box = await Hive.openBox(_boxName);
    final current = box.get('_totalSpinsKey', defaultValue: 0);
    await box.put('_totalSpinsKey', current + 1);
  }

  /// Sets the segment fetch time for spin wheel caching.
  Future<void> setSegmentFetchTime(DateTime time) async {
    final box = await Hive.openBox(_boxName);
    await box.put('_lastSegmentFetchTimeKey', time.toIso8601String());
  }

  /// Retrieves the last segment fetch time.
  Future<DateTime?> getSegmentFetchTime() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_lastSegmentFetchTimeKey);
    return raw != null ? DateTime.tryParse(raw) : null;
  }
}
