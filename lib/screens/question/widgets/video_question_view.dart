import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../../game/models/question_model.dart';
import 'answer_option_card.dart';
import 'question_power_ups.dart';

/// Video-based question renderer
class VideoQuestionView extends StatefulWidget {
  final QuestionModel question;
  final void Function(String)? onAnswerSelected;
  final bool showFeedback;
  final String? selectedAnswer;
  final bool isMultiplayer;

  const VideoQuestionView({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  @override
  State<VideoQuestionView> createState() => _VideoQuestionViewState();
}

class _VideoQuestionViewState extends State<VideoQuestionView> {
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
      _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.question.videoUrl!));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
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
