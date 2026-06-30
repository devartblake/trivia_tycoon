import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../game/models/question_model.dart';
import 'answer_option_card.dart';
import 'question_power_ups.dart';

/// Audio-based question renderer
class AudioQuestionView extends StatefulWidget {
  final QuestionModel question;
  final void Function(String)? onAnswerSelected;
  final bool showFeedback;
  final String? selectedAnswer;
  final bool isMultiplayer;

  const AudioQuestionView({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  @override
  State<AudioQuestionView> createState() => _AudioQuestionViewState();
}

class _AudioQuestionViewState extends State<AudioQuestionView> {
  late AudioPlayer _audioPlayer;
  PlayerState? _playerState;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    if (widget.question.audioUrl?.isNotEmpty == true) {
      setState(() {
        _isLoading = true;
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _playerState = state;
          });
        }
      });

      _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      try {
        await _audioPlayer.setUrl(widget.question.audioUrl!);
      } catch (e) {
        debugPrint('Error loading audio: $e');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_playerState?.playing == true) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> _seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final displayOptions =
        widget.question.reducedOptions ?? widget.question.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isMultiplayer) const MultiplayerBadge(),
        Text(
          widget.question.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.blue.shade100,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.audiotrack,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audio Question',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          'Listen to the audio and answer the question',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _playerState?.playing == true
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                        color: Colors.blue.shade600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 16),
                      activeTrackColor: Colors.blue.shade600,
                      inactiveTrackColor: Colors.blue.shade200,
                      thumbColor: Colors.blue.shade600,
                    ),
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds / _duration.inMilliseconds
                          : 0.0,
                      onChanged: (value) {
                        final newPosition = Duration(
                          milliseconds:
                              (value * _duration.inMilliseconds).round(),
                        );
                        _seekTo(newPosition);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (widget.question.isBoostedTime ||
            widget.question.isShielded ||
            widget.question.multiplier != null)
          PowerUpIndicators(
            isBoostedTime: widget.question.isBoostedTime,
            isShielded: widget.question.isShielded,
            multiplier: widget.question.multiplier,
          ),
        if (widget.question.showHint &&
            widget.question.powerUpHint?.isNotEmpty == true)
          HintPanel(hint: widget.question.powerUpHint!),
        ...displayOptions.map(
          (option) => AnswerOptionCard(
            text: option,
            onPressed: widget.showFeedback || widget.onAnswerSelected == null
                ? null
                : () => widget.onAnswerSelected!(option),
            isSelected: option == widget.selectedAnswer,
            isCorrect: widget.question.isCorrectAnswer(option),
            showFeedback: widget.showFeedback,
            isMultiplayer: widget.isMultiplayer,
          ),
        ),
      ],
    );
  }
}
