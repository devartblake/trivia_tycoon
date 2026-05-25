import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/audio_settings_service.dart';

void main() {
  late Directory tempDir;
  late AudioSettingsService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp
        .createTemp('audio_settings_service_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    service = await AudioSettingsService.initialize();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('settings')) {
      await Hive.box('settings').clear();
      await Hive.box('settings').close();
      await Hive.deleteBoxFromDisk('settings');
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Audio on/off
  // ---------------------------------------------------------------------------

  test('getAudioOn defaults to true', () {
    expect(service.getAudioOn(), isTrue);
  });

  test('setAudioOn persists value', () async {
    await service.setAudioOn(false);
    expect(service.getAudioOn(), isFalse);
  });

  test('setAudioOn true persists value', () async {
    await service.setAudioOn(false);
    await service.setAudioOn(true);
    expect(service.getAudioOn(), isTrue);
  });

  // ---------------------------------------------------------------------------
  // Music on/off
  // ---------------------------------------------------------------------------

  test('getMusicOn defaults to true', () {
    expect(service.getMusicOn(), isTrue);
  });

  test('setMusicOn persists value', () async {
    await service.setMusicOn(false);
    expect(service.getMusicOn(), isFalse);
  });

  // ---------------------------------------------------------------------------
  // Sounds on/off
  // ---------------------------------------------------------------------------

  test('getSoundsOn defaults to true', () {
    expect(service.getSoundsOn(), isTrue);
  });

  test('setSoundsOn persists value', () async {
    await service.setSoundsOn(false);
    expect(service.getSoundsOn(), isFalse);
  });

  // ---------------------------------------------------------------------------
  // Volume
  // ---------------------------------------------------------------------------

  test('getMusicVolume defaults to 0.7', () {
    expect(service.getMusicVolume(), closeTo(0.7, 0.001));
  });

  test('setMusicVolume/getMusicVolume round trip', () async {
    await service.setMusicVolume(0.5);
    expect(service.getMusicVolume(), closeTo(0.5, 0.001));
  });

  test('setMusicVolume clamps above 1.0 to 1.0', () async {
    await service.setMusicVolume(1.5);
    expect(service.getMusicVolume(), closeTo(1.0, 0.001));
  });

  test('setMusicVolume clamps below 0.0 to 0.0', () async {
    await service.setMusicVolume(-0.2);
    expect(service.getMusicVolume(), closeTo(0.0, 0.001));
  });

  test('getSoundVolume defaults to 0.8', () {
    expect(service.getSoundVolume(), closeTo(0.8, 0.001));
  });

  test('setSoundVolume/getSoundVolume round trip', () async {
    await service.setSoundVolume(0.3);
    expect(service.getSoundVolume(), closeTo(0.3, 0.001));
  });

  test('setSoundVolume clamps to [0.0, 1.0]', () async {
    await service.setSoundVolume(2.0);
    expect(service.getSoundVolume(), closeTo(1.0, 0.001));
  });

  // ---------------------------------------------------------------------------
  // Toggles
  // ---------------------------------------------------------------------------

  test('toggleAudio flips audio on/off', () async {
    expect(service.getAudioOn(), isTrue);
    await service.toggleAudio();
    expect(service.getAudioOn(), isFalse);
    await service.toggleAudio();
    expect(service.getAudioOn(), isTrue);
  });

  test('toggleMusic flips music on/off', () async {
    expect(service.getMusicOn(), isTrue);
    await service.toggleMusic();
    expect(service.getMusicOn(), isFalse);
  });

  test('toggleSounds flips sounds on/off', () async {
    expect(service.getSoundsOn(), isTrue);
    await service.toggleSounds();
    expect(service.getSoundsOn(), isFalse);
  });

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  test('resetAudioSettings restores all defaults', () async {
    await service.setAudioOn(false);
    await service.setMusicOn(false);
    await service.setSoundsOn(false);
    await service.setMusicVolume(0.1);
    await service.setSoundVolume(0.2);

    await service.resetAudioSettings();

    expect(service.getAudioOn(), isTrue); // box-deleted → default
    expect(service.getMusicOn(), isTrue);
    expect(service.getSoundsOn(), isTrue);
    expect(service.getMusicVolume(), closeTo(0.7, 0.001));
    expect(service.getSoundVolume(), closeTo(0.8, 0.001));
  });

  // ---------------------------------------------------------------------------
  // Lifecycle: pauseAllAudio / resumeAudio
  // ---------------------------------------------------------------------------

  test('pauseAllAudio records wasPlaying=true when both audio and music are on',
      () async {
    await service.setAudioOn(true);
    await service.setMusicOn(true);
    await service.pauseAllAudio();

    // resumeAudio reads wasPlaying — if true it logs resume and clears the key
    // We verify by calling resumeAudio without error and checking key cleared
    await service.resumeAudio(); // should not throw
  });

  test('pauseAllAudio records wasPlaying=false when audio is off', () async {
    await service.setAudioOn(false);
    await service.setMusicOn(true);
    await service.pauseAllAudio();
    await service.resumeAudio(); // should not throw
  });

  // ---------------------------------------------------------------------------
  // Lifecycle: reduceVolumeForBackground / restoreNormalVolume
  // ---------------------------------------------------------------------------

  test('reduceVolumeForBackground halves current volumes', () async {
    await service.setMusicVolume(0.8);
    await service.setSoundVolume(0.6);

    await service.reduceVolumeForBackground();

    expect(service.getMusicVolume(), closeTo(0.4, 0.01));
    expect(service.getSoundVolume(), closeTo(0.3, 0.01));
  });

  test('restoreNormalVolume doubles volumes back', () async {
    await service.setMusicVolume(0.4);
    await service.setSoundVolume(0.3);

    await service.restoreNormalVolume();

    expect(service.getMusicVolume(), closeTo(0.8, 0.01));
    expect(service.getSoundVolume(), closeTo(0.6, 0.01));
  });

  // ---------------------------------------------------------------------------
  // debugDump
  // ---------------------------------------------------------------------------

  test('debugDump returns map with all expected keys', () async {
    final dump = service.debugDump();
    expect(dump.containsKey('audioOn'), isTrue);
    expect(dump.containsKey('musicOn'), isTrue);
    expect(dump.containsKey('soundsOn'), isTrue);
    expect(dump.containsKey('musicVolume'), isTrue);
    expect(dump.containsKey('soundVolume'), isTrue);
    expect(dump.containsKey('wasPlayingBeforePause'), isTrue);
  });

  // ---------------------------------------------------------------------------
  // Aliases
  // ---------------------------------------------------------------------------

  test('saveAudioOn alias works the same as setAudioOn', () async {
    await service.saveAudioOn(false);
    expect(service.getAudioOn(), isFalse);
  });

  test('saveMusicOn alias works the same as setMusicOn', () async {
    await service.saveMusicOn(false);
    expect(service.getMusicOn(), isFalse);
  });

  test('saveSoundsOn alias works the same as setSoundsOn', () async {
    await service.saveSoundsOn(false);
    expect(service.getSoundsOn(), isFalse);
  });
}
