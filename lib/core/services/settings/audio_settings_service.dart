import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Handles audio and music preferences (on/off)
class AudioSettingsService {
  static const _boxName = 'settings';
  static const _audioOnKey = 'audioOn';
  static const _musicOnKey = 'musicOn';
  static const _soundsOnKey = 'soundsOn';
  static const _wasPlayingKey = 'wasPlayingBeforePause';
  static const _musicVolumeKey = 'musicVolume';
  static const _soundVolumeKey = 'soundVolume';

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

  // ------------------------- VOLUME CONTROLS -----------------

  Future<void> setMusicVolume(double volume) async => await _box.put(_musicVolumeKey, volume.clamp(0.0, 1.0));

  double getMusicVolume({double defaultValue = 0.7}) => _box.get(_musicVolumeKey, defaultValue: defaultValue);

  Future<void> setSoundVolume(double volume) async => await _box.put(_soundVolumeKey, volume.clamp(0.0, 1.0));

  double getSoundVolume({double defaultValue = 0.8}) => _box.get(_soundVolumeKey, defaultValue: defaultValue);

  // ------------------------- LIFECYCLE METHODS ---------------

  /// Pause all audio (called by AppLifecycleObserver)
  Future<void> pauseAllAudio() async {
    try {
      // Save current playing state before pausing
      final wasPlaying = getMusicOn() && getAudioOn();
      await _box.put(_wasPlayingKey, wasPlaying);

      // Pause music and sounds
      // Note: In a real app, you'd interface with your audio player here
      // For now, we just save the state
      debugPrint('[AudioService] All audio paused, wasPlaying: $wasPlaying');
    } catch (e) {
      debugPrint('[AudioService] Error pausing audio: $e');
    }
  }

  /// Resume audio (called by AppLifecycleObserver)
  Future<void> resumeAudio() async {
    try {
      final wasPlaying = _box.get(_wasPlayingKey, defaultValue: false);

      if (wasPlaying && getMusicOn() && getAudioOn()) {
        // Resume music if it was playing before
        // Note: In a real app, you'd interface with your audio player here
        debugPrint('[AudioService] Resuming audio playback');
      }

      // Clear the pause state
      await _box.delete(_wasPlayingKey);
    } catch (e) {
      debugPrint('[AudioService] Error resuming audio: $e');
    }
  }

  /// Reduce audio volume for background state
  Future<void> reduceVolumeForBackground() async {
    try {
      // Reduce volume by 50% for background state
      final currentMusicVolume = getMusicVolume();
      final currentSoundVolume = getSoundVolume();

      await setMusicVolume(currentMusicVolume * 0.5);
      await setSoundVolume(currentSoundVolume * 0.5);

      debugPrint('[AudioService] Volume reduced for background');
    } catch (e) {
      debugPrint('[AudioService] Error reducing volume: $e');
    }
  }

  /// Restore normal audio volume
  Future<void> restoreNormalVolume() async {
    try {
      // Restore volume to normal levels
      await setMusicVolume(getMusicVolume() / 0.5);
      await setSoundVolume(getSoundVolume() / 0.5);

      debugPrint('[AudioService] Volume restored to normal');
    } catch (e) {
      debugPrint('[AudioService] Error restoring volume: $e');
    }
  }

  // ------------------------- EXISTING METHODS ----------------

  Future<void> resetAudioSettings() async {
    await _box.delete(_audioOnKey);
    await _box.delete(_musicOnKey);
    await _box.delete(_soundsOnKey);
    await _box.delete(_musicVolumeKey);
    await _box.delete(_soundVolumeKey);
    await _box.delete(_wasPlayingKey);
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
    'musicVolume': getMusicVolume(),
    'soundVolume': getSoundVolume(),
    'wasPlayingBeforePause': _box.get(_wasPlayingKey, defaultValue: false),
  };

  // Aliases for compatibility with SettingsController
  Future<void> saveAudioOn(bool value) async => await setAudioOn(value);
  Future<void> saveMusicOn(bool value) async => await setMusicOn(value);
  Future<void> saveSoundsOn(bool value) async => await setSoundsOn(value);
}
