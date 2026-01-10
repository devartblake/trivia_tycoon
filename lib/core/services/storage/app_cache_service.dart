import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../game/models/question_model.dart';
import '../../../game/models/leaderboard_entry.dart';
import '../../../ui_components/qr_code/models/scan_history_item.dart';

/// Offline-first cache service backed by Hive.
/// Key goals:
/// - Stable JSON typing (Map<String,dynamic> and List) when reading cached JSON.
/// - Avoid brittle generic casts like get<Map<String,dynamic>>() (explicit helpers instead).
/// - Maintain lightweight expiration metadata per key.
/// - Support existing app caching use-cases (leaderboards, questions, scan history, temp/session data).
class AppCacheService {
  static const String _boxName = 'cache';

  // Internal keys
  static const String _tempDataKey = 'temp_data';
  static const String _cacheMetadataKey = 'cache_metadata';
  static const String _lastCleanupKey = 'last_cleanup';

  // Cache expiration settings
  static const Duration _defaultExpiration = Duration(hours: 24);
  static const Duration _questionCacheExpiration = Duration(hours: 6);
  static const Duration _leaderboardCacheExpiration = Duration(minutes: 30);
  static const Duration _tempDataExpiration = Duration(hours: 1);

  late final Box _box;

  /// Call this in your ServiceManager before using other methods.
  /// This assumes Hive has already been initialized (Hive.initFlutter()) in your app bootstrap.
  static Future<AppCacheService> initialize() async {
    final service = AppCacheService();

    // If your bootstrap already opens this box, Hive.openBox will return the existing open box.
    service._box = await Hive.openBox(_boxName);

    // Optional: clean old entries at startup (safe, but not required)
    // await service.cleanOldEntries();

    return service;
  }

  // ---------------------------------------------------------------------------
  // Core typed API
  // ---------------------------------------------------------------------------

  /// Generic get with expiration check.
  ///
  /// IMPORTANT:
  /// - Do NOT call get<Map<String, dynamic>>. Use getJsonMap().
  /// - Do NOT call get<List<dynamic>> for JSON arrays. Use getJsonList() when you can.
  T? get<T>(String key) {

    final raw = _box.get(key);
    if (raw == null) return null;

    // Check expiration
    if (_isExpired(key)) {
      _box.delete(key);
      _removeCacheMetadata(key);
      return null;
    }

    // If stored as JSON string, decode and normalize Map keys to String.
    if (raw is String) {
      final decoded = _tryDecodeJson(raw);
      if (decoded == null) {
        // Plain string (not JSON)
        return raw as T?;
      }

      final normalized = _normalizeDecoded(decoded);
      return normalized as T?;
    }

    // Stored directly as a Hive-supported primitive/object.
    return raw as T?;
  }

  /// Strongly-typed JSON map getter (recommended for JSON objects).
  Map<String, dynamic>? getJsonMap(String key) {
    final v = get<dynamic>(key);
    if (v == null) return null;

    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      return Map<String, dynamic>.from(
        v.map((k, val) => MapEntry(k.toString(), val)),
      );
    }

    if (kDebugMode) {
      print('❌ [AppCacheService] getJsonMap("$key") got ${v.runtimeType}');
    }
    return null;
  }

  /// Strongly-typed JSON list getter (recommended for JSON arrays).
  List<dynamic>? getJsonList(String key) {
    final v = get<dynamic>(key);
    if (v == null) return null;

    if (v is List) return v;

    if (kDebugMode) {
      print('❌ [AppCacheService] getJsonList("$key") got ${v.runtimeType}');
    }
    return null;
  }

  /// Dedicated method for saving JSON-encodable objects.
  /// Ensures any object is stored as a JSON string for stable decoding.
  Future<void> setJson(String key, dynamic value, {Duration? expiration}) async {
    try {
      final encoded = jsonEncode(value);
      await _box.put(key, encoded);
      await _updateCacheMetadata(key, expiration: expiration);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to set JSON in cache for key "$key": $e');
      }
    }
  }

  /// Stores raw data as-is (use for primitives or Hive-supported objects).
  Future<void> put(String key, dynamic value, {Duration? expiration}) async {
    await _box.put(key, value);
    await _updateCacheMetadata(key, expiration: expiration);
  }

  /// Generic set:
  /// - primitives stored directly
  /// - Map/List encoded as JSON string
  Future<void> set(String key, dynamic value, {Duration? expiration}) async {
    if (value == null) {
      await remove(key);
      return;
    }

    final isPrimitive =
        value is String || value is num || value is bool || value is DateTime;

    if (isPrimitive) {
      await put(key, value, expiration: expiration);
      return;
    }

    // Structured data goes through JSON for stability.
    await setJson(key, value, expiration: expiration);
  }

  /// Set with explicit expiration time
  Future<void> setWithExpiration(
      String key,
      dynamic value,
      DateTime expiration,
      ) async {
    final isPrimitive =
        value is String || value is num || value is bool || value is DateTime;

    if (isPrimitive) {
      await _box.put(key, value);
    } else {
      await _box.put(key, jsonEncode(value));
    }

    await _setCacheExpiration(key, expiration);
  }

  Future<void> remove(String key) async {
    await _box.delete(key);
    await _removeCacheMetadata(key);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  // ---------------------------------------------------------------------------
  // Feature helpers (Leaderboard / Questions / Scan history)
  // ---------------------------------------------------------------------------

  /// Leaderboard helpers with expiration
  Future<void> cacheLeaderboard(List<LeaderboardEntry> entries) async {
    final encoded = entries.map((e) => e.toJson()).toList();
    await setWithExpiration(
      'leaderboard_data',
      encoded,
      DateTime.now().add(_leaderboardCacheExpiration),
    );
  }

  Future<List<LeaderboardEntry>> getCachedLeaderboard() async {
    final raw = getJsonList('leaderboard_data');
    if (raw == null) return [];

    try {
      return raw.map((e) {
        if (e is Map<String, dynamic>) return LeaderboardEntry.fromJson(e);
        if (e is Map) return LeaderboardEntry.fromJson(Map<String, dynamic>.from(e));
        throw StateError('Invalid leaderboard entry type: ${e.runtimeType}');
      }).toList();
    } catch (e) {
      await remove('leaderboard_data');
      return [];
    }
  }

  /// Save QuestionModel list to Hive (as JSON strings) with expiration
  Future<void> saveQuestionCache(String key, List<QuestionModel> questions) async {
    try {
      final encoded = questions.map((q) => q.toJson()).toList();
      await setWithExpiration(
        key,
        encoded,
        DateTime.now().add(_questionCacheExpiration),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save question cache: $e');
      }
    }
  }

  /// Load QuestionModel list from Hive with expiration check
  Future<List<QuestionModel>> loadQuestionCache(String key) async {
    final raw = getJsonList(key);
    if (raw == null) return [];

    try {
      return raw.map((e) {
        if (e is Map<String, dynamic>) return QuestionModel.fromJson(e);
        if (e is Map) return QuestionModel.fromJson(Map<String, dynamic>.from(e));
        throw StateError('Invalid question type: ${e.runtimeType}');
      }).toList();
    } catch (e) {
      await remove(key);
      return [];
    }
  }

  Future<void> clearQuestionCache(String key) async => remove(key);

  /// Saves questions from admin question editor (stored in separate 'questions' box).
  Future<void> saveQuestions(List<QuestionModel> questions) async {
    try {
      final box = await Hive.openBox('questions');
      await box.put('all', questions.map((q) => q.toJson()).toList());
      // Track under cache metadata (optional)
      await _updateCacheMetadata('questions_all');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save questions: $e');
      }
    }
  }

  /// Retrieves questions from separate box.
  Future<List<QuestionModel>> getQuestions() async {
    try {
      final box = await Hive.openBox('questions');
      final raw = box.get('all', defaultValue: []);
      if (raw is List) {
        return raw.map((q) {
          if (q is Map<String, dynamic>) return QuestionModel.fromJson(q);
          if (q is Map) return QuestionModel.fromJson(Map<String, dynamic>.from(q));
          throw StateError('Invalid saved question type: ${q.runtimeType}');
        }).toList();
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
      await setJson('qr_scan_history', encoded, expiration: _defaultExpiration);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save scan history: $e');
      }
    }
  }

  /// Retrieves QR Code Camera scan history
  Future<List<ScanHistoryItem>> loadScanHistory() async {
    try {
      final raw = getJsonList('qr_scan_history') ?? const <dynamic>[];
      return raw.map((e) {
        if (e is Map<String, dynamic>) return ScanHistoryItem.fromJson(e);
        if (e is Map) return ScanHistoryItem.fromJson(Map<String, dynamic>.from(e));
        throw StateError('Invalid scan item type: ${e.runtimeType}');
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load scan history: $e');
      }
      await remove('qr_scan_history');
      return [];
    }
  }

  Future<void> clearScanHistory() async => remove('qr_scan_history');

  // ---------------------------------------------------------------------------
  // Temporary data (session-like, expires quickly)
  // ---------------------------------------------------------------------------

  /// Store temporary data that expires quickly.
  /// Stored under [_tempDataKey] as a JSON map.
  Future<void> setTemporaryData(String key, dynamic value) async {
    final tempData = getJsonMap(_tempDataKey) ?? <String, dynamic>{};

    tempData[key] = {
      'value': value,
      'expires': DateTime.now().add(_tempDataExpiration).toIso8601String(),
    };

    await setJson(_tempDataKey, tempData, expiration: _tempDataExpiration);
  }

  /// Get temporary data with automatic expiration.
  T? getTemporaryData<T>(String key) {
    final tempData = getJsonMap(_tempDataKey) ?? <String, dynamic>{};
    final item = tempData[key];

    if (item is! Map) return null;

    final itemMap = Map<String, dynamic>.from(item);
    final expiresRaw = itemMap['expires'];
    if (expiresRaw is! String) return null;

    final expires = DateTime.tryParse(expiresRaw);
    if (expires == null) return null;

    if (DateTime.now().isAfter(expires)) {
      tempData.remove(key);
      setJson(_tempDataKey, tempData, expiration: _tempDataExpiration);
      return null;
    }

    return itemMap['value'] as T?;
  }

  /// Clears temporary data and other temp/session keys.
  Future<void> clearTemporaryData() async {
    try {
      await remove(_tempDataKey);

      final tempKeys = _box.keys
          .map((k) => k.toString())
          .where((k) => k.startsWith('temp_') || k.startsWith('session_'))
          .toList();

      for (final k in tempKeys) {
        await _box.delete(k);
        await _removeCacheMetadata(k);
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

  // ---------------------------------------------------------------------------
  // Cleanup / metadata / expiration
  // ---------------------------------------------------------------------------

  /// Cleans old cache entries (expires keys tracked in metadata).
  Future<void> cleanOldEntries() async {
    try {
      final metadata = _getCacheMetadata();
      final now = DateTime.now();
      final keysToRemove = <String>[];

      for (final entry in metadata.entries) {
        final key = entry.key;
        final data = entry.value;

        if (data is Map && data.containsKey('expires')) {
          final expiresRaw = data['expires'];
          if (expiresRaw is String) {
            final expires = DateTime.tryParse(expiresRaw);
            if (expires != null && now.isAfter(expires)) {
              keysToRemove.add(key);
            }
          }
        }
      }

      for (final key in keysToRemove) {
        await remove(key);
      }

      await _cleanExpiredTemporaryData();
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

  Future<void> _cleanExpiredTemporaryData() async {
    final tempData = getJsonMap(_tempDataKey) ?? <String, dynamic>{};
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in tempData.entries) {
      final item = entry.value;
      if (item is Map) {
        final itemMap = Map<String, dynamic>.from(item);
        final expiresRaw = itemMap['expires'];
        if (expiresRaw is String) {
          final expires = DateTime.tryParse(expiresRaw);
          if (expires != null && now.isAfter(expires)) {
            keysToRemove.add(entry.key);
          }
        }
      }
    }

    for (final key in keysToRemove) {
      tempData.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      await setJson(_tempDataKey, tempData, expiration: _tempDataExpiration);
    }
  }

  Future<void> _updateCacheMetadata(String key, {Duration? expiration}) async {
    final metadata = _getCacheMetadata();
    final now = DateTime.now();

    metadata[key] = {
      'created': now.toIso8601String(),
      'accessed': now.toIso8601String(),
      'expires': (expiration != null)
          ? now.add(expiration).toIso8601String()
          : now.add(_defaultExpiration).toIso8601String(),
    };

    await _box.put(_cacheMetadataKey, metadata);
  }

  Future<void> _setCacheExpiration(String key, DateTime expiration) async {
    final metadata = _getCacheMetadata();
    final existing = metadata[key];
    final existingMap = existing is Map
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};

    existingMap['expires'] = expiration.toIso8601String();
    existingMap['accessed'] = DateTime.now().toIso8601String();

    metadata[key] = existingMap;
    await _box.put(_cacheMetadataKey, metadata);
  }

  Future<void> _removeCacheMetadata(String key) async {
    final metadata = _getCacheMetadata();
    metadata.remove(key);
    await _box.put(_cacheMetadataKey, metadata);
  }

  Map<String, dynamic> _getCacheMetadata() {
    final raw = _box.get(_cacheMetadataKey);
    if (raw is Map) {
      // Normalize keys to String
      return Map<String, dynamic>.from(
        raw.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    return <String, dynamic>{};
  }

  bool _isExpired(String key) {
    final metadata = _getCacheMetadata();
    final data = metadata[key];

    if (data is! Map) return false;

    final m = Map<String, dynamic>.from(data);
    final expiresRaw = m['expires'];
    if (expiresRaw is! String) return false;

    final expires = DateTime.tryParse(expiresRaw);
    if (expires == null) return false;

    return DateTime.now().isAfter(expires);
  }

  Future<void> _updateLastCleanup() async {
    await _box.put(_lastCleanupKey, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastCleanup() async {
    final raw = _box.get(_lastCleanupKey);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    final metadata = _getCacheMetadata();
    final totalEntries = _box.length;

    final expiredCount = metadata.values.where((data) {
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        final expiresRaw = m['expires'];
        if (expiresRaw is String) {
          final expires = DateTime.tryParse(expiresRaw);
          return expires != null && DateTime.now().isAfter(expires);
        }
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

  Future<Map<String, dynamic>?> getCacheEntryInfo(String key) async {
    final metadata = _getCacheMetadata();
    final data = metadata[key];

    if (data is! Map) return null;

    final m = Map<String, dynamic>.from(data);
    final created = DateTime.tryParse(m['created']?.toString() ?? '');
    final expires = DateTime.tryParse(m['expires']?.toString() ?? '');
    final now = DateTime.now();

    if (created == null || expires == null) return null;

    return {
      'key': key,
      'created': m['created'],
      'accessed': m['accessed'],
      'expires': m['expires'],
      'isExpired': now.isAfter(expires),
      'age': now.difference(created).inMinutes,
      'timeToExpiry': expires.difference(now).inMinutes,
    };
  }

  Future<void> expireCacheEntry(String key) async {
    await _setCacheExpiration(
      key,
      DateTime.now().subtract(const Duration(seconds: 1)),
    );
  }

  Future<void> extendCacheEntry(String key, Duration extension) async {
    final info = await getCacheEntryInfo(key);
    if (info == null) return;

    final expires = DateTime.tryParse(info['expires']?.toString() ?? '');
    if (expires == null) return;

    await _setCacheExpiration(key, expires.add(extension));
  }

  Future<void> refreshCacheEntry(String key) async {
    final metadata = _getCacheMetadata();
    final data = metadata[key];

    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      m['accessed'] = DateTime.now().toIso8601String();
      metadata[key] = m;
      await _box.put(_cacheMetadataKey, metadata);
    }
  }

  List<String> getCacheKeysByPattern(String pattern) {
    return _box.keys
        .map((k) => k.toString())
        .where((k) => k.contains(pattern))
        .toList();
  }

  Future<void> removeCacheEntriesByPattern(String pattern) async {
    final keys = getCacheKeysByPattern(pattern);
    for (final key in keys) {
      await remove(key);
    }
  }

  // ---------------------------------------------------------------------------
  // JSON helpers
  // ---------------------------------------------------------------------------

  dynamic _tryDecodeJson(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  dynamic _normalizeDecoded(dynamic decoded) {
    if (decoded is Map) {
      return Map<String, dynamic>.from(
        decoded.map((k, v) => MapEntry(k.toString(), _normalizeDecoded(v))),
      );
    }
    if (decoded is List) {
      return decoded.map(_normalizeDecoded).toList();
    }
    return decoded;
  }
}
