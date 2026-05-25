import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/theme/swatch_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('swatch_service_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // loadSwatches / saveSwatches
  // -------------------------------------------------------------------------

  group('saveSwatches / loadSwatches', () {
    test('returns empty list when nothing stored', () async {
      expect(await SwatchService.loadSwatches(), isEmpty);
    });

    test('round-trip preserves fully-opaque colors', () async {
      final colors = [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
      ];
      await SwatchService.saveSwatches(colors);
      final loaded = await SwatchService.loadSwatches();
      expect(loaded.length, colors.length);
      for (var i = 0; i < colors.length; i++) {
        expect(loaded[i].value, colors[i].value);
      }
    });

    test('overwrites previous swatches', () async {
      await SwatchService.saveSwatches([const Color(0xFFFF0000)]);
      await SwatchService.saveSwatches([
        const Color(0xFF123456),
        const Color(0xFF654321),
      ]);
      final loaded = await SwatchService.loadSwatches();
      expect(loaded.length, 2);
      expect(loaded[0].value, const Color(0xFF123456).value);
    });

    test('single color round-trip', () async {
      await SwatchService.saveSwatches([const Color(0xFFABCDEF)]);
      final loaded = await SwatchService.loadSwatches();
      expect(loaded.length, 1);
      expect(loaded[0].value, const Color(0xFFABCDEF).value);
    });
  });

  // -------------------------------------------------------------------------
  // resetSwatches
  // -------------------------------------------------------------------------

  group('resetSwatches', () {
    test('clears previously saved swatches', () async {
      await SwatchService.saveSwatches([const Color(0xFFFF0000)]);
      await SwatchService.resetSwatches();
      expect(await SwatchService.loadSwatches(), isEmpty);
    });

    test('resetSwatchesToDefault also clears swatches', () async {
      await SwatchService.saveSwatches([const Color(0xFFFF0000)]);
      await SwatchService.resetSwatchesToDefault();
      expect(await SwatchService.loadSwatches(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // hasCustomSwatches
  // -------------------------------------------------------------------------

  group('hasCustomSwatches', () {
    test('returns false when nothing stored', () async {
      expect(await SwatchService.hasCustomSwatches(), isFalse);
    });

    test('returns true after saving swatches', () async {
      await SwatchService.saveSwatches([const Color(0xFFFF0000)]);
      expect(await SwatchService.hasCustomSwatches(), isTrue);
    });

    test('returns false after reset', () async {
      await SwatchService.saveSwatches([const Color(0xFFFF0000)]);
      await SwatchService.resetSwatches();
      expect(await SwatchService.hasCustomSwatches(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // setCustomSwatches / getCustomSwatches
  // -------------------------------------------------------------------------

  group('setCustomSwatches / getCustomSwatches', () {
    test('returns empty list when nothing stored', () async {
      expect(await SwatchService.getCustomSwatches(), isEmpty);
    });

    test('round-trip via setCustomSwatches / getCustomSwatches', () async {
      final colors = [const Color(0xFFAABBCC), const Color(0xFF112233)];
      await SwatchService.setCustomSwatches(colors);
      final loaded = await SwatchService.getCustomSwatches();
      expect(loaded.length, 2);
      expect(loaded[0].value, colors[0].value);
      expect(loaded[1].value, colors[1].value);
    });

    test('setCustomSwatches and saveSwatches share the same key', () async {
      await SwatchService.setCustomSwatches([const Color(0xFF010101)]);
      final viaLoad = await SwatchService.loadSwatches();
      expect(viaLoad.length, 1);
      expect(viaLoad[0].value, const Color(0xFF010101).value);
    });
  });
}
