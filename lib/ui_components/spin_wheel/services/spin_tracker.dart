import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';

/// Enhanced spin tracker with performance optimizations and better state management
class EnhancedSpinTracker {
  static const String _stateKey = 'spin_tracker_state';
  static const int _defaultMaxSpinsPerDay = 5;
  static const Duration _defaultCooldown = Duration(hours: 3);
  static const Duration _cacheTimeout = Duration(minutes: 1);

  // Cached state to avoid repeated database reads
  static SpinTrackerState? _cachedState;
  static DateTime? _lastCacheTime;
  static Timer? _cacheCleanupTimer;

  /// Get current spin tracker state with caching
  static Future<SpinTrackerState> _getState() async {
    // Check cache validity
    if (_cachedState != null && _lastCacheTime != null) {
      final cacheAge = DateTime.now().difference(_lastCacheTime!);
      if (cacheAge < _cacheTimeout) {
        return _cachedState!;
      }
    }

    // Load from storage
    try {
      final stateJson = await AppSettings.getString(_stateKey);
      if (stateJson != null && stateJson.isNotEmpty) {
        final decodedState = jsonDecode(stateJson);
        final loadedState = SpinTrackerState.fromJson(decodedState);

        // Validate and clean state
        final validatedState = _validateState(loadedState);
        _updateCache(validatedState);
        return validatedState;
      }
    } catch (e) {
      debugPrint('Failed to load spin tracker state: $e');
    }

    // Return default state
    final defaultState = SpinTrackerState.defaultState();
    _updateCache(defaultState);
    return defaultState;
  }

  /// Update cached state
  static void _updateCache(SpinTrackerState state) {
    _cachedState = state;
    _lastCacheTime = DateTime.now();

    // Schedule cache cleanup
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = Timer(_cacheTimeout, () {
      _cachedState = null;
      _lastCacheTime = null;
    });
  }

  /// Validate state integrity
  static SpinTrackerState _validateState(SpinTrackerState state) {
    final now = DateTime.now();

    // Reset daily count if it's a new day
    if (state.lastSpinTime != null) {
      final daysDifference = now.difference(state.lastSpinTime!).inDays;
      if (daysDifference >= 1) {
        return state.copyWith(
          dailyCount: 0,
          weeklyCount: daysDifference >= 7 ? 0 : state.weeklyCount,
        );
      }
    }

    // Validate daily count doesn't exceed reasonable limits
    final validDailyCount = state.dailyCount.clamp(0, state.maxSpinsPerDay * 2);

    if (validDailyCount != state.dailyCount) {
      return state.copyWith(dailyCount: validDailyCount);
    }

    return state;
  }

  /// Save state with batched writes
  static Timer? _saveTimer;
  static void _scheduleSave(SpinTrackerState state) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final stateJson = jsonEncode(state.toJson());
        await AppSettings.setString(_stateKey, stateJson);
      } catch (e) {
        debugPrint('Failed to save spin tracker state: $e');
      }
    });
  }

  /// Check if user can spin
  static Future<bool> canSpin() async {
    final state = await _getState();

    // Check daily limit
    if (state.dailyCount >= state.maxSpinsPerDay) return false;

    // Check cooldown
    if (state.lastSpinTime != null) {
      final timeSinceLastSpin = DateTime.now().difference(state.lastSpinTime!);
      if (timeSinceLastSpin < state.cooldownDuration) return false;
    }

    return true;
  }

  /// Register a spin with optimized state management
  static Future<void> registerSpin() async {
    final currentState = await _getState();
    final now = DateTime.now();

    // Determine if it's a new day
    bool isNewDay = false;
    if (currentState.lastSpinTime != null) {
      final lastSpinDate = DateTime(
        currentState.lastSpinTime!.year,
        currentState.lastSpinTime!.month,
        currentState.lastSpinTime!.day,
      );
      final currentDate = DateTime(now.year, now.month, now.day);
      isNewDay = currentDate.isAfter(lastSpinDate);
    }

    // Calculate new counts
    final newDailyCount = isNewDay ? 1 : currentState.dailyCount + 1;
    final newWeeklyCount = _shouldResetWeeklyCount(currentState.lastSpinTime, now)
        ? 1
        : currentState.weeklyCount + 1;
    final newTotalSpins = currentState.totalSpins + 1;

    // Create updated state
    final newState = currentState.copyWith(
      lastSpinTime: now,
      dailyCount: newDailyCount,
      weeklyCount: newWeeklyCount,
      totalSpins: newTotalSpins,
    );

    // Update cache and schedule save
    _updateCache(newState);
    _scheduleSave(newState);
  }

  /// Check if weekly count should reset
  static bool _shouldResetWeeklyCount(DateTime? lastSpin, DateTime now) {
    if (lastSpin == null) return false;

    // Calculate start of current week (Monday)
    final nowWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastSpinWeekStart = lastSpin.subtract(Duration(days: lastSpin.weekday - 1));

    return nowWeekStart.isAfter(lastSpinWeekStart);
  }

  /// Get time remaining until next spin
  static Future<Duration> timeLeft() async {
    final state = await _getState();

    if (state.lastSpinTime == null) return Duration.zero;

    final timeSinceLastSpin = DateTime.now().difference(state.lastSpinTime!);
    final remaining = state.cooldownDuration - timeSinceLastSpin;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get daily spin count
  static Future<int> getDailyCount() async {
    final state = await _getState();
    return state.dailyCount;
  }

  /// Get weekly spin count
  static Future<int> getWeeklyCount() async {
    final state = await _getState();
    return state.weeklyCount;
  }

  /// Get total spin count
  static Future<int> getTotalSpins() async {
    final state = await _getState();
    return state.totalSpins;
  }

  /// Get last spin time
  static Future<DateTime?> getLastSpinTime() async {
    final state = await _getState();
    return state.lastSpinTime;
  }

  /// Get maximum spins per day
  static Future<int> getMaxSpins() async {
    final state = await _getState();
    return state.maxSpinsPerDay;
  }

  /// Get cooldown duration
  static Future<Duration> getCooldown() async {
    final state = await _getState();
    return state.cooldownDuration;
  }

  /// Get comprehensive spin statistics
  static Future<SpinStatistics> getStatistics() async {
    final state = await _getState();
    final timeLeft = await SpinTracker.timeLeft();
    final canSpin = await SpinTracker.canSpin();

    return SpinStatistics(
      dailyCount: state.dailyCount,
      weeklyCount: state.weeklyCount,
      totalSpins: state.totalSpins,
      maxSpinsPerDay: state.maxSpinsPerDay,
      timeUntilNextSpin: timeLeft,
      canSpin: canSpin,
      lastSpinTime: state.lastSpinTime,
      cooldownDuration: state.cooldownDuration,
      spinsRemainingToday: (state.maxSpinsPerDay - state.dailyCount).clamp(0, state.maxSpinsPerDay),
    );
  }

  /// Update configuration (max spins, cooldown)
  static Future<void> updateConfiguration({
    int? maxSpinsPerDay,
    Duration? cooldownDuration,
  }) async {
    final currentState = await _getState();

    final newState = currentState.copyWith(
      maxSpinsPerDay: maxSpinsPerDay ?? currentState.maxSpinsPerDay,
      cooldownDuration: cooldownDuration ?? currentState.cooldownDuration,
    );

    _updateCache(newState);
    _scheduleSave(newState);
  }

  /// Reset daily count (for testing or admin purposes)
  static Future<void> resetDailyCount() async {
    final currentState = await _getState();
    final newState = currentState.copyWith(dailyCount: 0);

    _updateCache(newState);
    _scheduleSave(newState);
  }

  /// Reset all data
  static Future<void> resetAllData() async {
    final defaultState = SpinTrackerState.defaultState();
    _updateCache(defaultState);
    _scheduleSave(defaultState);
  }

  /// Get next spin availability time
  static Future<DateTime?> getNextSpinTime() async {
    final state = await _getState();

    if (state.lastSpinTime == null) return DateTime.now();

    final nextSpinTime = state.lastSpinTime!.add(state.cooldownDuration);
    return nextSpinTime.isAfter(DateTime.now()) ? nextSpinTime : DateTime.now();
  }

  /// Check if user has reached daily limit
  static Future<bool> hasReachedDailyLimit() async {
    final state = await _getState();
    return state.dailyCount >= state.maxSpinsPerDay;
  }

  /// Get spin frequency analysis
  static Future<SpinFrequencyAnalysis> getFrequencyAnalysis() async {
    final state = await _getState();
    final now = DateTime.now();

    // Calculate averages
    double dailyAverage = 0.0;
    double weeklyAverage = 0.0;

    if (state.lastSpinTime != null) {
      final daysSinceFirstSpin = now.difference(state.lastSpinTime!).inDays + 1;
      final weeksSinceFirstSpin = (daysSinceFirstSpin / 7).ceil();

      dailyAverage = state.totalSpins / daysSinceFirstSpin;
      weeklyAverage = state.totalSpins / weeksSinceFirstSpin;
    }

    return SpinFrequencyAnalysis(
      dailyAverage: dailyAverage,
      weeklyAverage: weeklyAverage,
      totalSpins: state.totalSpins,
      currentStreak: _calculateCurrentStreak(state),
      longestStreak: state.longestStreak,
    );
  }

  /// Calculate current spin streak
  static int _calculateCurrentStreak(SpinTrackerState state) {
    // This would require more detailed spin history
    // For now, return a simplified calculation
    return state.dailyCount > 0 ? 1 : 0;
  }

  /// Force cache refresh
  static void refreshCache() {
    _cachedState = null;
    _lastCacheTime = null;
    _cacheCleanupTimer?.cancel();
  }

  /// Cleanup resources
  static void dispose() {
    _saveTimer?.cancel();
    _cacheCleanupTimer?.cancel();
    _cachedState = null;
    _lastCacheTime = null;
  }
}

/// State model for spin tracker
@immutable
class SpinTrackerState {
  final DateTime? lastSpinTime;
  final int dailyCount;
  final int weeklyCount;
  final int totalSpins;
  final int maxSpinsPerDay;
  final Duration cooldownDuration;
  final int longestStreak;

  const SpinTrackerState({
    this.lastSpinTime,
    this.dailyCount = 0,
    this.weeklyCount = 0,
    this.totalSpins = 0,
    this.maxSpinsPerDay = 5,
    this.cooldownDuration = const Duration(hours: 3),
    this.longestStreak = 0,
  });

  SpinTrackerState copyWith({
    DateTime? lastSpinTime,
    int? dailyCount,
    int? weeklyCount,
    int? totalSpins,
    int? maxSpinsPerDay,
    Duration? cooldownDuration,
    int? longestStreak,
  }) {
    return SpinTrackerState(
      lastSpinTime: lastSpinTime ?? this.lastSpinTime,
      dailyCount: dailyCount ?? this.dailyCount,
      weeklyCount: weeklyCount ?? this.weeklyCount,
      totalSpins: totalSpins ?? this.totalSpins,
      maxSpinsPerDay: maxSpinsPerDay ?? this.maxSpinsPerDay,
      cooldownDuration: cooldownDuration ?? this.cooldownDuration,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }

  factory SpinTrackerState.defaultState() {
    return const SpinTrackerState();
  }

  Map<String, dynamic> toJson() {
    return {
      'lastSpinTime': lastSpinTime?.toIso8601String(),
      'dailyCount': dailyCount,
      'weeklyCount': weeklyCount,
      'totalSpins': totalSpins,
      'maxSpinsPerDay': maxSpinsPerDay,
      'cooldownDuration': cooldownDuration.inMilliseconds,
      'longestStreak': longestStreak,
    };
  }

  factory SpinTrackerState.fromJson(Map<String, dynamic> json) {
    return SpinTrackerState(
      lastSpinTime: json['lastSpinTime'] != null
          ? DateTime.parse(json['lastSpinTime'])
          : null,
      dailyCount: json['dailyCount'] ?? 0,
      weeklyCount: json['weeklyCount'] ?? 0,
      totalSpins: json['totalSpins'] ?? 0,
      maxSpinsPerDay: json['maxSpinsPerDay'] ?? 5,
      cooldownDuration: Duration(milliseconds: json['cooldownDuration'] ?? 10800000),
      longestStreak: json['longestStreak'] ?? 0,
    );
  }
}

/// Comprehensive spin statistics
@immutable
class SpinStatistics {
  final int dailyCount;
  final int weeklyCount;
  final int totalSpins;
  final int maxSpinsPerDay;
  final Duration timeUntilNextSpin;
  final bool canSpin;
  final DateTime? lastSpinTime;
  final Duration cooldownDuration;
  final int spinsRemainingToday;

  const SpinStatistics({
    required this.dailyCount,
    required this.weeklyCount,
    required this.totalSpins,
    required this.maxSpinsPerDay,
    required this.timeUntilNextSpin,
    required this.canSpin,
    this.lastSpinTime,
    required this.cooldownDuration,
    required this.spinsRemainingToday,
  });
}

/// Spin frequency analysis
@immutable
class SpinFrequencyAnalysis {
  final double dailyAverage;
  final double weeklyAverage;
  final int totalSpins;
  final int currentStreak;
  final int longestStreak;

  const SpinFrequencyAnalysis({
    required this.dailyAverage,
    required this.weeklyAverage,
    required this.totalSpins,
    required this.currentStreak,
    required this.longestStreak,
  });
}

/// Legacy compatibility wrapper
class SpinTracker {
  static Future<bool> canSpin() => EnhancedSpinTracker.canSpin();
  static Future<void> registerSpin() => EnhancedSpinTracker.registerSpin();
  static Future<Duration> timeLeft() => EnhancedSpinTracker.timeLeft();
  static Future<int> getDailyCount() => EnhancedSpinTracker.getDailyCount();
  static Future<DateTime?> getLastSpinTime() => EnhancedSpinTracker.getLastSpinTime();
  static Future<int> getMaxSpins() => EnhancedSpinTracker.getMaxSpins();

  // Legacy constants
  static const int maxSpinsPerDay = 5;
  static const Duration cooldown = Duration(hours: 3);
}