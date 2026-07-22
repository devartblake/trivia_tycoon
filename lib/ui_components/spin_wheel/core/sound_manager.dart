import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:flutter_soloud/flutter_soloud.dart' as soloud;
import 'package:synaptix/core/services/settings/app_settings.dart';
import 'package:synaptix/core/manager/log_manager.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';

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
    SoundEffect.spinStart: 'assets/audio/ui/spin_start.wav',
    SoundEffect.spinLoop: 'assets/audio/ui/spin_loop.wav',
    SoundEffect.spinEnd: 'assets/audio/ui/spin_end.wav',
    SoundEffect.wheelTick: 'assets/audio/ui/wheel_tick.wav',
    SoundEffect.prizeWin: 'assets/audio/ui/prize_win.wav',
    SoundEffect.bigWin: 'assets/audio/ui/big_win.wav',
    SoundEffect.buttonClick: 'assets/audio/ui/button_click.wav',
    SoundEffect.buttonHover: 'assets/audio/ui/button_hover.wav',
    SoundEffect.notification: 'assets/audio/ui/notification.wav',
    SoundEffect.error: 'assets/audio/ui/error.wav',
    SoundEffect.success: 'assets/audio/ui/success.wav',
  };

  soloud.SoLoud? _soLoud;
  final Map<SoundEffect, soloud.AudioSource> _audioSources = {};
  final Map<SoundEffect, soloud.SoundHandle> _activeSounds = {};

  just_audio.AudioPlayer? _musicPlayer;

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 0.7;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _soLoud = soloud.SoLoud.instance;
      await _soLoud!.init();
      await _loadSettings();
      await _preloadSoundEffects();
      _musicPlayer = just_audio.AudioPlayer();
      await _musicPlayer!.setVolume(_musicVolume);
      await _musicPlayer!.setLoopMode(just_audio.LoopMode.all);
      _initialized = true;
      LogManager.debug('SoundManager initialized');
    } catch (e) {
      LogManager.debug('SoundManager init failed: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      _soundEnabled = await AppSettings.getSoundsOn(defaultValue: true);
      _musicEnabled = await AppSettings.getMusicOn(defaultValue: true);
      if (_soLoud != null) _soLoud!.setGlobalVolume(_soundVolume);
    } catch (_) {}
  }

  Future<void> _preloadSoundEffects() async {
    if (_soLoud == null) return;
    try {
      for (final entry in _soundPaths.entries) {
        final audioSource = await _soLoud!.loadAsset(entry.value);
        _audioSources[entry.key] = audioSource;
      }
    } catch (_) {}
  }

  Future<void> playSound(
    SoundEffect effect, {
    double? volume,
    double? pitch,
    BuildContext? context,
    double? overrideVolumeMultiplier,
    SynaptixSoundStyle? overrideSoundStyle,
  }) async {
    if (!_initialized || !_soundEnabled || _soLoud == null) return;

    double volumeMultiplier = overrideVolumeMultiplier ?? 1.0;
    SynaptixSoundStyle soundStyle =
        overrideSoundStyle ?? SynaptixSoundStyle.digital;

    if (overrideVolumeMultiplier == null &&
        context != null &&
        context.mounted) {
      final themeExtension = Theme.of(context).extension<SynaptixTheme>();
      volumeMultiplier = themeExtension?.soundVolumeMultiplier ?? 1.0;
      soundStyle =
          themeExtension?.preferredSoundStyle ?? SynaptixSoundStyle.digital;
    }

    double effectivePitch = pitch ?? 1.0;
    if (pitch == null) {
      if (soundStyle == SynaptixSoundStyle.bouncy) effectivePitch = 1.15;
      if (soundStyle == SynaptixSoundStyle.minimalist) effectivePitch = 0.85;
    }

    try {
      final audioSource = _audioSources[effect];
      if (audioSource != null) {
        if (_activeSounds.containsKey(effect)) {
          _soLoud!.stop(_activeSounds[effect]!);
          _activeSounds.remove(effect);
        }
        final handle = await _soLoud!.play(
          audioSource,
          volume: (volume ?? _soundVolume) * volumeMultiplier,
        );
        if (effectivePitch != 1.0)
          _soLoud!.setRelativePlaySpeed(handle, effectivePitch);
        _activeSounds[effect] = handle;
        _cleanupSoundHandle(effect, handle);
      }
    } catch (_) {}
  }

  void _cleanupSoundHandle(SoundEffect effect, soloud.SoundHandle handle) {
    Future.delayed(const Duration(seconds: 5), () {
      if (_activeSounds[effect] == handle) _activeSounds.remove(effect);
    });
  }

  Future<void> playBackgroundMusic(String musicPath) async {
    if (!_initialized || !_musicEnabled || _musicPlayer == null) return;
    try {
      await _musicPlayer!.stop();
      await _musicPlayer!.setAsset(musicPath);
      await _musicPlayer!.play();
    } catch (_) {}
  }

  Future<void> stopBackgroundMusic() async {
    if (_musicPlayer != null) await _musicPlayer!.stop();
  }

  Future<void> pauseBackgroundMusic() async {
    if (_musicPlayer != null) await _musicPlayer!.pause();
  }

  Future<void> resumeBackgroundMusic() async {
    if (_musicPlayer != null && _musicEnabled) await _musicPlayer!.play();
  }

  Future<void> playSpinSequence(Duration duration) async {
    if (!_soundEnabled || _soLoud == null) return;
    try {
      await playSound(SoundEffect.spinStart);
      await Future.delayed(const Duration(milliseconds: 300));
      final loopDuration = duration - const Duration(milliseconds: 800);
      if (loopDuration.inMilliseconds > 0) {
        final loopSource = _audioSources[SoundEffect.spinLoop];
        if (loopSource != null) {
          final loopHandle = await _soLoud!
              .play(loopSource, volume: _soundVolume * 0.8, looping: true);
          Future.delayed(loopDuration, () {
            if (_soLoud != null) _soLoud!.stop(loopHandle);
          });
        }
      }
      Future.delayed(duration - const Duration(milliseconds: 500), () {
        playSound(SoundEffect.spinEnd);
      });
    } catch (_) {}
  }

  Future<void> playPrizeSound(String prizeName) async {
    if (!_soundEnabled) return;
    SoundEffect effect = SoundEffect.prizeWin;
    if (prizeName.toLowerCase().contains('diamond') ||
        prizeName.toLowerCase().contains('jackpot') ||
        prizeName.toLowerCase().contains('grand')) {
      effect = SoundEffect.bigWin;
      Future.delayed(const Duration(milliseconds: 200), () {
        playSound(SoundEffect.success, volume: 0.6);
      });
    }
    await playSound(effect);
    HapticFeedback.mediumImpact();
  }

  Future<void> playButtonClick() async {
    await playSound(SoundEffect.buttonClick, volume: 0.8);
    HapticFeedback.lightImpact();
  }

  Future<void> playButtonHover() async {
    await playSound(SoundEffect.buttonHover, volume: 0.5);
  }

  Future<void> playSuccess([BuildContext? context]) async {
    await playSound(SoundEffect.success, context: context);
    HapticFeedback.lightImpact();
  }

  Future<void> playError([BuildContext? context]) async {
    await playSound(SoundEffect.error, context: context);
    HapticFeedback.mediumImpact();
  }

  Future<void> playNotification([BuildContext? context]) async {
    await playSound(SoundEffect.notification, context: context);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await AppSettings.saveSoundsOn(enabled);
    if (!enabled && _soLoud != null) {
      for (final handle in _activeSounds.values) _soLoud!.stop(handle);
      _activeSounds.clear();
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await AppSettings.saveMusicOn(enabled);
    if (!enabled) await stopBackgroundMusic();
  }

  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    if (_soLoud != null) _soLoud!.setGlobalVolume(_soundVolume);
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    if (_musicPlayer != null) await _musicPlayer!.setVolume(_musicVolume);
  }

  bool get isMusicPlaying => _musicPlayer?.playing ?? false;
  Duration get musicPosition => _musicPlayer?.position ?? Duration.zero;
  Duration? get musicDuration => _musicPlayer?.duration;
  Future<void> seekMusic(Duration position) async {
    if (_musicPlayer != null) await _musicPlayer!.seek(position);
  }

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;
  bool get isInitialized => _initialized;

  Future<void> dispose() async {
    try {
      if (_soLoud != null) {
        for (final handle in _activeSounds.values) _soLoud!.stop(handle);
        _activeSounds.clear();
        for (final source in _audioSources.values)
          _soLoud!.disposeSource(source);
        _audioSources.clear();
        _soLoud!.deinit();
        _soLoud = null;
      }
      if (_musicPlayer != null) {
        await _musicPlayer!.stop();
        await _musicPlayer!.dispose();
        _musicPlayer = null;
      }
      _initialized = false;
    } catch (_) {}
  }
}

extension SoundManagerExtension on SoundManager {
  Future<void> playUISound(String action, [BuildContext? context]) async {
    switch (action.toLowerCase()) {
      case 'click':
      case 'tap':
        await playButtonClick();
        break;
      case 'hover':
        await playButtonHover();
        break;
      case 'success':
        await playSuccess(context);
        break;
      case 'error':
        await playError(context);
        break;
      case 'notification':
        await playNotification(context);
        break;
      case 'unlock':
        await playSound(SoundEffect.success, volume: 1.0, context: context);
        HapticFeedback.heavyImpact();
        break;
      case 'reward':
        await playSound(SoundEffect.prizeWin, volume: 0.8, context: context);
        break;
      case 'tab':
        await playSound(SoundEffect.buttonClick, volume: 0.5, context: context);
        break;
      case 'invite':
      case 'request':
        await playSound(SoundEffect.notification,
            volume: 0.9, context: context);
        break;
      default:
        await playSound(SoundEffect.buttonClick, context: context);
    }
  }

  Future<void> playWheelTick() async {
    await playSound(SoundEffect.wheelTick, volume: 0.6);
  }

  Future<void> playCelebration(
      {bool isBigWin = false, BuildContext? context}) async {
    double volMult = 1.0;
    SynaptixSoundStyle style = SynaptixSoundStyle.digital;

    if (context != null && context.mounted) {
      final themeExtension = Theme.of(context).extension<SynaptixTheme>();
      volMult = themeExtension?.soundVolumeMultiplier ?? 1.0;
      style = themeExtension?.preferredSoundStyle ?? SynaptixSoundStyle.digital;
    }

    if (isBigWin) {
      await playSound(SoundEffect.bigWin,
          overrideVolumeMultiplier: volMult, overrideSoundStyle: style);
      await Future.delayed(const Duration(milliseconds: 300));
      await playSound(SoundEffect.success,
          volume: 0.7,
          overrideVolumeMultiplier: volMult,
          overrideSoundStyle: style);
      await Future.delayed(const Duration(milliseconds: 300));
      await playSound(SoundEffect.prizeWin,
          volume: 0.5,
          overrideVolumeMultiplier: volMult,
          overrideSoundStyle: style);
    } else {
      await playSound(SoundEffect.prizeWin,
          overrideVolumeMultiplier: volMult, overrideSoundStyle: style);
      await Future.delayed(const Duration(milliseconds: 200));
      await playSound(SoundEffect.success,
          volume: 0.6,
          overrideVolumeMultiplier: volMult,
          overrideSoundStyle: style);
    }
    HapticFeedback.heavyImpact();
  }

  Future<void> fadeOutMusic(
      {Duration duration = const Duration(seconds: 2)}) async {
    if (!isMusicPlaying) return;
    const steps = 20;
    final stepDuration = duration.inMilliseconds ~/ steps;
    final volumeStep = musicVolume / steps;
    for (int i = steps; i > 0; i--) {
      await setMusicVolume(volumeStep * i);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }
    await stopBackgroundMusic();
    await setMusicVolume(musicVolume);
  }

  Future<void> fadeInMusic(String musicPath,
      {Duration duration = const Duration(seconds: 2)}) async {
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

final soundManager = SoundManager();
