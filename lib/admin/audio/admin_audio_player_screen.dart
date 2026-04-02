import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart' as soloud;
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';

class AdminAudioPlayerScreen extends StatefulWidget {
  const AdminAudioPlayerScreen({super.key});

  @override
  State<AdminAudioPlayerScreen> createState() => _AdminAudioPlayerScreenState();
}

class _AdminAudioPlayerScreenState extends State<AdminAudioPlayerScreen> {
  static const List<String> _musicTracks = [
    'assets/songs/around_the_world.mp3',
    'assets/songs/autumn_days_lofi.mp3',
    'assets/songs/breezing.mp3',
    'assets/songs/new_starts_beat.mp3',
    'assets/songs/patience.mp3',
  ];

  static const String _previewSfxAsset = 'assets/sounds/cha_ching.mp3';

  final just_audio.AudioPlayer _musicPlayer = just_audio.AudioPlayer();
  soloud.SoLoud? _soLoud;
  soloud.AudioSource? _previewSfx;

  bool _loading = true;
  bool _musicOn = true;
  bool _soundsOn = true;
  bool _isPlaying = false;
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  String _selectedTrack = _musicTracks.first;
  String? _status;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
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
      _previewSfx = await _soLoud!.loadAsset(_previewSfxAsset);

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
    if (!_musicOn) return;
    try {
      await _musicPlayer.setAsset(_selectedTrack);
      await _musicPlayer.play();
      setState(() => _status = 'Playing ${_selectedTrack.split('/').last}');
    } catch (e) {
      setState(() => _status = 'Track error: $e');
    }
  }

  Future<void> _pauseTrack() async {
    await _musicPlayer.pause();
    setState(() => _status = 'Music paused');
  }

  Future<void> _stopTrack() async {
    await _musicPlayer.stop();
    setState(() => _status = 'Music stopped');
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
          : Padding(
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
                            setState(() => _selectedTrack = value);
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
                              onPressed: _playTrack,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Play'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _pauseTrack,
                              icon: const Icon(Icons.pause_rounded),
                              label: const Text('Pause'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _stopTrack,
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
                          onPressed: _playPreviewSfx,
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
