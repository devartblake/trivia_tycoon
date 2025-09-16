import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../game/models/question_model.dart';
import '../../../game/models/leaderboard_entry.dart';
import '../../../ui_components/qr_code/models/scan_history_item.dart';

class AppCacheService {
  static const _boxName = 'cache';
  static const _tempDataKey = 'temp_data';
  static const _cacheMetadataKey = 'cache_metadata';
  static const _lastCleanupKey = 'last_cleanup';

  late final Box _box;

  // Cache expiration settings
  static const Duration _defaultExpiration = Duration(hours: 24);
  static const Duration _questionCacheExpiration = Duration(hours: 6);
  static const Duration _leaderboardCacheExpiration = Duration(minutes: 30);
  static const Duration _tempDataExpiration = Duration(hours: 1);

  /// Call this in your ServiceManager before using other methods
  static Future<AppCacheService> initialize() async {
    final service = AppCacheService();
    service._box = await Hive.openBox(_boxName);
    return service;
  }

  /// Generic get with expiration check
  T? get<T>(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;

    // Check if this is an expired cached item
    if (_isExpired(key)) {
      _box.delete(key);
      return null;
    }

    if (raw is String) {
      try {
        return jsonDecode(raw) as T?;
      } catch (e) {
        return raw as T?;
      }
    }
    return raw as T?;
  }

  Future<void> put(String key, dynamic value) async {
    await _box.put(key, value);
    await _updateCacheMetadata(key);
  }

  /// Generic set (JSON encodes all non-primitive values) with expiration
  Future<void> set(String key, dynamic value, {Duration? expiration}) async {
    final encoded = value is String || value is num || value is bool
        ? value
        : jsonEncode(value);

    await _box.put(key, encoded);
    await _updateCacheMetadata(key, expiration: expiration);
  }

  /// Set with explicit expiration time
  Future<void> setWithExpiration(String key, dynamic value, DateTime expiration) async {
    final encoded = value is String || value is num || value is bool
        ? value
        : jsonEncode(value);

    await _box.put(key, encoded);
    await _setCacheExpiration(key, expiration);
  }

  Future<void> remove(String key) async {
    await _box.delete(key);
    await _removeCacheMetadata(key);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  /// 📹 Leaderboard helpers with expiration
  Future<void> cacheLeaderboard(List<LeaderboardEntry> entries) async {
    final encoded = entries.map((e) => e.toJson()).toList();
    await setWithExpiration(
        'leaderboard_data',
        encoded,
        DateTime.now().add(_leaderboardCacheExpiration)
    );
  }

  Future<List<LeaderboardEntry>> getCachedLeaderboard() async {
    final raw = get<List<dynamic>>('leaderboard_data');
    if (raw == null) return [];

    try {
      return raw
          .map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      await remove('leaderboard_data');
      return [];
    }
  }

  /// ✅ Save QuestionModel list to Hive (as JSON strings) with expiration
  Future<void> saveQuestionCache(String key, List<QuestionModel> questions) async {
    try {
      final encoded = questions.map((q) => json.encode(q.toJson())).toList();
      await setWithExpiration(
          key,
          json.encode(encoded),
          DateTime.now().add(_questionCacheExpiration)
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save question cache: $e');
      }
    }
  }

  /// ✅ Load QuestionModel list from Hive with expiration check
  Future<List<QuestionModel>> loadQuestionCache(String key) async {
    final raw = get<String>(key);
    if (raw == null) return [];

    try {
      final List<dynamic> decoded = json.decode(raw);
      return decoded
          .map((e) => QuestionModel.fromJson(json.decode(e)))
          .toList();
    } catch (e) {
      await remove(key);
      return [];
    }
  }

  /// ✅ Clear cached question data for a given key
  Future<void> clearQuestionCache(String key) async {
    await remove(key);
  }

  /// Saves question from admin question editor
  Future<void> saveQuestions(List<QuestionModel> questions) async {
    try {
      final box = await Hive.openBox('questions');
      await box.put('all', questions.map((q) => q.toJson()).toList());
      await _updateCacheMetadata('questions_all');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save questions: $e');
      }
    }
  }

  /// Retrieves questions from model
  Future<List<QuestionModel>> getQuestions() async {
    try {
      final box = await Hive.openBox('questions');
      final raw = box.get('all', defaultValue: []);
      if (raw is List) {
        return raw.map((q) => QuestionModel.fromJson(q)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get questions: $e');
      }
      return [];
    }
  }

  /// Saves QR Code Camera scan history with expiration
  Future<void> saveScanHistory(List<ScanHistoryItem> items) async {
    try {
      final encoded = items.map((e) => e.toJson()).toList();
      await set('qr_scan_history', encoded, expiration: _defaultExpiration);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save scan history: $e');
      }
    }
  }

  /// Retrieves QR Code Camera scan history
  Future<List<ScanHistoryItem>> loadScanHistory() async {
    try {
      final raw = get<List<dynamic>>('qr_scan_history') ?? [];
      return raw.map((e) => ScanHistoryItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load scan history: $e');
      }
      await remove('qr_scan_history');
      return [];
    }
  }

  /// Clears QR Code Camera scan history
  Future<void> clearScanHistory() async {
    await remove('qr_scan_history');
  }

  /// Store temporary data that expires quickly
  Future<void> setTemporaryData(String key, dynamic value) async {
    final tempData = get<Map<String, dynamic>>(_tempDataKey) ?? <String, dynamic>{};
    tempData[key] = {
      'value': value,
      'expires': DateTime.now().add(_tempDataExpiration).toIso8601String(),
    };
    await set(_tempDataKey, tempData);
  }

  /// Get temporary data with automatic expiration
  T? getTemporaryData<T>(String key) {
    final tempData = get<Map<String, dynamic>>(_tempDataKey) ?? <String, dynamic>{};
    final item = tempData[key];

    if (item == null) return null;

    final expires = DateTime.parse(item['expires']);
    if (DateTime.now().isAfter(expires)) {
      // Item expired, remove it
      tempData.remove(key);
      set(_tempDataKey, tempData);
      return null;
    }

    return item['value'] as T?;
  }

  /// LIFECYCLE METHOD: Clears temporary data
  /// Called when app goes to background or is about to be terminated
  Future<void> clearTemporaryData() async {
    try {
      await remove(_tempDataKey);

      // Clear any other temporary keys
      final tempKeys = _box.keys.where((key) =>
      key.toString().startsWith('temp_') ||
          key.toString().startsWith('session_')
      ).toList();

      for (final key in tempKeys) {
        await _box.delete(key);
      }

      if (kDebugMode) {
        print('✅ Temporary data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear temporary data: $e');
      }
    }
  }

  /// LIFECYCLE METHOD: Cleans old cache entries
  /// Called when app resumes or starts
  Future<void> cleanOldEntries() async {
    try {
      final metadata = _getCacheMetadata();
      final now = DateTime.now();
      final keysToRemove = <String>[];

      // Check each cached item for expiration
      for (final entry in metadata.entries) {
        final key = entry.key;
        final data = entry.value as Map<String, dynamic>?;

        if (data != null && data.containsKey('expires')) {
          final expires = DateTime.parse(data['expires']);
          if (now.isAfter(expires)) {
            keysToRemove.add(key);
          }
        }
      }

      // Remove expired entries
      for (final key in keysToRemove) {
        await remove(key);
      }

      // Clean up temporary data
      await _cleanExpiredTemporaryData();

      // Update last cleanup time
      await _updateLastCleanup();

      if (kDebugMode) {
        print('✅ Cache cleanup completed. Removed ${keysToRemove.length} expired entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Cache cleanup failed: $e');
      }
    }
  }

  /// Clean expired temporary data
  Future<void> _cleanExpiredTemporaryData() async {
    final tempData = get<Map<String, dynamic>>(_tempDataKey) ?? <String, dynamic>{};
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in tempData.entries) {
      final item = entry.value as Map<String, dynamic>?;
      if (item != null && item.containsKey('expires')) {
        final expires = DateTime.parse(item['expires']);
        if (now.isAfter(expires)) {
          keysToRemove.add(entry.key);
        }
      }
    }

    for (final key in keysToRemove) {
      tempData.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      await set(_tempDataKey, tempData);
    }
  }

  /// Updates cache metadata for a key
  Future<void> _updateCacheMetadata(String key, {Duration? expiration}) async {
    final metadata = _getCacheMetadata();
    final now = DateTime.now();

    metadata[key] = {
      'created': now.toIso8601String(),
      'accessed': now.toIso8601String(),
      'expires': expiration != null
          ? now.add(expiration).toIso8601String()
          : now.add(_defaultExpiration).toIso8601String(),
    };

    await _box.put(_cacheMetadataKey, metadata);
  }

  /// Sets specific expiration for a cache key
  Future<void> _setCacheExpiration(String key, DateTime expiration) async {
    final metadata = _getCacheMetadata();
    final existing = metadata[key] as Map<String, dynamic>? ?? <String, dynamic>{};

    existing['expires'] = expiration.toIso8601String();
    existing['accessed'] = DateTime.now().toIso8601String();

    metadata[key] = existing;
    await _box.put(_cacheMetadataKey, metadata);
  }

  /// Removes cache metadata for a key
  Future<void> _removeCacheMetadata(String key) async {
    final metadata = _getCacheMetadata();
    metadata.remove(key);
    await _box.put(_cacheMetadataKey, metadata);
  }

  /// Gets cache metadata
  Map<String, dynamic> _getCacheMetadata() {
    final raw = _box.get(_cacheMetadataKey);
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  /// Checks if a cache key is expired
  bool _isExpired(String key) {
    final metadata = _getCacheMetadata();
    final data = metadata[key] as Map<String, dynamic>?;

    if (data == null || !data.containsKey('expires')) {
      return false; // No expiration data means no expiration
    }

    final expires = DateTime.parse(data['expires']);
    return DateTime.now().isAfter(expires);
  }

  /// Updates last cleanup timestamp
  Future<void> _updateLastCleanup() async {
    await _box.put(_lastCleanupKey, DateTime.now().toIso8601String());
  }

  /// Gets last cleanup timestamp
  Future<DateTime?> getLastCleanup() async {
    final raw = _box.get(_lastCleanupKey);
    return raw != null ? DateTime.parse(raw) : null;
  }

  /// Gets cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final metadata = _getCacheMetadata();
    final totalEntries = _box.length;
    final expiredCount = metadata.values.where((data) {
      if (data is Map && data.containsKey('expires')) {
        final expires = DateTime.parse(data['expires']);
        return DateTime.now().isAfter(expires);
      }
      return false;
    }).length;

    final lastCleanup = await getLastCleanup();

    return {
      'totalEntries': totalEntries,
      'trackedEntries': metadata.length,
      'expiredEntries': expiredCount,
      'lastCleanup': lastCleanup?.toIso8601String(),
      'cacheSize': _box.keys.length,
    };
  }

  /// Gets cache entry details
  Future<Map<String, dynamic>?> getCacheEntryInfo(String key) async {
    final metadata = _getCacheMetadata();
    final data = metadata[key] as Map<String, dynamic>?;

    if (data == null) return null;

    final now = DateTime.now();
    final expires = DateTime.parse(data['expires']);
    final created = DateTime.parse(data['created']);

    return {
      'key': key,
      'created': data['created'],
      'accessed': data['accessed'],
      'expires': data['expires'],
      'isExpired': now.isAfter(expires),
      'age': now.difference(created).inMinutes,
      'timeToExpiry': expires.difference(now).inMinutes,
    };
  }

  /// Force expires a cache entry
  Future<void> expireCacheEntry(String key) async {
    await _setCacheExpiration(key, DateTime.now().subtract(const Duration(seconds: 1)));
  }

  /// Extends cache entry expiration
  Future<void> extendCacheEntry(String key, Duration extension) async {
    final info = await getCacheEntryInfo(key);
    if (info != null) {
      final currentExpires = DateTime.parse(info['expires']);
      await _setCacheExpiration(key, currentExpires.add(extension));
    }
  }

  /// Refreshes cache entry (updates access time)
  Future<void> refreshCacheEntry(String key) async {
    final metadata = _getCacheMetadata();
    final data = metadata[key] as Map<String, dynamic>?;

    if (data != null) {
      data['accessed'] = DateTime.now().toIso8601String();
      metadata[key] = data;
      await _box.put(_cacheMetadataKey, metadata);
    }
  }

  /// Gets all cache keys by pattern
  List<String> getCacheKeysByPattern(String pattern) {
    return _box.keys.where((key) => key.toString().contains(pattern)).cast<String>().toList();
  }

  /// Bulk remove cache entries by pattern
  Future<void> removeCacheEntriesByPattern(String pattern) async {
    final keys = getCacheKeysByPattern(pattern);
    for (final key in keys) {
      await remove(key);
    }
  }
}
