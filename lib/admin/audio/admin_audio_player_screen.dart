import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart' as soloud;
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';

class AdminAudioPlayerScreen extends StatefulWidget {
  const AdminAudioPlayerScreen({super.key});

  @override
  State<AdminAudioPlayerScreen> createState() => _AdminAudioPlayerScreenState();
}

class _AdminAudioPlayerScreenState extends State<AdminAudioPlayerScreen> {
  static const String _defaultSfxAsset = 'assets/sounds/cha_ching.mp3';

  final just_audio.AudioPlayer _musicPlayer = just_audio.AudioPlayer();
  soloud.SoLoud? _soLoud;
  soloud.AudioSource? _previewSfx;

  List<String> _musicTracks = const ['assets/songs/around_the_world.mp3'];
  List<String> _sfxAssets = const [_defaultSfxAsset];
  bool _loading = true;
  bool _musicOn = true;
  bool _soundsOn = true;
  bool _isPlaying = false;
  bool _trackLoaded = false;
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  String _selectedTrack = 'assets/songs/around_the_world.mp3';
  String? _loadedTrack;
  String _selectedSfx = _defaultSfxAsset;
  String? _status;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _loadCatalogsFromIndex();
      final musicOn = await AppSettings.getMusicOn(defaultValue: true);
      final soundsOn = await AppSettings.getSoundsOn(defaultValue: true);

      _musicOn = musicOn;
      _soundsOn = soundsOn;
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.setLoopMode(just_audio.LoopMode.one);

      _musicPlayer.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() => _isPlaying = state.playing);
      });

      _soLoud = soloud.SoLoud.instance;
      await _soLoud!.init();
      _soLoud!.setGlobalVolume(_sfxVolume);
      _previewSfx = await _soLoud!.loadAsset(_selectedSfx);

      setState(() {
        _status = 'Audio engine ready';
      });
    } catch (e) {
      setState(() {
        _status = 'Audio init warning: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadCatalogsFromIndex() async {
    final songsJson = await rootBundle.loadString('assets/songs/index.json');
    final soundsJson = await rootBundle.loadString('assets/sounds/index.json');

    final songMap = jsonDecode(songsJson) as Map<String, dynamic>;
    final sfxMap = jsonDecode(soundsJson) as Map<String, dynamic>;

    final songFiles = (songMap['files'] as List<dynamic>? ?? const [])
        .map((e) => (e as Map<String, dynamic>)['path']?.toString() ?? '')
        .where((p) => p.isNotEmpty)
        .map((p) => 'assets/songs/$p')
        .toList();

    final sfxFiles = (sfxMap['files'] as List<dynamic>? ?? const [])
        .map((e) => (e as Map<String, dynamic>)['path']?.toString() ?? '')
        .where((p) => p.isNotEmpty)
        .map((p) => 'assets/sounds/$p')
        .toList();

    if (songFiles.isNotEmpty) {
      _musicTracks = songFiles;
      _selectedTrack = songFiles.first;
    }

    if (sfxFiles.isNotEmpty) {
      _sfxAssets = sfxFiles;
      _selectedSfx = sfxFiles.first;
    }
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    try {
      _soLoud?.deinit();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _toggleMusic(bool value) async {
    setState(() => _musicOn = value);
    await AppSettings.saveMusicOn(value);
    if (!value) {
      await _musicPlayer.pause();
    }
  }

  Future<void> _toggleSfx(bool value) async {
    setState(() => _soundsOn = value);
    await AppSettings.saveSoundsOn(value);
  }

  Future<void> _playTrack() async {
    if (!_musicOn) {
      setState(() => _status = 'Enable Music to play tracks');
      return;
    }
    try {
      if (!_trackLoaded || _loadedTrack != _selectedTrack) {
        await _musicPlayer.setAsset(_selectedTrack);
        _trackLoaded = true;
        _loadedTrack = _selectedTrack;
      }
      await _musicPlayer.play();
      setState(() => _status = 'Playing ${_selectedTrack.split('/').last}');
    } catch (e) {
      setState(() => _status = 'Track error: $e');
    }
  }

  Future<void> _pauseTrack() async {
    await _musicPlayer.pause();
    setState(() {
      _isPlaying = false;
      _status = 'Music paused';
    });
  }

  Future<void> _stopTrack() async {
    await _musicPlayer.stop();
    setState(() {
      _isPlaying = false;
      _status = 'Music stopped';
    });
  }

  Future<void> _playPreviewSfx() async {
    if (!_soundsOn || _soLoud == null || _previewSfx == null) return;
    try {
      await _soLoud!.play(_previewSfx!, volume: _sfxVolume);
      setState(() => _status = 'SFX preview played');
    } catch (e) {
      setState(() => _status = 'SFX error: $e');
    }
  }

  Future<void> _selectSfx(String asset) async {
    if (_soLoud == null) return;
    try {
      final source = await _soLoud!.loadAsset(asset);
      setState(() {
        _selectedSfx = asset;
        _previewSfx = source;
      });
    } catch (e) {
      setState(() => _status = 'SFX load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1325),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B33),
        title: const Text('Admin Audio Studio'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audio Controls',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          value: _musicOn,
                          onChanged: _toggleMusic,
                          title: const Text('Music Enabled',
                              style: TextStyle(color: Colors.white)),
                        ),
                        SwitchListTile.adaptive(
                          value: _soundsOn,
                          onChanged: _toggleSfx,
                          title: const Text('SFX Enabled',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Music Player',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedTrack,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0x22000000),
                            labelText: 'Track',
                          ),
                          dropdownColor: const Color(0xFF1A2341),
                          items: _musicTracks
                              .map((track) => DropdownMenuItem(
                                    value: track,
                                    child: Text(
                                      track.split('/').last,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedTrack = value;
                              _trackLoaded = false;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Text('Music Volume ${(100 * _musicVolume).round()}%',
                            style: const TextStyle(color: Colors.white70)),
                        Slider(
                          value: _musicVolume,
                          min: 0,
                          max: 1,
                          onChanged: (v) async {
                            setState(() => _musicVolume = v);
                            await _musicPlayer.setVolume(v);
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed:
                                  _musicOn ? (_isPlaying ? _pauseTrack : _playTrack) : null,
                              icon: Icon(_isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded),
                              label: Text(_isPlaying ? 'Pause' : 'Play'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: (_isPlaying || _trackLoaded) ? _stopTrack : null,
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Stop'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SFX Preview (flutter_soloud)',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedSfx,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0x22000000),
                            labelText: 'SFX Asset',
                          ),
                          dropdownColor: const Color(0xFF1A2341),
                          items: _sfxAssets
                              .map((asset) => DropdownMenuItem(
                                    value: asset,
                                    child: Text(
                                      asset.split('/').last,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            _selectSfx(value);
                          },
                        ),
                        const SizedBox(height: 12),
                        Text('SFX Volume ${(100 * _sfxVolume).round()}%',
                            style: const TextStyle(color: Colors.white70)),
                        Slider(
                          value: _sfxVolume,
                          min: 0,
                          max: 1,
                          onChanged: (v) {
                            setState(() => _sfxVolume = v);
                            _soLoud?.setGlobalVolume(v);
                          },
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed:
                              (_soundsOn && _soLoud != null && _previewSfx != null)
                                  ? _playPreviewSfx
                                  : null,
                          icon: const Icon(Icons.music_note_rounded),
                          label: const Text('Play Preview SFX'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_status != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _status!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x221D2A50),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
