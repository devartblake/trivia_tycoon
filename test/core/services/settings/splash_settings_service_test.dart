import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/navigation/splash_type.dart';
import 'package:trivia_tycoon/core/services/settings/splash_settings_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('splash_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  SplashSettingsService _make() => SplashSettingsService();

  // -------------------------------------------------------------------------
  // getSplashType
  // -------------------------------------------------------------------------

  group('getSplashType', () {
    test('defaults to SplashType.fortuneWheel when nothing stored', () async {
      expect(await _make().getSplashType(), SplashType.fortuneWheel);
    });

    test('returns stored splash type', () async {
      final svc = _make();
      await svc.setSplashType(SplashType.mindMarket);
      expect(await svc.getSplashType(), SplashType.mindMarket);
    });

    test('returns fortuneWheel fallback for unrecognized stored value', () async {
      final box = await Hive.openBox('settings');
      await box.put('splash_type', 'unknown_type_xyz');
      expect(await _make().getSplashType(), SplashType.fortuneWheel);
    });
  });

  // -------------------------------------------------------------------------
  // setSplashType — all enum values
  // -------------------------------------------------------------------------

  group('setSplashType', () {
    for (final type in SplashType.values) {
      test('stores and retrieves ${type.name}', () async {
        final svc = _make();
        await svc.setSplashType(type);
        expect(await svc.getSplashType(), type);
      });
    }

    test('overwrites previous value', () async {
      final svc = _make();
      await svc.setSplashType(SplashType.hqTerminal);
      await svc.setSplashType(SplashType.empireRising);
      expect(await svc.getSplashType(), SplashType.empireRising);
    });
  });

  // -------------------------------------------------------------------------
  // SplashType enum completeness
  // -------------------------------------------------------------------------

  group('SplashType enum', () {
    test('has 5 values', () {
      expect(SplashType.values.length, 5);
    });

    test('contains all expected values', () {
      expect(
        SplashType.values,
        containsAll([
          SplashType.mindMarket,
          SplashType.empireRising,
          SplashType.vaultUnlock,
          SplashType.fortuneWheel,
          SplashType.hqTerminal,
        ]),
      );
    });
  });
}
