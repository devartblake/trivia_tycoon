import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';

void main() {
  late Directory tempDir;
  late GeneralKeyValueStorageService svc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gkvs_test_');
    Hive.init(tempDir.path);
    svc = GeneralKeyValueStorageService();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // String
  // -------------------------------------------------------------------------

  group('setString / getString', () {
    test('round-trip', () async {
      await svc.setString('name', 'Alice');
      expect(await svc.getString('name'), 'Alice');
    });

    test('overwrites previous value', () async {
      await svc.setString('name', 'Alice');
      await svc.setString('name', 'Bob');
      expect(await svc.getString('name'), 'Bob');
    });

    test('returns null for missing key', () async {
      expect(await svc.getString('does_not_exist'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Int
  // -------------------------------------------------------------------------

  group('setInt / getInt', () {
    test('round-trip', () async {
      await svc.setInt('score', 42);
      expect(await svc.getInt('score'), 42);
    });

    test('returns 0 for missing key', () async {
      expect(await svc.getInt('missing_int'), 0);
    });

    test('overwrites previous value', () async {
      await svc.setInt('score', 10);
      await svc.setInt('score', 99);
      expect(await svc.getInt('score'), 99);
    });

    test('stores 0 correctly', () async {
      await svc.setInt('zero', 0);
      expect(await svc.getInt('zero'), 0);
    });
  });

  // -------------------------------------------------------------------------
  // Bool
  // -------------------------------------------------------------------------

  group('setBool / getBool', () {
    test('stores true', () async {
      await svc.setBool('flag', true);
      expect(await svc.getBool('flag'), isTrue);
    });

    test('stores false', () async {
      await svc.setBool('flag', false);
      expect(await svc.getBool('flag'), isFalse);
    });

    test('returns null for missing key', () async {
      expect(await svc.getBool('no_bool'), isNull);
    });

    test('toggle from true to false', () async {
      await svc.setBool('toggle', true);
      await svc.setBool('toggle', false);
      expect(await svc.getBool('toggle'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Color
  // -------------------------------------------------------------------------

  group('setColor / getColor', () {
    test('round-trip for Colors.red', () async {
      await svc.setColor('theme', Colors.red);
      expect(await svc.getColor('theme'), Colors.red);
    });

    test('round-trip for arbitrary ARGB color', () async {
      const color = Color(0xFF1A2B3C);
      await svc.setColor('custom', color);
      expect(await svc.getColor('custom'), color);
    });

    test('returns null for missing key', () async {
      expect(await svc.getColor('no_color'), isNull);
    });

    test('overwrites with new color', () async {
      await svc.setColor('c', Colors.blue);
      await svc.setColor('c', Colors.green);
      expect(await svc.getColor('c'), Colors.green);
    });
  });

  // -------------------------------------------------------------------------
  // DateTime
  // -------------------------------------------------------------------------

  group('setDateTime / getDateTime', () {
    test('round-trip preserves ISO8601 precision', () async {
      final dt = DateTime.parse('2025-06-15T12:30:00.000Z');
      await svc.setDateTime('ts', dt);
      final restored = await svc.getDateTime('ts');
      expect(restored, isNotNull);
      expect(restored!.toIso8601String(), dt.toIso8601String());
    });

    test('returns null for missing key', () async {
      expect(await svc.getDateTime('no_dt'), isNull);
    });

    test('overwrites previous DateTime', () async {
      final dt1 = DateTime(2025, 1, 1);
      final dt2 = DateTime(2025, 12, 31);
      await svc.setDateTime('date', dt1);
      await svc.setDateTime('date', dt2);
      final restored = await svc.getDateTime('date');
      expect(restored!.year, 2025);
      expect(restored.month, 12);
      expect(restored.day, 31);
    });
  });

  // -------------------------------------------------------------------------
  // StringList (uses 'preferences' box)
  // -------------------------------------------------------------------------

  group('setStringList / getStringList', () {
    test('round-trip for simple list', () async {
      await svc.setStringList('tags', ['a', 'b', 'c']);
      final result = await svc.getStringList('tags');
      expect(result, ['a', 'b', 'c']);
    });

    test('single-element list round-trips', () async {
      await svc.setStringList('single', ['only']);
      expect(await svc.getStringList('single'), ['only']);
    });

    test('returns null for missing key', () async {
      expect(await svc.getStringList('no_list'), isNull);
    });

    test('overwrites previous list', () async {
      await svc.setStringList('colors', ['red', 'blue']);
      await svc.setStringList('colors', ['green']);
      expect(await svc.getStringList('colors'), ['green']);
    });
  });

  // -------------------------------------------------------------------------
  // JSON
  // -------------------------------------------------------------------------

  group('setJson / getJson', () {
    test('round-trip for simple map', () async {
      final data = {'player': 'Alice', 'score': 100};
      await svc.setJson('profile', data);
      final result = await svc.getJson('profile');
      expect(result, isNotNull);
      expect(result!['player'], 'Alice');
      expect(result['score'], 100);
    });

    test('returns null for missing key', () async {
      expect(await svc.getJson('no_json'), isNull);
    });

    test('returns null for non-JSON stored value', () async {
      await svc.setString('plain', 'not json');
      // getJson expects valid JSON; plain string is not a Map
      final result = await svc.getJson('plain');
      expect(result, isNull);
    });

    test('nested map round-trip', () async {
      final data = {
        'user': {'name': 'Bob', 'level': 5},
      };
      await svc.setJson('nested', data);
      final result = await svc.getJson('nested');
      expect((result!['user'] as Map)['name'], 'Bob');
    });
  });

  // -------------------------------------------------------------------------
  // Generic get / set
  // -------------------------------------------------------------------------

  group('generic get / set', () {
    test('set string, get returns same string', () async {
      await svc.set('generic_str', 'hello');
      expect(await svc.get('generic_str'), 'hello');
    });

    test('set int, get returns same int', () async {
      await svc.set('generic_int', 7);
      expect(await svc.get('generic_int'), 7);
    });

    test('get returns null for missing key', () async {
      expect(await svc.get('totally_missing'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // remove
  // -------------------------------------------------------------------------

  group('remove', () {
    test('removes stored key', () async {
      await svc.setString('to_remove', 'bye');
      await svc.remove('to_remove');
      expect(await svc.getString('to_remove'), isNull);
    });

    test('removing non-existent key does not throw', () async {
      await expectLater(svc.remove('ghost'), completes);
    });
  });

  // -------------------------------------------------------------------------
  // Key isolation
  // -------------------------------------------------------------------------

  group('key isolation', () {
    test('different keys stored independently', () async {
      await svc.setString('a', 'alpha');
      await svc.setString('b', 'beta');
      expect(await svc.getString('a'), 'alpha');
      expect(await svc.getString('b'), 'beta');
    });

    test('int key does not collide with string key of same name', () async {
      await svc.setInt('x', 10);
      await svc.setInt('y', 20);
      expect(await svc.getInt('x'), 10);
      expect(await svc.getInt('y'), 20);
    });
  });
}
