import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:logging/logging.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../core/services/analytics/app_lifecycle.dart';
import '../../core/services/audio/audio_asset_service.dart';
import '../../game/controllers/settings_controller.dart';
import '../models/songs.dart';
import '../models/sounds.dart';

/// Controls audio playback using flutter_soloud with cross fading.
class AudioController {
  static final _log = Logger('AudioController');

  final SoLoud? soloud;
  final Map<SfxType, Handle> _sfxCache = {};
  Handle? _currentMusic;
  Handle? _nextMusic;

  // just_audio player for remote music URL streaming (Option A/B).
  ja.AudioPlayer? _musicPlayer;

  // Per-type just_audio players for remote SFX streaming.
  // Populated by _preloadRemoteSfx() when audioAssetService is set.
  final Map<SfxType, ja.AudioPlayer> _remoteSfxCache = {};

  // Optional backend service that returns presigned MinIO URLs for both
  // songs and SFX. When set, audio is fetched from MinIO with local
  // SoLoud assets as the fallback on any network error.
  AudioAssetService? audioAssetService;

  final Queue<Song> _playlist;
  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  AudioController(this.soloud, {this.audioAssetService})
      : _playlist = Queue.of(List<Song>.of(songs)..shuffle());

  Future<void> initialize() async {
    await soloud!.init();
    // Always preload local SFX so they're available as a fallback.
    await _preloadSfx();
    // Overlay with remote SFX when the backend service is available.
    if (audioAssetService != null) {
      await _preloadRemoteSfx();
    }
  }

  void attachDependencies(AppLifecycleStateNotifier lifecycleNotifier,
      SettingsController settingsController) {
    _attachLifecycleNotifier(lifecycleNotifier);
    _attachSettings(settingsController);
  }

  void dispose() {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    _stopAllSound();
    _musicPlayer?.dispose();
    _musicPlayer = null;
    for (final player in _remoteSfxCache.values) {
      player.dispose();
    }
    _remoteSfxCache.clear();
    soloud!.deinit();
  }

  /// Stream music from a remote URL (MinIO presigned URL or any HTTPS audio URL).
  /// Call this to verify just_audio URL playback locally before wiring up
  /// the full AudioAssetService backend integration.
  Future<void> playRemoteMusic(String presignedUrl) async {
    _log.info('Playing remote music: $presignedUrl');
    _musicPlayer ??= ja.AudioPlayer();
    await _musicPlayer!
        .setAudioSource(ja.AudioSource.uri(Uri.parse(presignedUrl)));
    await _musicPlayer!.play();
  }

  /// Stop remote music playback without disposing the player.
  Future<void> stopRemoteMusic() async {
    await _musicPlayer?.stop();
  }

  Future<void> _preloadSfx() async {
    _log.info('Preloading local sound effects');
    for (var type in SfxType.values) {
      var paths = soundTypeToFilename(type);
      if (paths.isNotEmpty) {
        var sound = await soloud!.loadFile('assets/sfx/${paths.first}');
        _sfxCache[type] = sound as Handle;
      }
    }
  }

  /// Preload remote SFX from MinIO via presigned URLs.
  /// Falls back gracefully — types that fail are played from the local SoLoud cache.
  Future<void> _preloadRemoteSfx() async {
    _log.info('Preloading remote sound effects');
    for (final type in SfxType.values) {
      final paths = soundTypeToFilename(type);
      if (paths.isEmpty) continue;
      try {
        final url = await audioAssetService!.getPresignedUrl(
          paths.first,
          category: 'sfx',
        );
        final player = ja.AudioPlayer();
        await player.setAudioSource(ja.AudioSource.uri(Uri.parse(url)));
        _remoteSfxCache[type] = player;
      } catch (e) {
        _log.warning(
            'Remote SFX preload failed for ${paths.first}, will use local: $e');
      }
    }
  }

  void playSfx(SfxType type) {
    if (!(_settings?.audioOn.value ?? false) ||
        !(_settings?.soundsOn.value ?? false)) {
      _log.fine(() => 'Ignoring sound: $type');
      return;
    }

    // Remote SFX takes priority; seek to start then play for instant retrigger.
    final remotePlayer = _remoteSfxCache[type];
    if (remotePlayer != null) {
      remotePlayer.seek(Duration.zero).then((_) => remotePlayer.play());
      return;
    }

    // Fall back to SoLoud local cache.
    final sound = _sfxCache[type];
    if (sound != null) {
      soloud!.play(sound as AudioSource);
    }
  }

  void _attachLifecycleNotifier(AppLifecycleStateNotifier lifecycleNotifier) {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;
  }

  void _attachSettings(SettingsController settingsController) {
    _settings = settingsController;
    _settings!.audioOn.addListener(_audioOnHandler);
    _settings!.musicOn.addListener(_musicOnHandler);
    _settings!.soundsOn.addListener(_soundsOnHandler);

    if (_settings!.audioOn.value && _settings!.musicOn.value) {
      _playCurrentSongInPlaylist();
    }
  }

  void _handleAppLifecycle() {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopAllSound();
        break;
      case AppLifecycleState.resumed:
        if (_settings!.audioOn.value && _settings!.musicOn.value) {
          _startOrResumeMusic();
        }
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _audioOnHandler() {
    if (_settings!.audioOn.value) {
      if (_settings!.musicOn.value) _startOrResumeMusic();
    } else {
      _stopAllSound();
    }
  }

  void _musicOnHandler() {
    if (_settings!.musicOn.value) {
      if (_settings!.audioOn.value) _startOrResumeMusic();
    } else {
      _stopAllSound();
    }
  }

  void _soundsOnHandler() {
    _stopAllSound();
  }

  Future<void> _playCurrentSongInPlaylist() async {
    final song = _playlist.first;
    _log.info('Playing ${song.filename} now.');

    if (audioAssetService != null) {
      try {
        final url = await audioAssetService!.getPresignedUrl(song.filename);
        _musicPlayer ??= ja.AudioPlayer();
        await _musicPlayer!.setAudioSource(ja.AudioSource.uri(Uri.parse(url)));
        await _musicPlayer!.play();
        // Advance playlist; SoLoud handles are not used for remote playback.
        _playlist.add(_playlist.removeFirst());
        return;
      } catch (e) {
        _log.warning(
            'Remote audio failed for ${song.filename}, falling back to local: $e');
      }
    }

    // Fallback: load from bundled assets via SoLoud.
    _nextMusic =
        (await soloud!.loadFile('assets/songs/${song.filename}')) as Handle?;
    _crossfadeToNextSong();
  }

  void _crossfadeToNextSong() {
    if (_currentMusic != null) {
      _fadeOut(_currentMusic!);
    }
    _fadeIn(_nextMusic!);
    _currentMusic = _nextMusic;
    _playlist.add(_playlist.removeFirst());
  }

  void _fadeOut(Handle sound) {
    for (double volume = 1.0; volume > 0; volume -= 0.1) {
      Future.delayed(Duration(milliseconds: 100),
          () => soloud!.setVolume(sound as SoundHandle, volume));
    }
    Future.delayed(
        Duration(seconds: 1), () => soloud!.stop(sound as SoundHandle));
  }

  void _fadeIn(Handle sound) {
    soloud!.play(sound as AudioSource);
    for (double volume = 0; volume < 1.0; volume += 0.1) {
      Future.delayed(Duration(milliseconds: 100),
          () => soloud?.setVolume(sound as SoundHandle, volume));
    }
  }

  void _startOrResumeMusic() {
    if (audioAssetService != null) {
      if (_musicPlayer == null || _musicPlayer!.playing == false) {
        _playCurrentSongInPlaylist();
      } else {
        _musicPlayer!.play();
      }
      return;
    }
    if (_currentMusic == null) {
      _playCurrentSongInPlaylist();
    } else {
      soloud!.setPause(_currentMusic! as SoundHandle, false);
    }
  }

  void _stopAllSound() {
    _musicPlayer?.stop();
    for (final player in _remoteSfxCache.values) {
      player.stop();
    }
    soloud!.stopAll();
  }
}

extension on SoLoud {
  void stopAll() {}
}
