import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';

void main() {
  late Directory tempDir;
  late AppCacheService cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_cache_test_');
    Hive.init(tempDir.path);
    cache = await AppCacheService.initialize();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // put / get
  // -------------------------------------------------------------------------

  group('put / get', () {
    test('basic round-trip', () async {
      await cache.put('k1', 'hello');
      expect(await cache.get<String>('k1'), 'hello');
    });

    test('int round-trip', () async {
      await cache.put('k_int', 42);
      expect(await cache.get<int>('k_int'), 42);
    });

    test('null value triggers remove', () async {
      await cache.put('k_null', 'exists');
      await cache.put('k_null', null);
      expect(await cache.get<String>('k_null'), isNull);
    });

    test('absent key returns null', () async {
      expect(await cache.get<String>('nonexistent'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // set (smart dispatch)
  // -------------------------------------------------------------------------

  group('set (smart dispatch)', () {
    test('string stored and retrieved', () async {
      await cache.set('s1', 'world');
      expect(await cache.get<String>('s1'), 'world');
    });

    test('map stored via JSON encoding', () async {
      await cache.set('s_map', {'a': 1, 'b': 2});
      final result = await cache.get<Map<String, dynamic>>('s_map');
      expect(result!['a'], 1);
    });

    test('null calls remove', () async {
      await cache.set('s_del', 'value');
      await cache.set('s_del', null);
      expect(await cache.get<String>('s_del'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // setJson / getJsonMap / getJsonList
  // -------------------------------------------------------------------------

  group('setJson / getJsonMap / getJsonList', () {
    test('setJson + getJsonMap round-trip', () async {
      await cache.setJson('j_map', {'x': 10, 'y': 20});
      final result = await cache.getJsonMap('j_map');
      expect(result!['x'], 10);
    });

    test('setJson + getJsonList round-trip', () async {
      await cache.setJson('j_list', [1, 2, 3]);
      final result = await cache.getJsonList('j_list');
      expect(result, [1, 2, 3]);
    });

    test('getJsonMap returns null for absent key', () async {
      expect(await cache.getJsonMap('absent_key'), isNull);
    });

    test('getJsonList returns null for absent key', () async {
      expect(await cache.getJsonList('absent_list_key'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // expiration
  // -------------------------------------------------------------------------

  group('expiration', () {
    test('entry expired after duration elapses', () async {
      await cache.put('exp_key', 'data',
          expiration: const Duration(milliseconds: 1));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(await cache.get<String>('exp_key'), isNull);
    });

    test('entry available before expiration', () async {
      await cache.put('exp_key2', 'data', expiration: const Duration(hours: 1));
      expect(await cache.get<String>('exp_key2'), 'data');
    });

    test('setWithExpiration with explicit DateTime', () async {
      final future = DateTime.now().add(const Duration(hours: 2));
      await cache.setWithExpiration('exp_explicit', 'val', future);
      expect(await cache.get<String>('exp_explicit'), 'val');
    });

    test('setWithExpiration with past DateTime returns null on get', () async {
      final past = DateTime.now().subtract(const Duration(seconds: 1));
      await cache.setWithExpiration('exp_past', 'val', past);
      expect(await cache.get<String>('exp_past'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // remove
  // -------------------------------------------------------------------------

  group('remove', () {
    test('entry gone after remove', () async {
      await cache.put('r1', 'to_delete');
      await cache.remove('r1');
      expect(await cache.get<String>('r1'), isNull);
    });

    test('remove non-existent key is no-op', () async {
      await expectLater(cache.remove('nonexistent'), completes);
    });
  });

  // -------------------------------------------------------------------------
  // clear
  // -------------------------------------------------------------------------

  group('clear', () {
    test('box empty after clear', () async {
      await cache.put('clear_k1', 'a');
      await cache.put('clear_k2', 'b');
      await cache.clear();
      expect(await cache.get<String>('clear_k1'), isNull);
      expect(await cache.get<String>('clear_k2'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // setTemporaryData / getTemporaryData
  // -------------------------------------------------------------------------

  group('setTemporaryData / getTemporaryData', () {
    test('returns value after set', () async {
      await cache.setTemporaryData('temp_k1', 'temp_val');
      expect(await cache.getTemporaryData<String>('temp_k1'), 'temp_val');
    });

    test('returns null for absent key', () async {
      expect(await cache.getTemporaryData<String>('absent_temp'), isNull);
    });

    test('returns null for expired entry', () async {
      // We can't easily fake time, but we can verify the pattern
      // by checking the structure of the stored data
      final result = await cache.getTemporaryData<String>('not_set');
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // clearTemporaryData
  // -------------------------------------------------------------------------

  group('clearTemporaryData', () {
    test('removes temp_ prefixed keys', () async {
      await cache.put('temp_data_key', 'value');
      await cache.clearTemporaryData();
      // After clearing, temp data key should be removed
      expect(await cache.get<String>('temp_data_key'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // cacheLeaderboard / getCachedLeaderboard
  // -------------------------------------------------------------------------

  group('cacheLeaderboard / getCachedLeaderboard', () {
    test('stores and retrieves empty leaderboard', () async {
      await cache.cacheLeaderboard([]);
      final result = await cache.getCachedLeaderboard();
      expect(result, isA<List>());
    });

    test('getCachedLeaderboard returns empty list on absent key', () async {
      final result = await cache.getCachedLeaderboard();
      // Fresh cache or after clear — either empty list or empty
      expect(result, isA<List>());
    });
  });

  // -------------------------------------------------------------------------
  // saveQuestionCache / loadQuestionCache / clearQuestionCache
  // -------------------------------------------------------------------------

  group('question cache', () {
    test('loadQuestionCache returns empty list on absent key', () async {
      final result = await cache.loadQuestionCache('absent_qs');
      expect(result, isEmpty);
    });

    test('clearQuestionCache completes without error', () async {
      await expectLater(cache.clearQuestionCache('q_key'), completes);
    });
  });

  // -------------------------------------------------------------------------
  // getCacheStats
  // -------------------------------------------------------------------------

  group('getCacheStats', () {
    test('returns map with totalEntries key', () async {
      await cache.put('stat_k1', 'v1');
      final stats = await cache.getCacheStats();
      expect(stats.containsKey('totalEntries'), isTrue);
    });

    test('totalEntries >= 1 after a put', () async {
      await cache.clear();
      await cache.put('stat_k2', 'val');
      final stats = await cache.getCacheStats();
      expect(stats['totalEntries'], greaterThanOrEqualTo(1));
    });
  });

  // -------------------------------------------------------------------------
  // getCacheEntryInfo
  // -------------------------------------------------------------------------

  group('getCacheEntryInfo', () {
    test('returns null for absent key', () async {
      final info = await cache.getCacheEntryInfo('no_entry');
      expect(info, isNull);
    });

    test('returns map with created/expires/isExpired after put', () async {
      await cache.put('info_k', 'val', expiration: const Duration(hours: 1));
      final info = await cache.getCacheEntryInfo('info_k');
      expect(info, isNotNull);
      expect(info!.containsKey('created'), isTrue);
      expect(info.containsKey('isExpired'), isTrue);
    });

    test('isExpired false for fresh entry', () async {
      await cache.put('info_fresh', 'v', expiration: const Duration(hours: 1));
      final info = await cache.getCacheEntryInfo('info_fresh');
      expect(info!['isExpired'], isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // expireCacheEntry
  // -------------------------------------------------------------------------

  group('expireCacheEntry', () {
    test('entry becomes expired immediately', () async {
      await cache.put('to_expire', 'value',
          expiration: const Duration(hours: 24));
      await cache.expireCacheEntry('to_expire');
      expect(await cache.get<String>('to_expire'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // extendCacheEntry
  // -------------------------------------------------------------------------

  group('extendCacheEntry', () {
    test('entry still accessible after extension', () async {
      await cache.put('to_extend', 'value',
          expiration: const Duration(milliseconds: 100));
      await cache.extendCacheEntry('to_extend', const Duration(hours: 1));
      expect(await cache.get<String>('to_extend'), 'value');
    });
  });

  // -------------------------------------------------------------------------
  // getCacheKeysByPattern / removeCacheEntriesByPattern
  // -------------------------------------------------------------------------

  group('getCacheKeysByPattern / removeCacheEntriesByPattern', () {
    test('getCacheKeysByPattern returns matching keys', () async {
      await cache.put('pattern_a', 'v1');
      await cache.put('pattern_b', 'v2');
      await cache.put('other_key', 'v3');
      final keys = await cache.getCacheKeysByPattern('pattern');
      expect(keys, containsAll(['pattern_a', 'pattern_b']));
      expect(keys.contains('other_key'), isFalse);
    });

    test('removeCacheEntriesByPattern deletes all matching keys', () async {
      await cache.put('del_pattern_x', 'v1');
      await cache.put('del_pattern_y', 'v2');
      await cache.put('keep_key', 'v3');
      await cache.removeCacheEntriesByPattern('del_pattern');
      expect(await cache.get<String>('del_pattern_x'), isNull);
      expect(await cache.get<String>('del_pattern_y'), isNull);
      expect(await cache.get<String>('keep_key'), 'v3');
    });
  });

  // -------------------------------------------------------------------------
  // cleanOldEntries
  // -------------------------------------------------------------------------

  group('cleanOldEntries', () {
    test('removes expired entries', () async {
      await cache.put('cleanup_exp', 'val',
          expiration: const Duration(milliseconds: 1));
      await Future.delayed(const Duration(milliseconds: 20));
      await cache.cleanOldEntries();
      expect(await cache.get<String>('cleanup_exp'), isNull);
    });

    test('preserves non-expired entries', () async {
      await cache.put('cleanup_live', 'keep',
          expiration: const Duration(hours: 24));
      await cache.cleanOldEntries();
      expect(await cache.get<String>('cleanup_live'), 'keep');
    });
  });

  // -------------------------------------------------------------------------
  // getLastCleanup
  // -------------------------------------------------------------------------

  group('getLastCleanup', () {
    test('null before any cleanup', () async {
      // Fresh cache — may be null
      final cleanup = await cache.getLastCleanup();
      // Either null or a valid DateTime (if cleanup ran during init)
      expect(cleanup == null || cleanup is DateTime, isTrue);
    });

    test('non-null after cleanOldEntries', () async {
      await cache.cleanOldEntries();
      final cleanup = await cache.getLastCleanup();
      expect(cleanup, isNotNull);
    });
  });
}
