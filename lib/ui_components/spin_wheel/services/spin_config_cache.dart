import 'package:synaptix/core/manager/log_manager.dart';
import 'package:synaptix/core/services/spin_wheel_api_client.dart';
import 'package:synaptix/ui_components/spin_wheel/models/spin_system_models.dart';

/// Multi-level cache for spin wheel configuration
///
/// Cache Hierarchy:
/// 1. Memory Cache (fast, limited size)
/// 2. Disk Cache (persistent, larger size)
/// 3. API (source of truth)
class SpinConfigCache {
  final SpinWheelApiClient _apiClient;
  final Map<String, CachedSpinData> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Cache TTL (time-to-live) - 1 hour for configuration
  static const Duration _configTtl = Duration(hours: 1);

  /// Cache TTL for analytics - 5 minutes for fresh data
  static const Duration _analyticsTtl = Duration(minutes: 5);

  /// Max items in memory cache
  static const int _maxMemoryItems = 20;

  /// Hit and miss counters for statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;

  SpinConfigCache({required SpinWheelApiClient apiClient})
      : _apiClient = apiClient;

  /// Get wheel segments with multi-level caching
  Future<List<WheelSegment>> getSegments() async {
    const cacheKey = 'spin_segments';

    // Check memory cache
    if (_isMemoryCacheValid(cacheKey)) {
      LogManager.debug('[SpinConfigCache] Memory cache hit for segments');
      _cacheHits++;
      return _getMemoryCachedSegments(cacheKey);
    }

    _cacheMisses++;
    LogManager.debug('[SpinConfigCache] Memory cache miss for segments');

    try {
      // Fetch from API
      final segments = await _apiClient.getSegments();

      // Store in memory cache
      _storeInMemoryCache(cacheKey, segments);

      LogManager.debug(
          '[SpinConfigCache] Fetched ${segments.length} segments from API');
      return segments;
    } catch (e) {
      LogManager.error(
        '[SpinConfigCache] Error fetching segments: $e',
        source: 'SpinConfigCache.getSegments',
        error: e,
      );
      rethrow;
    }
  }

  /// Get probability configuration with caching
  Future<ProbabilityConfig> getProbabilityConfig() async {
    const cacheKey = 'probability_config';

    // Check memory cache
    if (_isMemoryCacheValid(cacheKey)) {
      LogManager.debug(
          '[SpinConfigCache] Memory cache hit for probability config');
      _cacheHits++;
      return _getMemoryCachedConfig(cacheKey);
    }

    _cacheMisses++;
    LogManager.debug(
        '[SpinConfigCache] Memory cache miss for probability config');

    try {
      // Fetch from API
      final config = await _apiClient.getProbabilityConfig();

      // Store in memory cache
      _storeInMemoryCache(cacheKey, config);

      LogManager.debug('[SpinConfigCache] Fetched probability config from API');
      return config;
    } catch (e) {
      LogManager.error(
        '[SpinConfigCache] Error fetching probability config: $e',
        source: 'SpinConfigCache.getProbabilityConfig',
        error: e,
      );
      rethrow;
    }
  }

  /// Get analytics with caching
  Future<SpinAnalytics> getAnalytics({String period = '24h'}) async {
    final cacheKey = 'analytics_$period';

    // Check memory cache
    if (_isMemoryCacheValid(cacheKey, ttl: _analyticsTtl)) {
      LogManager.debug('[SpinConfigCache] Memory cache hit for analytics');
      _cacheHits++;
      return _getMemoryCachedAnalytics(cacheKey);
    }

    _cacheMisses++;
    LogManager.debug('[SpinConfigCache] Memory cache miss for analytics');

    try {
      // Fetch from API
      final analytics = await _apiClient.getAnalytics(period: period);

      // Store in memory cache
      _storeInMemoryCache(cacheKey, analytics);

      LogManager.debug(
          '[SpinConfigCache] Fetched analytics for period=$period');
      return analytics;
    } catch (e) {
      LogManager.error(
        '[SpinConfigCache] Error fetching analytics: $e',
        source: 'SpinConfigCache.getAnalytics',
        error: e,
      );
      rethrow;
    }
  }

  /// Log spin result (analytics)
  Future<void> logSpinResult(SpinResult result) async {
    try {
      await _apiClient.logSpinResult(result);
      // Invalidate analytics cache
      _invalidateAnalyticsCache();
    } catch (e) {
      LogManager.error(
        '[SpinConfigCache] Error logging spin result: $e',
        source: 'SpinConfigCache.logSpinResult',
        error: e,
      );
      // Don't rethrow - analytics failure shouldn't break spin flow
    }
  }

  /// Claim reward
  Future<ClaimRewardResponse> claimReward({
    required String userId,
    required String spinResultId,
    required String segmentId,
  }) async {
    try {
      return await _apiClient.claimReward(
        userId: userId,
        spinResultId: spinResultId,
        segmentId: segmentId,
      );
    } catch (e) {
      LogManager.error(
        '[SpinConfigCache] Error claiming reward: $e',
        source: 'SpinConfigCache.claimReward',
        error: e,
      );
      rethrow;
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? _cacheHits / totalRequests : 0.0;

    return {
      'totalItems': _memoryCache.length,
      'maxItems': _maxMemoryItems,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': hitRate,
      'memoryUsage': _estimateMemoryUsage(),
    };
  }

  /// Invalidate specific cache entry
  void _invalidateCache(String key) {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    LogManager.debug('[SpinConfigCache] Invalidated cache for key=$key');
  }

  /// Invalidate all analytics caches
  void _invalidateAnalyticsCache() {
    _cacheTimestamps.removeWhere((key, _) => key.startsWith('analytics_'));
    _memoryCache.removeWhere((key, _) => key.startsWith('analytics_'));
    LogManager.debug('[SpinConfigCache] Invalidated all analytics caches');
  }

  /// Clear all caches
  void clearAllCaches() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    LogManager.debug('[SpinConfigCache] Cleared all caches');
  }

  /// Reset statistics
  void resetStatistics() {
    _cacheHits = 0;
    _cacheMisses = 0;
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

    final effectiveTtl = ttl ?? _configTtl;
    final isExpired = _isExpired(timestamp, ttl: effectiveTtl);

    if (isExpired) {
      _invalidateCache(key);
      return false;
    }

    return true;
  }

  /// Check if timestamp is expired
  bool _isExpired(DateTime timestamp, {Duration? ttl}) {
    final effectiveTtl = ttl ?? _configTtl;
    return DateTime.now().difference(timestamp) > effectiveTtl;
  }

  /// Get segments from memory cache
  List<WheelSegment> _getMemoryCachedSegments(String key) {
    final cached = _memoryCache[key];
    if (cached is CachedSegments) {
      return cached.segments;
    }
    throw StateError('Invalid cache type for key=$key');
  }

  /// Get config from memory cache
  ProbabilityConfig _getMemoryCachedConfig(String key) {
    final cached = _memoryCache[key];
    if (cached is CachedProbabilityConfig) {
      return cached.config;
    }
    throw StateError('Invalid cache type for key=$key');
  }

  /// Get analytics from memory cache
  SpinAnalytics _getMemoryCachedAnalytics(String key) {
    final cached = _memoryCache[key];
    if (cached is CachedAnalytics) {
      return cached.analytics;
    }
    throw StateError('Invalid cache type for key=$key');
  }

  /// Store data in memory cache with LRU eviction
  void _storeInMemoryCache(String key, dynamic data) {
    // Implement LRU eviction if cache is full
    if (_memoryCache.length >= _maxMemoryItems) {
      _evictLruItem();
    }

    if (data is List<WheelSegment>) {
      _memoryCache[key] = CachedSegments(data);
    } else if (data is ProbabilityConfig) {
      _memoryCache[key] = CachedProbabilityConfig(data);
    } else if (data is SpinAnalytics) {
      _memoryCache[key] = CachedAnalytics(data);
    }

    _cacheTimestamps[key] = DateTime.now();
    LogManager.debug('[SpinConfigCache] Stored in memory cache: key=$key');
  }

  /// Evict least recently used item (FIFO for simplicity)
  void _evictLruItem() {
    if (_cacheTimestamps.isEmpty) return;

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
    LogManager.debug('[SpinConfigCache] Evicted LRU item: key=$oldestKey');
  }

  /// Estimate memory usage of cache
  String _estimateMemoryUsage() {
    // Simple estimation: ~2KB per segment, ~5KB per config, ~10KB per analytics
    final segmentBytes = _memoryCache.values
        .whereType<CachedSegments>()
        .fold<int>(0, (sum, item) => sum + (item.segments.length * 2000));

    final configBytes = _memoryCache.values
        .whereType<CachedProbabilityConfig>()
        .fold<int>(0, (sum, item) => sum + 5000);

    final analyticsBytes = _memoryCache.values
        .whereType<CachedAnalytics>()
        .fold<int>(0, (sum, item) => sum + 10000);

    final totalBytes = segmentBytes + configBytes + analyticsBytes;
    final totalMb = totalBytes / (1024 * 1024);

    return '${totalMb.toStringAsFixed(2)} MB';
  }
}

// ─────────────────────────────────────────────────────────────────────
// Cache Data Classes
// ─────────────────────────────────────────────────────────────────────

/// Base class for cached spin data
abstract class CachedSpinData {
  DateTime get timestamp;
}

/// Cached wheel segments
class CachedSegments extends CachedSpinData {
  final List<WheelSegment> segments;

  @override
  final DateTime timestamp = DateTime.now();

  CachedSegments(this.segments);
}

/// Cached probability configuration
class CachedProbabilityConfig extends CachedSpinData {
  final ProbabilityConfig config;

  @override
  final DateTime timestamp = DateTime.now();

  CachedProbabilityConfig(this.config);
}

/// Cached spin analytics
class CachedAnalytics extends CachedSpinData {
  final SpinAnalytics analytics;

  @override
  final DateTime timestamp = DateTime.now();

  CachedAnalytics(this.analytics);
}
