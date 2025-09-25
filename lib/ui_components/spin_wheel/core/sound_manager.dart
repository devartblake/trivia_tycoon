import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:flutter_soloud/flutter_soloud.dart' as soloud;
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';

enum SoundEffect {
  spinStart,
  spinLoop,
  spinEnd,
  wheelTick,
  prizeWin,
  bigWin,
  buttonClick,
  buttonHover,
  notification,
  error,
  success,
}

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final Map<SoundEffect, String> _soundPaths = {
    SoundEffect.spinStart: 'assets/sounds/spin_start.wav',
    SoundEffect.spinLoop: 'assets/sounds/spin_loop.wav',
    SoundEffect.spinEnd: 'assets/sounds/spin_end.wav',
    SoundEffect.wheelTick: 'assets/sounds/wheel_tick.wav',
    SoundEffect.prizeWin: 'assets/sounds/prize_win.wav',
    SoundEffect.bigWin: 'assets/sounds/big_win.wav',
    SoundEffect.buttonClick: 'assets/sounds/button_click.wav',
    SoundEffect.buttonHover: 'assets/sounds/button_hover.wav',
    SoundEffect.notification: 'assets/sounds/notification.wav',
    SoundEffect.error: 'assets/sounds/error.wav',
    SoundEffect.success: 'assets/sounds/success.wav',
  };

  // SoLoud instances for sound effects
  soloud.SoLoud? _soLoud;
  final Map<SoundEffect, soloud.AudioSource> _audioSources = {};
  final Map<SoundEffect, soloud.SoundHandle> _activeSounds = {};

  // Just Audio for background music
  just_audio.AudioPlayer? _musicPlayer;

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 0.7;
  bool _initialized = false;

  /// Initialize the sound manager
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize SoLoud for sound effects
      _soLoud = soloud.SoLoud.instance;
      await _soLoud!.init();

      // Load settings
      await _loadSettings();

      // Preload sound effects
      await _preloadSoundEffects();

      // Initialize Just Audio for background music
      _musicPlayer = just_audio.AudioPlayer();
      await _musicPlayer!.setVolume(_musicVolume);
      await _musicPlayer!.setLoopMode(just_audio.LoopMode.all);

      _initialized = true;
      print('SoundManager initialized successfully');
    } catch (e) {
      print('SoundManager initialization failed: $e');
    }
  }

  /// Load audio settings from storage
  Future<void> _loadSettings() async {
    try {
      _soundEnabled = await AppSettings.getSoundsOn(defaultValue: true);
      _musicEnabled = await AppSettings.getMusicOn(defaultValue: true);

      // Set SoLoud global volume
      if (_soLoud != null) {
        _soLoud!.setGlobalVolume(_soundVolume);
      }
    } catch (e) {
      print('Failed to load sound settings: $e');
    }
  }

  /// Preload all sound effects into memory
  Future<void> _preloadSoundEffects() async {
    if (_soLoud == null) return;

    try {
      for (final entry in _soundPaths.entries) {
        final audioSource = await _soLoud!.loadAsset(entry.value);
        _audioSources[entry.key] = audioSource;
      }
    } catch (e) {
      print('Failed to preload sound effects: $e');
    }
  }

  /// Play a sound effect using SoLoud
  Future<void> playSound(SoundEffect effect, {double? volume}) async {
    if (!_initialized || !_soundEnabled || _soLoud == null) return;

    try {
      final audioSource = _audioSources[effect];
      if (audioSource != null) {
        // Stop any currently playing instance of this sound
        if (_activeSounds.containsKey(effect)) {
          _soLoud!.stop(_activeSounds[effect]!);
          _activeSounds.remove(effect);
        }

        // Play the sound
        final handle = await _soLoud!.play(
          audioSource,
          volume: volume ?? _soundVolume,
        );

        _activeSounds[effect] = handle;

        // Clean up handle when sound finishes
        _cleanupSoundHandle(effect, handle);
      }
    } catch (e) {
      print('Failed to play sound $effect: $e');
    }
  }

  /// Clean up sound handle after a delay
  void _cleanupSoundHandle(SoundEffect effect, soloud.SoundHandle handle) {
    Future.delayed(const Duration(seconds: 5), () {
      if (_activeSounds[effect] == handle) {
        _activeSounds.remove(effect);
      }
    });
  }

  /// Play background music using Just Audio
  Future<void> playBackgroundMusic(String musicPath) async {
    if (!_initialized || !_musicEnabled || _musicPlayer == null) return;

    try {
      await _musicPlayer!.stop();
      await _musicPlayer!.setAsset(musicPath);
      await _musicPlayer!.play();
    } catch (e) {
      print('Failed to play background music: $e');
    }
  }

  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    if (_musicPlayer != null) {
      await _musicPlayer!.stop();
    }
  }

  /// Pause background music
  Future<void> pauseBackgroundMusic() async {
    if (_musicPlayer != null) {
      await _musicPlayer!.pause();
    }
  }

  /// Resume background music
  Future<void> resumeBackgroundMusic() async {
    if (_musicPlayer != null && _musicEnabled) {
      await _musicPlayer!.play();
    }
  }

  /// Play wheel spinning sequence with layered sounds
  Future<void> playSpinSequence(Duration duration) async {
    if (!_soundEnabled || _soLoud == null) return;

    try {
      // Play spin start sound
      await playSound(SoundEffect.spinStart);

      // Wait a bit then start loop
      await Future.delayed(const Duration(milliseconds: 300));

      // Play spinning loop for most of the duration
      final loopDuration = duration - const Duration(milliseconds: 800);
      if (loopDuration.inMilliseconds > 0) {
        final loopSource = _audioSources[SoundEffect.spinLoop];
        if (loopSource != null) {
          final loopHandle = await _soLoud!.play(
            loopSource,
            volume: _soundVolume * 0.8,
            looping: true,
          );

          // Stop loop before spin ends
          Future.delayed(loopDuration, () {
            if (_soLoud != null) {
              _soLoud!.stop(loopHandle);
            }
          });
        }
      }

      // Play end sound
      Future.delayed(duration - const Duration(milliseconds: 500), () {
        playSound(SoundEffect.spinEnd);
      });
    } catch (e) {
      print('Failed to play spin sequence: $e');
    }
  }

  /// Play prize win sound based on prize value with sound layering
  Future<void> playPrizeSound(String prizeName) async {
    if (!_soundEnabled) return;

    // Determine which sound to play based on prize
    SoundEffect effect = SoundEffect.prizeWin;

    if (prizeName.toLowerCase().contains('diamond') ||
        prizeName.toLowerCase().contains('jackpot') ||
        prizeName.toLowerCase().contains('grand')) {
      effect = SoundEffect.bigWin;

      // Add extra celebration for big wins
      Future.delayed(const Duration(milliseconds: 200), () {
        playSound(SoundEffect.success, volume: 0.6);
      });
    }

    await playSound(effect);

    // Add haptic feedback
    HapticFeedback.mediumImpact();
  }

  /// Play button interaction sounds with SoLoud for low latency
  Future<void> playButtonClick() async {
    await playSound(SoundEffect.buttonClick, volume: 0.8);
    HapticFeedback.lightImpact();
  }

  Future<void> playButtonHover() async {
    await playSound(SoundEffect.buttonHover, volume: 0.5);
  }

  /// Play UI feedback sounds
  Future<void> playSuccess() async {
    await playSound(SoundEffect.success);
    HapticFeedback.lightImpact();
  }

  Future<void> playError() async {
    await playSound(SoundEffect.error);
    HapticFeedback.mediumImpact();
  }

  Future<void> playNotification() async {
    await playSound(SoundEffect.notification);
  }

  /// Update sound settings
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await AppSettings.saveSoundsOn(enabled);

    if (!enabled && _soLoud != null) {
      // Stop all currently playing sounds
      for (final handle in _activeSounds.values) {
        _soLoud!.stop(handle);
      }
      _activeSounds.clear();
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await AppSettings.saveMusicOn(enabled);

    if (!enabled) {
      await stopBackgroundMusic();
    }
  }

  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);

    // Update SoLoud global volume
    if (_soLoud != null) {
      _soLoud!.setGlobalVolume(_soundVolume);
    }
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);

    if (_musicPlayer != null) {
      await _musicPlayer!.setVolume(_musicVolume);
    }
  }

  /// Check if background music is playing
  bool get isMusicPlaying => _musicPlayer?.playing ?? false;

  /// Get current music position
  Duration get musicPosition => _musicPlayer?.position ?? Duration.zero;

  /// Get music duration
  Duration? get musicDuration => _musicPlayer?.duration;

  /// Seek to position in music
  Future<void> seekMusic(Duration position) async {
    if (_musicPlayer != null) {
      await _musicPlayer!.seek(position);
    }
  }

  /// Getters for current settings
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;
  bool get isInitialized => _initialized;

  /// Dispose all resources
  Future<void> dispose() async {
    try {
      // Stop and dispose all SoLoud sounds
      if (_soLoud != null) {
        for (final handle in _activeSounds.values) {
          _soLoud!.stop(handle);
        }
        _activeSounds.clear();

        // Dispose audio sources
        for (final source in _audioSources.values) {
          _soLoud!.disposeSource(source);
        }
        _audioSources.clear();

        // Deinitialize SoLoud
        _soLoud!.deinit();
        _soLoud = null;
      }

      // Stop and dispose music player
      if (_musicPlayer != null) {
        await _musicPlayer!.stop();
        await _musicPlayer!.dispose();
        _musicPlayer = null;
      }

      _initialized = false;
      print('SoundManager disposed successfully');
    } catch (e) {
      print('Error disposing SoundManager: $e');
    }
  }
}

/// Extension for easy access to sound manager
extension SoundManagerExtension on SoundManager {
  /// Quick method to play common UI sounds with haptics
  Future<void> playUISound(String action) async {
    switch (action.toLowerCase()) {
      case 'click':
      case 'tap':
        await playButtonClick();
        break;
      case 'hover':
        await playButtonHover();
        break;
      case 'success':
        await playSuccess();
        break;
      case 'error':
        await playError();
        break;
      case 'notification':
        await playNotification();
        break;
      default:
        await playSound(SoundEffect.buttonClick);
    }
  }

  /// Play contextual wheel sounds
  Future<void> playWheelTick() async {
    await playSound(SoundEffect.wheelTick, volume: 0.6);
  }

  /// Play layered celebration sounds
  Future<void> playCelebration({bool isBigWin = false}) async {
    if (isBigWin) {
      await playSound(SoundEffect.bigWin);
      Future.delayed(const Duration(milliseconds: 300), () {
        playSound(SoundEffect.success, volume: 0.7);
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        playSound(SoundEffect.prizeWin, volume: 0.5);
      });
    } else {
      await playSound(SoundEffect.prizeWin);
      Future.delayed(const Duration(milliseconds: 200), () {
        playSound(SoundEffect.success, volume: 0.6);
      });
    }

    HapticFeedback.heavyImpact();
  }

  /// Fade out background music
  Future<void> fadeOutMusic({Duration duration = const Duration(seconds: 2)}) async {
    if (!isMusicPlaying) return;

    const steps = 20;
    final stepDuration = duration.inMilliseconds ~/ steps;
    final volumeStep = musicVolume / steps;

    for (int i = steps; i > 0; i--) {
      await setMusicVolume(volumeStep * i);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }

    await stopBackgroundMusic();
    await setMusicVolume(musicVolume); // Restore original volume
  }

  /// Fade in background music
  Future<void> fadeInMusic(String musicPath, {Duration duration = const Duration(seconds: 2)}) async {
    final originalVolume = musicVolume;
    await setMusicVolume(0.0);
    await playBackgroundMusic(musicPath);

    const steps = 20;
    final stepDuration = duration.inMilliseconds ~/ steps;
    final volumeStep = originalVolume / steps;

    for (int i = 1; i <= steps; i++) {
      await setMusicVolume(volumeStep * i);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }
  }
}

/// Global sound manager instance
final soundManager = SoundManager();
