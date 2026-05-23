import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/audio_settings_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('audio_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<AudioSettingsService> _make() => AudioSettingsService.initialize();

  // -------------------------------------------------------------------------
  // Audio on/off
  // -------------------------------------------------------------------------

  group('getAudioOn / setAudioOn', () {
    test('defaults to true', () async {
      final svc = await _make();
      expect(svc.getAudioOn(), isTrue);
    });

    test('stores and retrieves false', () async {
      final svc = await _make();
      await svc.setAudioOn(false);
      expect(svc.getAudioOn(), isFalse);
    });

    test('stores and retrieves true', () async {
      final svc = await _make();
      await svc.setAudioOn(false);
      await svc.setAudioOn(true);
      expect(svc.getAudioOn(), isTrue);
    });
  });

  group('getMusicOn / setMusicOn', () {
    test('defaults to true', () async {
      final svc = await _make();
      expect(svc.getMusicOn(), isTrue);
    });

    test('stores false correctly', () async {
      final svc = await _make();
      await svc.setMusicOn(false);
      expect(svc.getMusicOn(), isFalse);
    });
  });

  group('getSoundsOn / setSoundsOn', () {
    test('defaults to true', () async {
      final svc = await _make();
      expect(svc.getSoundsOn(), isTrue);
    });

    test('stores false correctly', () async {
      final svc = await _make();
      await svc.setSoundsOn(false);
      expect(svc.getSoundsOn(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Volume clamping
  // -------------------------------------------------------------------------

  group('setMusicVolume — clamping', () {
    test('stores 0.5 unchanged', () async {
      final svc = await _make();
      await svc.setMusicVolume(0.5);
      expect(svc.getMusicVolume(), closeTo(0.5, 0.001));
    });

    test('clamps below 0.0 to 0.0', () async {
      final svc = await _make();
      await svc.setMusicVolume(-0.1);
      expect(svc.getMusicVolume(), closeTo(0.0, 0.001));
    });

    test('clamps above 1.0 to 1.0', () async {
      final svc = await _make();
      await svc.setMusicVolume(1.5);
      expect(svc.getMusicVolume(), closeTo(1.0, 0.001));
    });

    test('accepts 0.0 exactly', () async {
      final svc = await _make();
      await svc.setMusicVolume(0.0);
      expect(svc.getMusicVolume(), closeTo(0.0, 0.001));
    });

    test('accepts 1.0 exactly', () async {
      final svc = await _make();
      await svc.setMusicVolume(1.0);
      expect(svc.getMusicVolume(), closeTo(1.0, 0.001));
    });

    test('getMusicVolume defaults to 0.7', () async {
      final svc = await _make();
      expect(svc.getMusicVolume(), closeTo(0.7, 0.001));
    });
  });

  group('setSoundVolume — clamping', () {
    test('clamps below 0.0 to 0.0', () async {
      final svc = await _make();
      await svc.setSoundVolume(-5.0);
      expect(svc.getSoundVolume(), closeTo(0.0, 0.001));
    });

    test('clamps above 1.0 to 1.0', () async {
      final svc = await _make();
      await svc.setSoundVolume(2.0);
      expect(svc.getSoundVolume(), closeTo(1.0, 0.001));
    });

    test('getSoundVolume defaults to 0.8', () async {
      final svc = await _make();
      expect(svc.getSoundVolume(), closeTo(0.8, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // Toggle helpers
  // -------------------------------------------------------------------------

  group('toggleAudio', () {
    test('flips from default true to false', () async {
      final svc = await _make();
      await svc.toggleAudio();
      expect(svc.getAudioOn(), isFalse);
    });

    test('double-toggle restores original value', () async {
      final svc = await _make();
      final before = svc.getAudioOn();
      await svc.toggleAudio();
      await svc.toggleAudio();
      expect(svc.getAudioOn(), before);
    });
  });

  group('toggleMusic', () {
    test('flips musicOn', () async {
      final svc = await _make();
      await svc.toggleMusic();
      expect(svc.getMusicOn(), isFalse);
    });
  });

  group('toggleSounds', () {
    test('flips soundsOn', () async {
      final svc = await _make();
      await svc.toggleSounds();
      expect(svc.getSoundsOn(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Lifecycle helpers
  // -------------------------------------------------------------------------

  group('pauseAllAudio / resumeAudio', () {
    test('resumeAudio completes without error', () async {
      final svc = await _make();
      await svc.pauseAllAudio();
      await expectLater(svc.resumeAudio(), completes);
    });

    test('resumeAudio clears wasPlayingBeforePause state', () async {
      final svc = await _make();
      await svc.pauseAllAudio();
      await svc.resumeAudio();
      // After resume, debugDump should not retain stale pause state
      final dump = svc.debugDump();
      expect(dump['wasPlayingBeforePause'], isFalse);
    });
  });

  group('reduceVolumeForBackground / restoreNormalVolume', () {
    test('reduceVolumeForBackground halves the music volume', () async {
      final svc = await _make();
      await svc.setMusicVolume(0.8);
      await svc.reduceVolumeForBackground();
      expect(svc.getMusicVolume(), closeTo(0.4, 0.001));
    });

    test('restoreNormalVolume doubles the volume back', () async {
      final svc = await _make();
      await svc.setMusicVolume(0.8);
      await svc.reduceVolumeForBackground(); // now 0.4
      await svc.restoreNormalVolume(); // should be 0.8 again
      expect(svc.getMusicVolume(), closeTo(0.8, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // resetAudioSettings
  // -------------------------------------------------------------------------

  group('resetAudioSettings', () {
    test('returns to defaults after reset', () async {
      final svc = await _make();
      await svc.setAudioOn(false);
      await svc.setMusicVolume(0.1);
      await svc.resetAudioSettings();
      expect(svc.getAudioOn(), isTrue); // default
      expect(svc.getMusicVolume(), closeTo(0.7, 0.001)); // default
    });
  });

  // -------------------------------------------------------------------------
  // debugDump
  // -------------------------------------------------------------------------

  group('debugDump', () {
    test('returns map with all expected keys', () async {
      final svc = await _make();
      final dump = svc.debugDump();
      expect(dump.keys.toSet(), containsAll([
        'audioOn', 'musicOn', 'soundsOn',
        'musicVolume', 'soundVolume', 'wasPlayingBeforePause',
      ]));
    });
  });

  // -------------------------------------------------------------------------
  // saveAudioOn / saveMusicOn / saveSoundsOn aliases
  // -------------------------------------------------------------------------

  group('save* aliases', () {
    test('saveAudioOn delegates to setAudioOn', () async {
      final svc = await _make();
      await svc.saveAudioOn(false);
      expect(svc.getAudioOn(), isFalse);
    });

    test('saveMusicOn delegates to setMusicOn', () async {
      final svc = await _make();
      await svc.saveMusicOn(false);
      expect(svc.getMusicOn(), isFalse);
    });

    test('saveSoundsOn delegates to setSoundsOn', () async {
      final svc = await _make();
      await svc.saveSoundsOn(false);
      expect(svc.getSoundsOn(), isFalse);
    });
  });
}
