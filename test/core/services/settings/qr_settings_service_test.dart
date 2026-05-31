import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/qr_settings_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('qr_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  QrSettingsService makeService() => QrSettingsService();

  // -------------------------------------------------------------------------
  // getQrScanHistoryLimit
  // -------------------------------------------------------------------------

  group('getQrScanHistoryLimit', () {
    test('returns default 50 when nothing is stored', () async {
      expect(await makeService().getQrScanHistoryLimit(), 50);
    });

    test('returns stored positive integer', () async {
      final svc = makeService();
      await svc.setScanHistoryLimit(100);
      expect(await svc.getQrScanHistoryLimit(), 100);
    });

    test('returns default 50 when stored value is 0 (not positive)', () async {
      final svc = makeService();
      await svc.setScanHistoryLimit(0);
      expect(await svc.getQrScanHistoryLimit(), 50);
    });

    test('returns default 50 when stored value is negative', () async {
      final svc = makeService();
      await svc.setScanHistoryLimit(-10);
      expect(await svc.getQrScanHistoryLimit(), 50);
    });
  });

  // -------------------------------------------------------------------------
  // setScanHistoryLimit
  // -------------------------------------------------------------------------

  group('setScanHistoryLimit', () {
    test('persists the limit', () async {
      final svc = makeService();
      await svc.setScanHistoryLimit(200);
      expect(await svc.getQrScanHistoryLimit(), 200);
    });

    test('overwriting with a new positive value updates the limit', () async {
      final svc = makeService();
      await svc.setScanHistoryLimit(75);
      await svc.setScanHistoryLimit(25);
      expect(await svc.getQrScanHistoryLimit(), 25);
    });

    test('1 is the minimum valid positive value', () async {
      final svc = makeService();
      await svc.setScanHistoryLimit(1);
      expect(await svc.getQrScanHistoryLimit(), 1);
    });
  });
}
