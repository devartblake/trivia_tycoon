import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Handles audio and music preferences (on/off)
class AudioSettingsService {
  static const _boxName = 'settings';
  static const _audioOnKey = 'audioOn';
  static const _musicOnKey = 'musicOn';
  static const _soundsOnKey = 'soundsOn';

  final Box _box;

  AudioSettingsService._(this._box);

  static Future<AudioSettingsService> initialize() async {
    final box = await Hive.openBox(_boxName);
    return AudioSettingsService._(box);
  }

  // ------------------------- AUDIO ---------------------------

  Future<void> setAudioOn(bool value) async => await _box.put(_audioOnKey, value);

  bool getAudioOn({bool defaultValue = true}) => _box.get(_audioOnKey, defaultValue: defaultValue);

  // ------------------------- MUSIC ---------------------------

  Future<void> setMusicOn(bool value) async => await _box.put(_musicOnKey, value);

  bool getMusicOn({bool defaultValue = true}) => _box.get(_musicOnKey, defaultValue: defaultValue);

  // ------------------------- SOUND FX ------------------------

  Future<void> setSoundsOn(bool value) async => await _box.put(_soundsOnKey, value);

  bool getSoundsOn({bool defaultValue = true}) => _box.get(_soundsOnKey, defaultValue: defaultValue);

  Future<void> resetAudioSettings() async {
    await _box.delete(_audioOnKey);
    await _box.delete(_musicOnKey);
    await _box.delete(_soundsOnKey);
  }

  Future<void> toggleAudio() async =>
      await setAudioOn(!getAudioOn());

  Future<void> toggleMusic() async =>
      await setMusicOn(!getMusicOn());

  Future<void> toggleSounds() async =>
      await setSoundsOn(!getSoundsOn());

  Map<String, dynamic> debugDump() => {
    'audioOn': getAudioOn(),
    'musicOn': getMusicOn(),
    'soundsOn': getSoundsOn(),
  };

  // Aliases for compatibility with SettingsController
  Future<void> saveAudioOn(bool value) async => await setAudioOn(value);
  Future<void> saveMusicOn(bool value) async => await setMusicOn(value);
  Future<void> saveSoundsOn(bool value) async => await setSoundsOn(value);
}
