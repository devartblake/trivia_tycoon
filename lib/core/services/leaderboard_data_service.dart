import 'dart:convert';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'package:flutter/material.dart';
import '../../game/models/leaderboard_entry.dart';
import '../../game/services/leaderboard_service.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';

class LeaderboardDataService {
  final ApiService apiService;
  late AppCacheService appCache;
  final Future<List<LeaderboardEntry>> Function()? assetLoader;

  // Cache and refresh settings
  static const Duration _refreshInterval = Duration(minutes: 5);
  static const Duration _forceRefreshInterval = Duration(minutes: 30);
  static const String _lastRefreshKey = 'leaderboard_last_refresh';
  static const String _lastForceRefreshKey = 'leaderboard_last_force_refresh';
  static const String _refreshFailureCountKey = 'leaderboard_refresh_failures';

  DateTime? _lastRefreshTime;
  bool _isRefreshing = false;

  LeaderboardDataService({required this.apiService, this.assetLoader});

  Future<List<LeaderboardEntry>> loadLeaderboard() async {
    // Check if we need to refresh data first
    if (await _shouldRefreshData()) {
      await refreshData();
    }

    // 1. Try loading from asset loader if provided (Riverpod-based)
    try {
      final jsonStr = await rootBundle.loadString('assets/data/leaderboard/leaderboard.json');
      debugPrint("✅ Loaded JSON content: ${jsonStr.substring(0, 100)}...");
      if (assetLoader != null) {
        final assetData = await assetLoader!();
        if (assetData.isNotEmpty) return assetData;
      }
    } catch (e) {
      debugPrint("📄 Asset loader failed: $e");
    }

    // 2. Try local cache first for better performance
    try {
      final cached = await appCache.getCachedLeaderboard();
      if (cached.isNotEmpty) {
        debugPrint("💾 Loaded ${cached.length} entries from cache");
        return cached;
      }
    } catch (e) {
      debugPrint("💾 Hive cache failed: $e");
    }

    // 3. Try API as fallback
    try {
      final remote = await LeaderboardService(apiService: apiService).fetchLeaderboard();
      await appCache.cacheLeaderboard(remote);
      await _updateLastRefresh();
      debugPrint("🌐 Loaded ${remote.length} entries from API");
      return remote;
    } catch (e) {
      debugPrint("🌐 API load failed: $e");
      await _incrementRefreshFailureCount();
    }

    return [];
  }

  List<LeaderboardEntry> _parseLeaderboardJson(String jsonStr) {
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((e) => LeaderboardEntry.fromJson(e)).toList();
    } catch (e) {
      debugPrint("❌ Failed to parse leaderboard JSON: $e");
      return [];
    }
  }

  Future<void> submitScore(String playerName, int score) async {
    try {
      await LeaderboardService(
        apiService: apiService,
      ).submitScore(playerName, score);

      // Force a refresh after successful score submission
      await refreshData(force: true);
      debugPrint('✅ Score submitted successfully for $playerName: $score');
    } catch (e) {
      debugPrint('⚠️ Failed to submit score: $e');

      // Store failed submission for retry later
      await _storePendingSubmission(playerName, score);
      rethrow;
    }
  }

  /// Stores a pending score submission for retry later
  Future<void> _storePendingSubmission(String playerName, int score) async {
    try {
      final pendingSubmissions = await _getPendingSubmissions();
      pendingSubmissions.add({
        'playerName': playerName,
        'score': score,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await appCache.set('pending_submissions', pendingSubmissions);
      debugPrint('💾 Stored pending submission for retry: $playerName - $score');
    } catch (e) {
      debugPrint('❌ Failed to store pending submission: $e');
    }
  }

  /// Gets pending score submissions
  Future<List<Map<String, dynamic>>> _getPendingSubmissions() async {
    try {
      final raw = appCache.get<List<dynamic>>('pending_submissions') ?? [];
      return raw.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get pending submissions: $e');
      return [];
    }
  }

  /// Retries pending score submissions
  Future<void> retryPendingSubmissions() async {
    try {
      final pendingSubmissions = await _getPendingSubmissions();
      if (pendingSubmissions.isEmpty) return;

      final successfulSubmissions = <int>[];

      for (int i = 0; i < pendingSubmissions.length; i++) {
        final submission = pendingSubmissions[i];
        try {
          await LeaderboardService(apiService: apiService).submitScore(
            submission['playerName'],
            submission['score'],
          );
          successfulSubmissions.add(i);
          debugPrint('✅ Retry successful: ${submission['playerName']} - ${submission['score']}');
        } catch (e) {
          debugPrint('❌ Retry failed for ${submission['playerName']}: $e');
        }
      }

      // Remove successful submissions
      if (successfulSubmissions.isNotEmpty) {
        final updatedSubmissions = <Map<String, dynamic>>[];
        for (int i = 0; i < pendingSubmissions.length; i++) {
          if (!successfulSubmissions.contains(i)) {
            updatedSubmissions.add(pendingSubmissions[i]);
          }
        }
        await appCache.set('pending_submissions', updatedSubmissions);

        // Refresh leaderboard after successful retries
        await refreshData(force: true);
        debugPrint('🔄 Processed ${successfulSubmissions.length} pending submissions');
      }
    } catch (e) {
      debugPrint('❌ Failed to retry pending submissions: $e');
    }
  }

  /// Checks if data should be refreshed based on time intervals
  Future<bool> _shouldRefreshData() async {
    try {
      final lastRefresh = await _getLastRefresh();
      if (lastRefresh == null) return true;

      final timeSinceRefresh = DateTime.now().difference(lastRefresh);

      // Check for regular refresh interval
      if (timeSinceRefresh > _refreshInterval) {
        return true;
      }

      // Check for force refresh interval if we have failures
      final failureCount = await _getRefreshFailureCount();
      if (failureCount > 0 && timeSinceRefresh > _forceRefreshInterval) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking refresh criteria: $e');
      return true; // Default to refresh on error
    }
  }

  /// LIFECYCLE METHOD: Refreshes leaderboard data
  /// Called when app resumes or when data needs to be updated
  Future<void> refreshData({bool force = false}) async {
    if (_isRefreshing && !force) {
      debugPrint('⏳ Refresh already in progress, skipping...');
      return;
    }

    _isRefreshing = true;

    try {
      debugPrint('🔄 Starting leaderboard data refresh...');

      // First, retry any pending submissions
      await retryPendingSubmissions();

      // Fetch fresh data from API
      final leaderboardService = LeaderboardService(apiService: apiService);
      final freshData = await leaderboardService.fetchLeaderboard();

      if (freshData.isNotEmpty) {
        // Cache the fresh data
        await appCache.cacheLeaderboard(freshData);
        await _updateLastRefresh();
        await _resetRefreshFailureCount();

        debugPrint('✅ Leaderboard refresh completed: ${freshData.length} entries');
      } else {
        debugPrint('⚠️ Received empty leaderboard data');
        await _incrementRefreshFailureCount();
      }
    } catch (e) {
      debugPrint('❌ Leaderboard refresh failed: $e');
      await _incrementRefreshFailureCount();

      // Don't rethrow unless this is a forced refresh
      if (force) rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Forces a complete data refresh (clears cache first)
  Future<void> forceRefresh() async {
    try {
      debugPrint('🔄 Forcing complete leaderboard refresh...');

      // Clear existing cache
      await appCache.remove('leaderboard_data');

      // Force refresh
      await refreshData(force: true);

      debugPrint('✅ Force refresh completed');
    } catch (e) {
      debugPrint('❌ Force refresh failed: $e');
      rethrow;
    }
  }

  /// Gets refresh statistics
  Future<Map<String, dynamic>> getRefreshStats() async {
    final lastRefresh = await _getLastRefresh();
    final lastForceRefresh = await _getLastForceRefresh();
    final failureCount = await _getRefreshFailureCount();
    final pendingSubmissions = await _getPendingSubmissions();

    return {
      'lastRefresh': lastRefresh?.toIso8601String(),
      'lastForceRefresh': lastForceRefresh?.toIso8601String(),
      'failureCount': failureCount,
      'pendingSubmissions': pendingSubmissions.length,
      'isRefreshing': _isRefreshing,
      'shouldRefresh': await _shouldRefreshData(),
    };
  }

  /// Updates last refresh timestamp
  Future<void> _updateLastRefresh() async {
    final now = DateTime.now();
    await appCache.set(_lastRefreshKey, now.toIso8601String());
    _lastRefreshTime = now;
  }

  /// Gets last refresh timestamp
  Future<DateTime?> _getLastRefresh() async {
    if (_lastRefreshTime != null) return _lastRefreshTime;

    try {
      final raw = appCache.get<String>(_lastRefreshKey);
      _lastRefreshTime = raw != null ? DateTime.parse(raw) : null;
      return _lastRefreshTime;
    } catch (e) {
      return null;
    }
  }

  /// Updates last force refresh timestamp
  Future<void> _updateLastForceRefresh() async {
    await appCache.set(_lastForceRefreshKey, DateTime.now().toIso8601String());
  }

  /// Gets last force refresh timestamp
  Future<DateTime?> _getLastForceRefresh() async {
    try {
      final raw = appCache.get<String>(_lastForceRefreshKey);
      return raw != null ? DateTime.parse(raw) : null;
    } catch (e) {
      return null;
    }
  }

  /// Increments refresh failure count
  Future<void> _incrementRefreshFailureCount() async {
    final current = await _getRefreshFailureCount();
    await appCache.set(_refreshFailureCountKey, current + 1);
  }

  /// Resets refresh failure count
  Future<void> _resetRefreshFailureCount() async {
    await appCache.set(_refreshFailureCountKey, 0);
  }

  /// Gets refresh failure count
  Future<int> _getRefreshFailureCount() async {
    return appCache.get<int>(_refreshFailureCountKey) ?? 0;
  }

  /// Validates leaderboard data integrity
  Future<bool> validateLeaderboardData() async {
    try {
      final cached = await appCache.getCachedLeaderboard();

      // Check for basic data integrity
      for (final entry in cached) {
        if (entry.playerName.isEmpty || entry.score < 0) {
          debugPrint('⚠️ Invalid leaderboard entry found: ${entry.playerName} - ${entry.score}');
          return false;
        }
      }

      // Check if data is sorted correctly (highest scores first)
      for (int i = 0; i < cached.length - 1; i++) {
        if (cached[i].score < cached[i + 1].score) {
          debugPrint('⚠️ Leaderboard data not properly sorted');
          return false;
        }
      }

      debugPrint('✅ Leaderboard data validation passed');
      return true;
    } catch (e) {
      debugPrint('❌ Leaderboard data validation failed: $e');
      return false;
    }
  }

  /// Gets leaderboard entry by player name
  Future<LeaderboardEntry?> getPlayerEntry(String playerName) async {
    try {
      final leaderboard = await loadLeaderboard();
      return leaderboard.firstWhere(
            (entry) => entry.playerName.toLowerCase() == playerName.toLowerCase(),
        orElse: () => throw StateError('Player not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Gets player's rank (1-based)
  Future<int?> getPlayerRank(String playerName) async {
    try {
      final leaderboard = await loadLeaderboard();
      for (int i = 0; i < leaderboard.length; i++) {
        if (leaderboard[i].playerName.toLowerCase() == playerName.toLowerCase()) {
          return i + 1; // 1-based ranking
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gets top N players
  Future<List<LeaderboardEntry>> getTopPlayers({int count = 10}) async {
    try {
      final leaderboard = await loadLeaderboard();
      return leaderboard.take(count).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets players around a specific rank
  Future<List<LeaderboardEntry>> getPlayersAroundRank(int rank, {int radius = 2}) async {
    try {
      final leaderboard = await loadLeaderboard();
      final startIndex = (rank - 1 - radius).clamp(0, leaderboard.length);
      final endIndex = (rank - 1 + radius).clamp(0, leaderboard.length - 1);

      return leaderboard.sublist(startIndex, endIndex + 1);
    } catch (e) {
      return [];
    }
  }

  /// Searches for players by name pattern
  Future<List<LeaderboardEntry>> searchPlayers(String namePattern) async {
    try {
      final leaderboard = await loadLeaderboard();
      final pattern = namePattern.toLowerCase();

      return leaderboard.where((entry) =>
          entry.playerName.toLowerCase().contains(pattern)
      ).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets leaderboard statistics
  Future<Map<String, dynamic>> getLeaderboardStats() async {
    try {
      final leaderboard = await loadLeaderboard();

      if (leaderboard.isEmpty) {
        return {
          'totalPlayers': 0,
          'highestScore': 0,
          'averageScore': 0,
          'medianScore': 0,
        };
      }

      final scores = leaderboard.map((e) => e.score).toList();
      final totalScore = scores.fold(0, (sum, score) => sum + score);
      final averageScore = totalScore / scores.length;

      scores.sort();
      final medianScore = scores.length % 2 == 0
          ? (scores[scores.length ~/ 2 - 1] + scores[scores.length ~/ 2]) / 2
          : scores[scores.length ~/ 2].toDouble();

      return {
        'totalPlayers': leaderboard.length,
        'highestScore': scores.last,
        'lowestScore': scores.first,
        'averageScore': averageScore.round(),
        'medianScore': medianScore.round(),
        'lastUpdated': (await _getLastRefresh())?.toIso8601String(),
      };
    } catch (e) {
      return {
        'totalPlayers': 0,
        'highestScore': 0,
        'averageScore': 0,
        'medianScore': 0,
        'error': e.toString(),
      };
    }
  }

  /// Clears all leaderboard cache and pending data
  Future<void> clearAllData() async {
    try {
      await appCache.remove('leaderboard_data');
      await appCache.remove('pending_submissions');
      await appCache.remove(_lastRefreshKey);
      await appCache.remove(_lastForceRefreshKey);
      await appCache.remove(_refreshFailureCountKey);

      _lastRefreshTime = null;
      debugPrint('🗑️ All leaderboard data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear leaderboard data: $e');
    }
  }

  /// Export leaderboard data for backup
  Future<Map<String, dynamic>> exportLeaderboardData() async {
    final leaderboard = await loadLeaderboard();
    final pendingSubmissions = await _getPendingSubmissions();

    return {
      'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
      'pendingSubmissions': pendingSubmissions,
      'lastRefresh': (await _getLastRefresh())?.toIso8601String(),
      'exported': DateTime.now().toIso8601String(),
    };
  }

  /// Import leaderboard data from backup
  Future<void> importLeaderboardData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('leaderboard') && data['leaderboard'] is List) {
        final entries = (data['leaderboard'] as List)
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList();
        await appCache.cacheLeaderboard(entries);
      }

      if (data.containsKey('pendingSubmissions') && data['pendingSubmissions'] is List) {
        await appCache.set('pending_submissions', data['pendingSubmissions']);
      }

      await _updateLastRefresh();
      debugPrint('✅ Leaderboard data imported successfully');
    } catch (e) {
      debugPrint('❌ Failed to import leaderboard data: $e');
      rethrow;
    }
  }

  /// Dispose method to clean up resources
  void dispose() {
    _isRefreshing = false;
    _lastRefreshTime = null;
  }
}
