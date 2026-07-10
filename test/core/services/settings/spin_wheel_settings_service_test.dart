import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/spin_wheel_settings_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('spin_wheel_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  SpinWheelSettingsService makeService() => SpinWheelSettingsService();

  // -------------------------------------------------------------------------
  // Jackpot time
  // -------------------------------------------------------------------------

  group('setJackpotTime / getJackpotTime', () {
    test('stores and retrieves a DateTime', () async {
      final svc = makeService();
      final now = DateTime(2026, 1, 15, 12, 30, 0);
      await svc.setJackpotTime(now);
      final retrieved = await svc.getJackpotTime();
      expect(retrieved.year, now.year);
      expect(retrieved.month, now.month);
      expect(retrieved.day, now.day);
    });

    test('returns epoch (1970-01-01) as default when nothing stored', () async {
      final svc = makeService();
      final time = await svc.getJackpotTime();
      expect(time.millisecondsSinceEpoch, 0);
    });

    test('overwrites previous jackpot time', () async {
      final svc = makeService();
      final first = DateTime(2025, 1, 1);
      final second = DateTime(2026, 6, 15);
      await svc.setJackpotTime(first);
      await svc.setJackpotTime(second);
      final retrieved = await svc.getJackpotTime();
      expect(retrieved.year, 2026);
    });
  });

  // -------------------------------------------------------------------------
  // Win streak
  // -------------------------------------------------------------------------

  group('setWinStreak / getWinStreak', () {
    test('defaults to 0', () async {
      expect(await makeService().getWinStreak(), 0);
    });

    test('stores and retrieves streak', () async {
      final svc = makeService();
      await svc.setWinStreak(7);
      expect(await svc.getWinStreak(), 7);
    });

    test('overwrites previous streak', () async {
      final svc = makeService();
      await svc.setWinStreak(3);
      await svc.setWinStreak(10);
      expect(await svc.getWinStreak(), 10);
    });
  });

  // -------------------------------------------------------------------------
  // Total spins
  // -------------------------------------------------------------------------

  group('setTotalSpins / getTotalSpins', () {
    test('defaults to 0', () async {
      expect(await makeService().getTotalSpins(), 0);
    });

    test('stores and retrieves spin count', () async {
      final svc = makeService();
      await svc.setTotalSpins(42);
      expect(await svc.getTotalSpins(), 42);
    });
  });

  // -------------------------------------------------------------------------
  // incrementTotalSpins — KNOWN BUG
  // -------------------------------------------------------------------------

  group('incrementTotalSpins — bug: uses string literal key', () {
    test(
        'BUG: incrementTotalSpins writes to string literal "_totalSpinsKey" '
        'instead of constant "totalSpins", so getTotalSpins does not see the increment',
        () async {
      final svc = makeService();
      await svc.setTotalSpins(5);
      await svc.incrementTotalSpins();
      // getTotalSpins reads from 'totalSpins' key (correct constant)
      // but incrementTotalSpins writes to '_totalSpinsKey' (wrong string literal)
      // so the result is still 5, not 6
      expect(await svc.getTotalSpins(), 5);
    });
  });

  // -------------------------------------------------------------------------
  // Segment fetch time — KNOWN BUG
  // -------------------------------------------------------------------------

  group('setSegmentFetchTime / getSegmentFetchTime', () {
    test(
        'BUG: setSegmentFetchTime writes to string literal "_lastSegmentFetchTimeKey" '
        'but getSegmentFetchTime reads from constant "lastSegmentFetchTime", '
        'so getSegmentFetchTime always returns null after set', () async {
      final svc = makeService();
      final t = DateTime(2026, 3, 1, 10, 0, 0);
      await svc.setSegmentFetchTime(t);
      // reads from 'lastSegmentFetchTime' — nothing there because set wrote to '_lastSegmentFetchTimeKey'
      expect(await svc.getSegmentFetchTime(), isNull);
    });

    test('getSegmentFetchTime returns null when nothing is stored', () async {
      expect(await makeService().getSegmentFetchTime(), isNull);
    });
  });
}
