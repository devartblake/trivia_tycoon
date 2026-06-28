import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';

/// Multi-level cache for tier configuration
///
/// Cache Hierarchy:
/// 1. Memory Cache (fast, limited size)
/// 2. Disk Cache (persistent, larger size)
/// 3. API (source of truth)
class TierConfigCache {
  final TierApiClient _apiClient;
  final Map<String, CachedTierData> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Cache TTL (time-to-live) - 1 hour for tier definitions
  static const Duration _definitionsTtl = Duration(hours: 1);

  /// Cache TTL for player progress - 5 minutes for fresh data
  static const Duration _playerProgressTtl = Duration(minutes: 5);

  /// Max items in memory cache
  static const int _maxMemoryItems = 20;

  TierConfigCache({required TierApiClient apiClient}) : _apiClient = apiClient;

  /// Get tier definitions with multi-level caching
  Future<List<TierDefinition>> getTierDefinitions() async {
    const cacheKey = 'tier_definitions';

    // Check memory cache
    if (_isMemoryCacheValid(cacheKey)) {
      LogManager.debug('[TierConfigCache] Memory cache hit for tier definitions');
      return _getMemoryCachedTiers(cacheKey);
    }

    LogManager.debug('[TierConfigCache] Memory cache miss for tier definitions');

    try {
      // Fetch from API
      final tiers = await _apiClient.getTierDefinitions();

      // Store in memory cache
      _storeInMemoryCache(cacheKey, tiers);

      // TODO: Store in disk cache (Phase 2.2.2)

      LogManager.debug('[TierConfigCache] Fetched ${tiers.length} tier definitions from API');
      return tiers;
    } catch (e) {
      LogManager.error(
        '[TierConfigCache] Error fetching tier definitions: $e',
        source: 'TierConfigCache.getTierDefinitions',
        error: e,
      );
      rethrow;
    }
  }

  /// Get player tier progress with caching
  Future<PlayerTierProgress> getPlayerTierProgress(String userId) async {
    final cacheKey = 'player_progress_$userId';

    // Check memory cache
    if (_isMemoryCacheValid(cacheKey, ttl: _playerProgressTtl)) {
      LogManager.debug('[TierConfigCache] Memory cache hit for player progress');
      return _getMemoryCachedProgress(cacheKey);
    }

    LogManager.debug('[TierConfigCache] Memory cache miss for player progress');

    try {
      // Fetch from API
      final progress = await _apiClient.getPlayerTierProgress(userId);

      // Store in memory cache
      _storeInMemoryCache(cacheKey, progress);

      // TODO: Store in disk cache if needed

      LogManager.debug('[TierConfigCache] Fetched player progress for user=$userId');
      return progress;
    } catch (e) {
      LogManager.error(
        '[TierConfigCache] Error fetching player progress: $e',
        source: 'TierConfigCache.getPlayerTierProgress',
        error: e,
      );
      rethrow;
    }
  }

  /// Award XP to player
  Future<XpAwardResult> awardXp(String userId, int amount, String reason) async {
    try {
      LogManager.debug('[TierConfigCache] Awarding $amount XP to user=$userId');

      final result = await _apiClient.awardXp(userId, amount, reason);

      // Invalidate player progress cache
      _invalidateCache('player_progress_$userId');

      LogManager.debug('[TierConfigCache] XP awarded successfully');
      return result;
    } catch (e) {
      LogManager.error(
        '[TierConfigCache] Error awarding XP: $e',
        source: 'TierConfigCache.awardXp',
        error: e,
      );
      rethrow;
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final hitCount = _memoryCache.length;
    final ttlExpiredCount = _cacheTimestamps.entries
        .where((e) => _isExpired(e.value))
        .length;

    return {
      'totalItems': _memoryCache.length,
      'maxItems': _maxMemoryItems,
      'expiredItems': ttlExpiredCount,
      'memoryUsage': _estimateMemoryUsage(),
    };
  }

  /// Invalidate specific cache entry
  void _invalidateCache(String key) {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    LogManager.debug('[TierConfigCache] Invalidated cache for key=$key');
  }

  /// Clear all caches
  void clearAllCaches() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    LogManager.debug('[TierConfigCache] Cleared all caches');
  }

  // ─────────────────────────────────────────────────────────────────────
  // Private Helper Methods
  // ─────────────────────────────────────────────────────────────────────

  /// Check if memory cache entry is valid (not expired)
  bool _isMemoryCacheValid(String key, {Duration? ttl}) {
    if (!_memoryCache.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) {
      return false;
    }

    final effectiveTtl = ttl ?? _definitionsTtl;
    final isExpired = _isExpired(timestamp, ttl: effectiveTtl);

    if (isExpired) {
      _invalidateCache(key);
      return false;
    }

    return true;
  }

  /// Check if timestamp is expired
  bool _isExpired(DateTime timestamp, {Duration? ttl}) {
    final effectiveTtl = ttl ?? _definitionsTtl;
    return DateTime.now().difference(timestamp) > effectiveTtl;
  }

  /// Get tier definitions from memory cache
  List<TierDefinition> _getMemoryCachedTiers(String key) {
    final cached = _memoryCache[key];
    if (cached is CachedTierList) {
      return cached.tiers;
    }
    throw StateError('Invalid cache type for key=$key');
  }

  /// Get player progress from memory cache
  PlayerTierProgress _getMemoryCachedProgress(String key) {
    final cached = _memoryCache[key];
    if (cached is CachedPlayerProgress) {
      return cached.progress;
    }
    throw StateError('Invalid cache type for key=$key');
  }

  /// Store data in memory cache with LRU eviction
  void _storeInMemoryCache(String key, dynamic data) {
    // Implement LRU eviction if cache is full
    if (_memoryCache.length >= _maxMemoryItems) {
      _evictLruItem();
    }

    if (data is List<TierDefinition>) {
      _memoryCache[key] = CachedTierList(data);
    } else if (data is PlayerTierProgress) {
      _memoryCache[key] = CachedPlayerProgress(data);
    }

    _cacheTimestamps[key] = DateTime.now();
    LogManager.debug('[TierConfigCache] Stored in memory cache: key=$key');
  }

  /// Evict least recently used item (FIFO for simplicity)
  void _evictLruItem() {
    if (_memoryCache.isEmpty) return;

    // Get oldest timestamp
    var oldestKey = _cacheTimestamps.keys.first;
    var oldestTime = _cacheTimestamps[oldestKey]!;

    for (final entry in _cacheTimestamps.entries) {
      if (entry.value.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value;
      }
    }

    _invalidateCache(oldestKey);
    LogManager.debug('[TierConfigCache] Evicted LRU item: key=$oldestKey');
  }

  /// Estimate memory usage of cache
  String _estimateMemoryUsage() {
    // Simple estimation: ~100KB per tier definition, ~50KB per progress entry
    final tierBytes = _memoryCache.values
        .whereType<CachedTierList>()
        .fold<int>(0, (sum, item) => sum + (item.tiers.length * 100000));

    final progressBytes = _memoryCache.values
        .whereType<CachedPlayerProgress>()
        .fold<int>(0, (sum, item) => sum + 50000);

    final totalBytes = tierBytes + progressBytes;
    final totalMb = totalBytes / (1024 * 1024);

    return '${totalMb.toStringAsFixed(2)} MB';
  }
}

// ─────────────────────────────────────────────────────────────────────
// Cache Data Classes
// ─────────────────────────────────────────────────────────────────────

/// Base class for cached data
abstract class CachedTierData {
  DateTime get timestamp;
}

/// Cached tier definitions list
class CachedTierList extends CachedTierData {
  final List<TierDefinition> tiers;

  @override
  final DateTime timestamp = DateTime.now();

  CachedTierList(this.tiers);
}

/// Cached player tier progress
class CachedPlayerProgress extends CachedTierData {
  final PlayerTierProgress progress;

  @override
  final DateTime timestamp = DateTime.now();

  CachedPlayerProgress(this.progress);
}

// ─────────────────────────────────────────────────────────────────────
// Cache Statistics Helper
// ─────────────────────────────────────────────────────────────────────

/// Cache statistics and diagnostics
class CacheStatistics {
  final int totalItems;
  final int maxItems;
  final int expiredItems;
  final String memoryUsage;
  final double hitRate;

  CacheStatistics({
    required this.totalItems,
    required this.maxItems,
    required this.expiredItems,
    required this.memoryUsage,
    required this.hitRate,
  });

  @override
  String toString() => '''
CacheStatistics {
  totalItems: $totalItems/$maxItems,
  expiredItems: $expiredItems,
  memoryUsage: $memoryUsage,
  hitRate: ${(hitRate * 100).toStringAsFixed(1)}%,
}''';
}
