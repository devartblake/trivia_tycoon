import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:synaptix/core/services/settings/confetti_settings_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('confetti_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  ConfettiSettingsService makeService() => ConfettiSettingsService();

  // -------------------------------------------------------------------------
  // theme
  // -------------------------------------------------------------------------

  group('saveTheme / getTheme', () {
    test('defaults to "default"', () async {
      expect(await makeService().getTheme(), 'default');
    });

    test('stores and retrieves theme name', () async {
      final svc = makeService();
      await svc.saveTheme('rainbow');
      expect(await svc.getTheme(), 'rainbow');
    });
  });

  // -------------------------------------------------------------------------
  // speed
  // -------------------------------------------------------------------------

  group('saveSpeed / getSpeed', () {
    test('defaults to 1.0', () async {
      expect(await makeService().getSpeed(), 1.0);
    });

    test('stores and retrieves custom speed', () async {
      final svc = makeService();
      await svc.saveSpeed(2.5);
      expect(await svc.getSpeed(), 2.5);
    });
  });

  // -------------------------------------------------------------------------
  // particle count
  // -------------------------------------------------------------------------

  group('saveParticleCount / getParticleCount', () {
    test('defaults to 100', () async {
      expect(await makeService().getParticleCount(), 100);
    });

    test('stores and retrieves custom count', () async {
      final svc = makeService();
      await svc.saveParticleCount(250);
      expect(await svc.getParticleCount(), 250);
    });
  });

  // -------------------------------------------------------------------------
  // colors
  // -------------------------------------------------------------------------

  group('saveColors / getColors', () {
    test('defaults to empty list', () async {
      expect(await makeService().getColors(), isEmpty);
    });

    test('stores and retrieves color list', () async {
      final svc = makeService();
      await svc.saveColors([0xFFFF0000, 0xFF00FF00, 0xFF0000FF]);
      expect(await svc.getColors(), [0xFFFF0000, 0xFF00FF00, 0xFF0000FF]);
    });
  });

  // -------------------------------------------------------------------------
  // preset
  // -------------------------------------------------------------------------

  group('savePreset / getPreset', () {
    test('defaults to "default"', () async {
      expect(await makeService().getPreset(), 'default');
    });

    test('stores and retrieves preset name', () async {
      final svc = makeService();
      await svc.savePreset('celebration');
      expect(await svc.getPreset(), 'celebration');
    });
  });

  // -------------------------------------------------------------------------
  // density
  // -------------------------------------------------------------------------

  group('saveDensity / getDensity', () {
    test('defaults to "Auto"', () async {
      expect(await makeService().getDensity(), 'Auto');
    });

    test('stores and retrieves custom density', () async {
      final svc = makeService();
      await svc.saveDensity('High');
      expect(await svc.getDensity(), 'High');
    });
  });

  // -------------------------------------------------------------------------
  // All settings are independent keys
  // -------------------------------------------------------------------------

  test('all settings can be set without interfering with each other', () async {
    final svc = makeService();
    await svc.saveTheme('fire');
    await svc.saveSpeed(3.0);
    await svc.saveParticleCount(500);
    await svc.saveColors([0xFFFFFFFF]);
    await svc.savePreset('fireworks');
    await svc.saveDensity('Low');

    expect(await svc.getTheme(), 'fire');
    expect(await svc.getSpeed(), 3.0);
    expect(await svc.getParticleCount(), 500);
    expect(await svc.getColors(), [0xFFFFFFFF]);
    expect(await svc.getPreset(), 'fireworks');
    expect(await svc.getDensity(), 'Low');
  });
}
