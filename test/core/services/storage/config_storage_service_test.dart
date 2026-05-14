import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/storage/config_storage_service.dart';

void main() {
  late Directory tempDir;
  late ConfigStorageService svc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('config_storage_test_');
    Hive.init(tempDir.path);
    svc = ConfigStorageService();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // saveConfig / getConfig
  // -------------------------------------------------------------------------

  group('saveConfig / getConfig', () {
    test('stores and retrieves a string', () async {
      await svc.saveConfig('theme', 'dark');
      expect(await svc.getConfig('theme'), 'dark');
    });

    test('stores and retrieves an int', () async {
      await svc.saveConfig('maxRetries', 3);
      expect(await svc.getConfig('maxRetries'), 3);
    });

    test('stores and retrieves a bool', () async {
      await svc.saveConfig('debug', true);
      expect(await svc.getConfig('debug'), isTrue);
    });

    test('returns null for missing key', () async {
      expect(await svc.getConfig('not_present'), isNull);
    });

    test('overwrites previous value', () async {
      await svc.saveConfig('mode', 'easy');
      await svc.saveConfig('mode', 'hard');
      expect(await svc.getConfig('mode'), 'hard');
    });

    test('stores map value', () async {
      final map = {'key': 'value', 'num': 42};
      await svc.saveConfig('complex', map);
      final result = await svc.getConfig('complex') as Map;
      expect(result['key'], 'value');
      expect(result['num'], 42);
    });
  });

  // -------------------------------------------------------------------------
  // removeConfig
  // -------------------------------------------------------------------------

  group('removeConfig', () {
    test('removes an existing key', () async {
      await svc.saveConfig('to_delete', 'bye');
      await svc.removeConfig('to_delete');
      expect(await svc.getConfig('to_delete'), isNull);
    });

    test('removing non-existent key does not throw', () async {
      await expectLater(svc.removeConfig('ghost'), completes);
    });

    test('removing one key does not affect others', () async {
      await svc.saveConfig('a', 'alpha');
      await svc.saveConfig('b', 'beta');
      await svc.removeConfig('a');
      expect(await svc.getConfig('a'), isNull);
      expect(await svc.getConfig('b'), 'beta');
    });
  });

  // -------------------------------------------------------------------------
  // getAllConfigKeys
  // -------------------------------------------------------------------------

  group('getAllConfigKeys', () {
    test('returns empty list when no configs stored', () async {
      expect(await svc.getAllConfigKeys(), isEmpty);
    });

    test('returns all stored keys', () async {
      await svc.saveConfig('k1', 1);
      await svc.saveConfig('k2', 2);
      await svc.saveConfig('k3', 3);
      final keys = await svc.getAllConfigKeys();
      expect(keys, containsAll(['k1', 'k2', 'k3']));
      expect(keys.length, 3);
    });

    test('excludes removed key', () async {
      await svc.saveConfig('keep', 'yes');
      await svc.saveConfig('remove', 'no');
      await svc.removeConfig('remove');
      final keys = await svc.getAllConfigKeys();
      expect(keys, contains('keep'));
      expect(keys, isNot(contains('remove')));
    });
  });

  // -------------------------------------------------------------------------
  // clearAllConfigs
  // -------------------------------------------------------------------------

  group('clearAllConfigs', () {
    test('clears all entries', () async {
      await svc.saveConfig('x', 1);
      await svc.saveConfig('y', 2);
      await svc.clearAllConfigs();
      expect(await svc.getAllConfigKeys(), isEmpty);
    });

    test('getConfig returns null after clear', () async {
      await svc.saveConfig('alive', 'yes');
      await svc.clearAllConfigs();
      expect(await svc.getConfig('alive'), isNull);
    });

    test('can save new entries after clearing', () async {
      await svc.saveConfig('old', 'value');
      await svc.clearAllConfigs();
      await svc.saveConfig('new', 'fresh');
      expect(await svc.getConfig('new'), 'fresh');
      expect(await svc.getAllConfigKeys(), ['new']);
    });
  });
}
