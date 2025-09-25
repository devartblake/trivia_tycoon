import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/settings/app_settings.dart';
import '../models/spin_system_models.dart';

/// Enhanced spin history provider with caching and analytics
final spinHistoryProvider = AsyncNotifierProvider<EnhancedSpinHistoryNotifier, SpinHistoryState>(
  EnhancedSpinHistoryNotifier.new,
);

/// State model for spin history with analytics
@immutable
class SpinHistoryState {
  final List<SpinResult> entries;
  final SpinHistoryAnalytics analytics;
  final DateTime lastUpdated;
  final bool isLoading;

  const SpinHistoryState({
    this.entries = const [],
    this.analytics = const SpinHistoryAnalytics(),
    required this.lastUpdated,
    this.isLoading = false,
  });

  SpinHistoryState copyWith({
    List<SpinResult>? entries,
    SpinHistoryAnalytics? analytics,
    DateTime? lastUpdated,
    bool? isLoading,
  }) {
    return SpinHistoryState(
      entries: entries ?? this.entries,
      analytics: analytics ?? this.analytics,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((e) => e.toJson()).toList(),
      'analytics': analytics.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory SpinHistoryState.fromJson(Map<String, dynamic> json) {
    final entriesList = (json['entries'] as List<dynamic>?)
        ?.map((e) => SpinResult.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return SpinHistoryState(
      entries: entriesList,
      analytics: json['analytics'] != null
          ? SpinHistoryAnalytics.fromJson(json['analytics'])
          : SpinHistoryAnalytics.fromEntries(entriesList),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }
}

/// Analytics data for spin history
@immutable
class SpinHistoryAnalytics {
  final int totalSpins;
  final int totalRewards;
  final double averageReward;
  final String mostFrequentPrize;
  final String highestReward;
  final Map<String, int> rewardTypeDistribution;
  final Map<String, int> dailySpinCounts;
  final DateTime? firstSpin;
  final DateTime? lastSpin;
  final int currentStreak;
  final int longestStreak;

  const SpinHistoryAnalytics({
    this.totalSpins = 0,
    this.totalRewards = 0,
    this.averageReward = 0.0,
    this.mostFrequentPrize = 'N/A',
    this.highestReward = 'N/A',
    this.rewardTypeDistribution = const {},
    this.dailySpinCounts = const {},
    this.firstSpin,
    this.lastSpin,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  factory SpinHistoryAnalytics.fromEntries(List<SpinResult> entries) {
    if (entries.isEmpty) return const SpinHistoryAnalytics();

    // Sort entries by timestamp
    final sortedEntries = List<SpinResult>.from(entries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate basic stats
    final totalSpins = entries.length;
    final totalRewards = entries.fold<int>(0, (sum, entry) => sum + entry.reward);
    final averageReward = totalSpins > 0 ? totalRewards / totalSpins : 0.0;

    // Find most frequent prize
    final prizeFrequency = <String, int>{};
    for (final entry in entries) {
      prizeFrequency[entry.label] = (prizeFrequency[entry.label] ?? 0) + 1;
    }
    final mostFrequentPrize = prizeFrequency.isEmpty
        ? 'N/A'
        : prizeFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Find highest reward
    final highestRewardEntry = entries.isEmpty
        ? null
        : entries.reduce((a, b) => a.reward > b.reward ? a : b);
    final highestReward = highestRewardEntry?.label ?? 'N/A';

    // Calculate reward type distribution
    final rewardTypeDistribution = <String, int>{};
    for (final entry in entries) {
      final type = entry.rewardType ?? 'unknown';
      rewardTypeDistribution[type] = (rewardTypeDistribution[type] ?? 0) + 1;
    }

    // Calculate daily spin counts
    final dailySpinCounts = <String, int>{};
    for (final entry in entries) {
      final dateKey = entry.timestamp.toIso8601String().split('T')[0];
      dailySpinCounts[dateKey] = (dailySpinCounts[dateKey] ?? 0) + 1;
    }

    // Calculate streaks
    final streaks = _calculateStreaks(sortedEntries);

    return SpinHistoryAnalytics(
      totalSpins: totalSpins,
      totalRewards: totalRewards,
      averageReward: averageReward,
      mostFrequentPrize: mostFrequentPrize,
      highestReward: highestReward,
      rewardTypeDistribution: rewardTypeDistribution,
      dailySpinCounts: dailySpinCounts,
      firstSpin: sortedEntries.isNotEmpty ? sortedEntries.first.timestamp : null,
      lastSpin: sortedEntries.isNotEmpty ? sortedEntries.last.timestamp : null,
      currentStreak: streaks['current'] ?? 0,
      longestStreak: streaks['longest'] ?? 0,
    );
  }

  static Map<String, int> _calculateStreaks(List<SpinResult> sortedEntries) {
    if (sortedEntries.isEmpty) return {'current': 0, 'longest': 0};

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastSpinDate;

    for (final entry in sortedEntries.reversed) {
      final spinDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );

      if (lastSpinDate == null) {
        tempStreak = 1;
        currentStreak = 1;
      } else {
        final daysDifference = lastSpinDate.difference(spinDate).inDays;
        if (daysDifference == 1) {
          tempStreak++;
          if (entry == sortedEntries.last) currentStreak = tempStreak;
        } else if (daysDifference > 1) {
          longestStreak = math.max(longestStreak, tempStreak);
          tempStreak = 1;
          if (entry == sortedEntries.last) currentStreak = 0;
        }
      }

      lastSpinDate = spinDate;
    }

    longestStreak = math.max(longestStreak, tempStreak);

    return {'current': currentStreak, 'longest': longestStreak};
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSpins': totalSpins,
      'totalRewards': totalRewards,
      'averageReward': averageReward,
      'mostFrequentPrize': mostFrequentPrize,
      'highestReward': highestReward,
      'rewardTypeDistribution': rewardTypeDistribution,
      'dailySpinCounts': dailySpinCounts,
      'firstSpin': firstSpin?.toIso8601String(),
      'lastSpin': lastSpin?.toIso8601String(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  factory SpinHistoryAnalytics.fromJson(Map<String, dynamic> json) {
    return SpinHistoryAnalytics(
      totalSpins: json['totalSpins'] ?? 0,
      totalRewards: json['totalRewards'] ?? 0,
      averageReward: (json['averageReward'] ?? 0.0).toDouble(),
      mostFrequentPrize: json['mostFrequentPrize'] ?? 'N/A',
      highestReward: json['highestReward'] ?? 'N/A',
      rewardTypeDistribution: Map<String, int>.from(json['rewardTypeDistribution'] ?? {}),
      dailySpinCounts: Map<String, int>.from(json['dailySpinCounts'] ?? {}),
      firstSpin: json['firstSpin'] != null ? DateTime.parse(json['firstSpin']) : null,
      lastSpin: json['lastSpin'] != null ? DateTime.parse(json['lastSpin']) : null,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
    );
  }
}

class EnhancedSpinHistoryNotifier extends AsyncNotifier<SpinHistoryState> {
  static const String _historyKey = 'enhanced_spin_history';
  static const String _analyticsKey = 'spin_history_analytics';
  static const int _maxEntries = 100;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  // Performance optimizations
  Timer? _saveTimer;
  SpinHistoryState? _cachedState;
  DateTime? _lastCacheTime;

  @override
  Future<SpinHistoryState> build() async {
    return await _loadHistoryState();
  }

  /// Load history state with caching
  Future<SpinHistoryState> _loadHistoryState() async {
    try {
      // Check cache first
      if (_cachedState != null && _lastCacheTime != null) {
        final cacheAge = DateTime.now().difference(_lastCacheTime!);
        if (cacheAge < _cacheTimeout) {
          return _cachedState!;
        }
      }

      // Load from storage
      final historyJson = await AppSettings.getString(_historyKey);
      if (historyJson == null || historyJson.isEmpty) {
        final emptyState = SpinHistoryState(lastUpdated: DateTime.now());
        _updateCache(emptyState);
        return emptyState;
      }

      final decodedHistory = jsonDecode(historyJson);
      final loadedState = SpinHistoryState.fromJson(decodedHistory);

      // Validate and clean data
      final validatedState = _validateAndCleanState(loadedState);
      _updateCache(validatedState);

      return validatedState;
    } catch (e) {
      debugPrint('Failed to load spin history: $e');
      final fallbackState = SpinHistoryState(lastUpdated: DateTime.now());
      _updateCache(fallbackState);
      return fallbackState;
    }
  }

  /// Update cache with timestamp
  void _updateCache(SpinHistoryState newState) {
    _cachedState = newState;
    _lastCacheTime = DateTime.now();
  }

  /// Validate and clean loaded state
  SpinHistoryState _validateAndCleanState(SpinHistoryState state) {
    // Remove entries older than 90 days and limit to max entries
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    final validEntries = state.entries
        .where((entry) => entry.timestamp.isAfter(cutoffDate))
        .take(_maxEntries)
        .toList();

    // Recalculate analytics if entries changed
    if (validEntries.length != state.entries.length) {
      final newAnalytics = SpinHistoryAnalytics.fromEntries(validEntries);
      return state.copyWith(
        entries: validEntries,
        analytics: newAnalytics,
        lastUpdated: DateTime.now(),
      );
    }

    return state;
  }

  /// Add new spin result with batched saving
  Future<void> addResult(SpinResult result) async {
    try {
      final currentState = await future;

      // Add new result and maintain order
      final updatedEntries = [result, ...currentState.entries]
          .take(_maxEntries)
          .toList();

      // Recalculate analytics
      final newAnalytics = SpinHistoryAnalytics.fromEntries(updatedEntries);

      final newState = currentState.copyWith(
        entries: updatedEntries,
        analytics: newAnalytics,
        lastUpdated: DateTime.now(),
      );

      // Update state immediately
      state = AsyncData(newState);
      _updateCache(newState);

      // Schedule batched save
      _scheduleSave(newState);
    } catch (e) {
      debugPrint('Failed to add spin result: $e');
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Schedule batched save to reduce I/O operations
  void _scheduleSave(SpinHistoryState stateToSave) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      await _saveState(stateToSave);
    });
  }

  /// Save state to storage
  Future<void> _saveState(SpinHistoryState stateToSave) async {
    try {
      final stateJson = jsonEncode(stateToSave.toJson());
      await AppSettings.setString(_historyKey, stateJson);
    } catch (e) {
      debugPrint('Failed to save spin history: $e');
    }
  }

  /// Add multiple results efficiently
  Future<void> addResults(List<SpinResult> results) async {
    if (results.isEmpty) return;

    try {
      final currentState = await future;

      // Merge and sort results
      final allEntries = [...results, ...currentState.entries];
      allEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final updatedEntries = allEntries.take(_maxEntries).toList();
      final newAnalytics = SpinHistoryAnalytics.fromEntries(updatedEntries);

      final newState = currentState.copyWith(
        entries: updatedEntries,
        analytics: newAnalytics,
        lastUpdated: DateTime.now(),
      );

      state = AsyncData(newState);
      _updateCache(newState);
      _scheduleSave(newState);
    } catch (e) {
      debugPrint('Failed to add multiple results: $e');
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Clear all history
  Future<void> clear() async {
    try {
      final emptyState = SpinHistoryState(lastUpdated: DateTime.now());
      state = AsyncData(emptyState);
      _updateCache(emptyState);

      await AppSettings.remove(_historyKey);
      await AppSettings.remove(_analyticsKey);
    } catch (e) {
      debugPrint('Failed to clear spin history: $e');
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Filter results by date range
  List<SpinResult> filterByDateRange(DateTime start, DateTime end) {
    final currentState = state.value;
    if (currentState == null) return [];

    return currentState.entries
        .where((entry) =>
    entry.timestamp.isAfter(start) &&
        entry.timestamp.isBefore(end))
        .toList();
  }

  /// Filter by reward type
  List<SpinResult> filterByRewardType(String rewardType) {
    final currentState = state.value;
    if (currentState == null) return [];

    return currentState.entries
        .where((entry) => entry.rewardType == rewardType)
        .toList();
  }

  /// Filter by minimum reward value
  List<SpinResult> filterByMinReward(int minReward) {
    final currentState = state.value;
    if (currentState == null) return [];

    return currentState.entries
        .where((entry) => entry.reward >= minReward)
        .toList();
  }

  /// Get results from last N days
  List<SpinResult> getRecentResults(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return filterByDateRange(cutoffDate, DateTime.now());
  }

  /// Get today's results
  List<SpinResult> getTodayResults() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return filterByDateRange(startOfDay, endOfDay);
  }

  /// Export history data
  Map<String, dynamic> exportData() {
    final currentState = state.value;
    if (currentState == null) return {};

    return {
      ...currentState.toJson(),
      'exported': DateTime.now().toIso8601String(),
      'version': '2.0',
    };
  }

  /// Import history data
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      final importedState = SpinHistoryState.fromJson(data);
      final validatedState = _validateAndCleanState(importedState);

      state = AsyncData(validatedState);
      _updateCache(validatedState);
      await _saveState(validatedState);
    } catch (e) {
      debugPrint('Failed to import history data: $e');
      throw Exception('Invalid history data format');
    }
  }

  /// Force refresh from storage
  Future<void> refresh() async {
    _cachedState = null;
    _lastCacheTime = null;
    state = const AsyncLoading();
    state = AsyncData(await _loadHistoryState());
  }

  /// Clean up resources when the notifier is no longer needed
  void cleanup() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _cachedState = null;
    _lastCacheTime = null;
  }
}

/// Convenience providers for specific data
final spinHistoryEntriesProvider = Provider<List<SpinResult>>((ref) {
  final historyState = ref.watch(spinHistoryProvider);
  return historyState.when(
    data: (state) => state.entries,
    loading: () => [],
    error: (_, __) => [],
  );
});

final spinHistoryAnalyticsProvider = Provider<SpinHistoryAnalytics>((ref) {
  final historyState = ref.watch(spinHistoryProvider);
  return historyState.when(
    data: (state) => state.analytics,
    loading: () => const SpinHistoryAnalytics(),
    error: (_, __) => const SpinHistoryAnalytics(),
  );
});

final todaySpinCountProvider = Provider<int>((ref) {
  final notifier = ref.read(spinHistoryProvider.notifier);
  return notifier.getTodayResults().length;
});

final currentStreakProvider = Provider<int>((ref) {
  final analytics = ref.watch(spinHistoryAnalyticsProvider);
  return analytics.currentStreak;
});

final totalRewardsProvider = Provider<int>((ref) {
  final analytics = ref.watch(spinHistoryAnalyticsProvider);
  return analytics.totalRewards;
});