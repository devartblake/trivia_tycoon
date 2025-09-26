import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../game/models/question_model.dart';

// Question type enum based on your model's type field
enum QuestionDisplayType {
  multipleChoice,
  image,
  video,
  audio,
}

extension QuestionDisplayTypeExtension on QuestionDisplayType {
  String get displayName {
    switch (this) {
      case QuestionDisplayType.multipleChoice:
        return 'Multiple Choice';
      case QuestionDisplayType.image:
        return 'Image Question';
      case QuestionDisplayType.video:
        return 'Video Question';
      case QuestionDisplayType.audio:
        return 'Audio Question';
    }
  }
}

// Base question widget interface
abstract class AdaptedQuestionWidget extends StatelessWidget {
  final QuestionModel question;
  final void Function(String)? onAnswerSelected;
  final bool showFeedback;
  final String? selectedAnswer;
  final bool isMultiplayer;

  const AdaptedQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  // Factory constructor to create appropriate widget based on question content
  factory AdaptedQuestionWidget.create({
    required QuestionModel question,
    required void Function(String)? onAnswerSelected,
    bool showFeedback = false,
    String? selectedAnswer,
    bool isMultiplayer = false,
  }) {
    QuestionDisplayType displayType = QuestionDisplayType.multipleChoice;

    // Determine display type based on available media
    if (question.imageUrl?.isNotEmpty == true) {
      displayType = QuestionDisplayType.image;
    } else if (question.videoUrl?.isNotEmpty == true) {
      displayType = QuestionDisplayType.video;
    } else if (question.type.toLowerCase().contains('audio')) {
      displayType = QuestionDisplayType.audio;
    }

    switch (displayType) {
      case QuestionDisplayType.multipleChoice:
        return AdaptedMultipleChoiceWidget(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );
      case QuestionDisplayType.image:
        return AdaptedImageQuestionWidget(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );
      case QuestionDisplayType.video:
        return AdaptedVideoQuestionWidget(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );
      case QuestionDisplayType.audio:
        return AdaptedAudioQuestionWidget(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );
    }
  }
}

// Multiple Choice Question Widget
class AdaptedMultipleChoiceWidget extends AdaptedQuestionWidget {
  const AdaptedMultipleChoiceWidget({
    super.key,
    required super.question,
    required super.onAnswerSelected,
    super.showFeedback,
    super.selectedAnswer,
    super.isMultiplayer,
  });

  @override
  Widget build(BuildContext context) {
    // Use reduced options if available (for eliminate power-up), otherwise use regular options
    final displayOptions = question.reducedOptions ?? question.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Multiplayer indicator (if applicable)
        if (isMultiplayer) _buildMultiplayerIndicator(),

        // Question text
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        // Power-up indicators
        if (question.isBoostedTime || question.isShielded || question.multiplier != null)
          _buildPowerUpIndicators(),

        // Hint display (if power-up is active)
        if (question.showHint && question.powerUpHint?.isNotEmpty == true)
          _buildHint(),

        // Answer options
        ...displayOptions.map((option) => _buildAnswerButton(option)),
      ],
    );
  }

  Widget _buildMultiplayerIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          const Text(
            'LIVE MULTIPLAYER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpIndicators() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (question.isBoostedTime) ...[
            Icon(Icons.speed, color: Colors.blue.shade600, size: 16),
            const SizedBox(width: 4),
            Text('Time Boost', style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
            const SizedBox(width: 8),
          ],
          if (question.isShielded) ...[
            Icon(Icons.shield, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 4),
            Text('Protected', style: TextStyle(color: Colors.green.shade600, fontSize: 12)),
            const SizedBox(width: 8),
          ],
          if (question.multiplier != null) ...[
            Icon(Icons.close, color: Colors.purple.shade600, size: 16),
            Text('${question.multiplier}x XP', style: TextStyle(color: Colors.purple.shade600, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.orange.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              question.powerUpHint!,
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String option) {
    final isSelected = option == selectedAnswer;
    final isCorrect = question.isCorrectAnswer(option);

    Color? backgroundColor;
    Color? textColor;
    Color? borderColor;

    if (showFeedback && isSelected) {
      backgroundColor = isCorrect ? Colors.green : Colors.red;
      textColor = Colors.white;
    } else if (showFeedback && isCorrect) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    } else if (isSelected && isMultiplayer) {
      backgroundColor = const Color(0xFF6366F1).withOpacity(0.1);
      borderColor = const Color(0xFF6366F1);
      textColor = const Color(0xFF6366F1);
    } else if (isSelected) {
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue;
      textColor = Colors.blue.shade800;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: showFeedback || onAnswerSelected == null
              ? null
              : () => onAnswerSelected!(option),
          child: Text(
            option,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// Image Question Widget
class AdaptedImageQuestionWidget extends AdaptedQuestionWidget {
  const AdaptedImageQuestionWidget({
    super.key,
    required super.question,
    required super.onAnswerSelected,
    super.showFeedback,
    super.selectedAnswer,
    super.isMultiplayer,
  });

  @override
  Widget build(BuildContext context) {
    final displayOptions = question.reducedOptions ?? question.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Image display
        if (question.imageUrl?.isNotEmpty == true)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: question.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.error, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Power-up indicators
        if (question.isBoostedTime || question.isShielded || question.multiplier != null)
          _buildPowerUpIndicators(),

        // Hint display
        if (question.showHint && question.powerUpHint?.isNotEmpty == true)
          _buildHint(),

        // Answer options
        ...displayOptions.map((option) => _buildAnswerButton(option)),
      ],
    );
  }

  Widget _buildPowerUpIndicators() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (question.isBoostedTime) ...[
            Icon(Icons.speed, color: Colors.blue.shade600, size: 16),
            const SizedBox(width: 4),
            Text('Time Boost', style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
            const SizedBox(width: 8),
          ],
          if (question.isShielded) ...[
            Icon(Icons.shield, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 4),
            Text('Protected', style: TextStyle(color: Colors.green.shade600, fontSize: 12)),
            const SizedBox(width: 8),
          ],
          if (question.multiplier != null) ...[
            Icon(Icons.close, color: Colors.purple.shade600, size: 16),
            Text('${question.multiplier}x XP', style: TextStyle(color: Colors.purple.shade600, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.orange.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              question.powerUpHint!,
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String option) {
    final isSelected = option == selectedAnswer;
    final isCorrect = question.isCorrectAnswer(option);

    Color? backgroundColor;
    Color? textColor;

    if (showFeedback && isSelected) {
      backgroundColor = isCorrect ? Colors.green : Colors.red;
      textColor = Colors.white;
    } else if (showFeedback && isCorrect) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: showFeedback || onAnswerSelected == null
              ? null
              : () => onAnswerSelected!(option),
          child: Text(
            option,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// Video Question Widget
class AdaptedVideoQuestionWidget extends AdaptedQuestionWidget {
  const AdaptedVideoQuestionWidget({
    super.key,
    required super.question,
    required super.onAnswerSelected,
    super.showFeedback,
    super.selectedAnswer,
    super.isMultiplayer,
  });

  @override
  Widget build(BuildContext context) {
    return _VideoQuestionWidgetStateful(
      question: question,
      onAnswerSelected: onAnswerSelected,
      showFeedback: showFeedback,
      selectedAnswer: selectedAnswer,
    );
  }
}

class _VideoQuestionWidgetStateful extends StatefulWidget {
  final QuestionModel question;
  final Function(String)? onAnswerSelected;
  final bool showFeedback;
  final String? selectedAnswer;
  final bool isMultiplayer;

  const _VideoQuestionWidgetStateful({
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  @override
  State<_VideoQuestionWidgetStateful> createState() => _VideoQuestionWidgetStatefulState();
}

class _VideoQuestionWidgetStatefulState extends State<_VideoQuestionWidgetStateful> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.question.videoUrl?.isNotEmpty == true) {
      _videoController = VideoPlayerController.network(widget.question.videoUrl!);
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayOptions = widget.question.reducedOptions ?? widget.question.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Text(
          widget.question.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Video player
        if (_isLoading)
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_chewieController != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
          ),

        const SizedBox(height: 24),

        // Power-up indicators and hints
        if (widget.question.showHint && widget.question.powerUpHint?.isNotEmpty == true)
          _buildHint(),

        // Answer options
        ...displayOptions.map((option) => _buildAnswerButton(option)),
      ],
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.orange.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.question.powerUpHint!,
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String option) {
    final isSelected = option == widget.selectedAnswer;
    final isCorrect = widget.question.isCorrectAnswer(option);

    Color? backgroundColor;
    Color? textColor;

    if (widget.showFeedback && isSelected) {
      backgroundColor = isCorrect ? Colors.green : Colors.red;
      textColor = Colors.white;
    } else if (widget.showFeedback && isCorrect) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: widget.showFeedback || widget.onAnswerSelected == null
              ? null
              : () => widget.onAnswerSelected!(option),
          child: Text(
            option,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// Audio Question Widget
class AdaptedAudioQuestionWidget extends AdaptedQuestionWidget {
  const AdaptedAudioQuestionWidget({
    super.key,
    required super.question,
    required super.onAnswerSelected,
    super.showFeedback,
    super.selectedAnswer,
    super.isMultiplayer,
  });

  @override
  Widget build(BuildContext context) {
    return _AudioQuestionWidgetStateful(
      question: question,
      onAnswerSelected: onAnswerSelected,
      showFeedback: showFeedback,
      selectedAnswer: selectedAnswer,
    );
  }
}

class _AudioQuestionWidgetStateful extends StatefulWidget {
  final QuestionModel question;
  final Function(String)? onAnswerSelected;
  final bool showFeedback;
  final String? selectedAnswer;
  final bool isMultiplayer;

  const _AudioQuestionWidgetStateful({
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  @override
  State<_AudioQuestionWidgetStateful> createState() => _AudioQuestionWidgetStatefulState();
}

class _AudioQuestionWidgetStatefulState extends State<_AudioQuestionWidgetStateful> {
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
    // You'll need to add an audioUrl field to your QuestionModel or use a custom field
    // For now, using a placeholder URL or checking if there's an audio field in your model
    if (widget.question.type.toLowerCase().contains('audio')) {
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

      // You would set the audio source here when you have an audioUrl field
      // await _audioPlayer.setUrl('your_audio_url_here');

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_playerState!.playing) {
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
    final displayOptions = widget.question.reducedOptions ?? widget.question.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Text(
          widget.question.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Audio player controls
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
              // Audio icon and title
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

              // Play/Pause button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _playerState!.playing
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                        color: Colors.blue.shade600,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar and time display
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
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
                          milliseconds: (value * _duration.inMilliseconds).round(),
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

        // Power-up indicators
        if (widget.question.isBoostedTime || widget.question.isShielded || widget.question.multiplier != null)
          _buildPowerUpIndicators(),

        // Hint display
        if (widget.question.showHint && widget.question.powerUpHint?.isNotEmpty == true)
          _buildHint(),

        // Answer options
        ...displayOptions.map((option) => _buildAnswerButton(option)),
      ],
    );
  }

  Widget _buildPowerUpIndicators() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.question.isBoostedTime) ...[
            Icon(Icons.speed, color: Colors.blue.shade600, size: 16),
            const SizedBox(width: 4),
            Text('Time Boost', style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
            const SizedBox(width: 8),
          ],
          if (widget.question.isShielded) ...[
            Icon(Icons.shield, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 4),
            Text('Protected', style: TextStyle(color: Colors.green.shade600, fontSize: 12)),
            const SizedBox(width: 8),
          ],
          if (widget.question.multiplier != null) ...[
            Icon(Icons.close, color: Colors.purple.shade600, size: 16),
            Text('${widget.question.multiplier}x XP', style: TextStyle(color: Colors.purple.shade600, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.orange.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.question.powerUpHint!,
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String option) {
    final isSelected = option == widget.selectedAnswer;
    final isCorrect = widget.question.isCorrectAnswer(option);

    Color? backgroundColor;
    Color? textColor;

    if (widget.showFeedback && isSelected) {
      backgroundColor = isCorrect ? Colors.green : Colors.red;
      textColor = Colors.white;
    } else if (widget.showFeedback && isCorrect) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: widget.showFeedback || widget.onAnswerSelected == null
              ? null
              : () => widget.onAnswerSelected!(option),
          child: Text(
            option,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
