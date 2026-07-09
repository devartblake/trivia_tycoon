import 'package:flutter/material.dart';
import '../../../game/models/question_model.dart';
import 'question_card_stack.dart';
import 'question_power_ups.dart';

/// Free-text question renderer: the player types their answer instead of
/// picking an option. Submission is normalized (trimmed) before being passed
/// up; correctness comparison for free-text questions is case- and
/// whitespace-insensitive (see QuestionModel.isCorrectAnswer).
class FreeTextView extends StatefulWidget {
  final QuestionModel question;
  final void Function(String)? onAnswerSelected;
  final bool showFeedback;
  final String? selectedAnswer;
  final bool isMultiplayer;

  const FreeTextView({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  @override
  State<FreeTextView> createState() => _FreeTextViewState();
}

class _FreeTextViewState extends State<FreeTextView> {
  late final TextEditingController _controller;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedAnswer ?? '');
    _submitted =
        widget.selectedAnswer != null && widget.selectedAnswer!.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant FreeTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New question arrived (PageView reuse): reset local input state.
    if (oldWidget.question.id != widget.question.id) {
      _controller.text = widget.selectedAnswer ?? '';
      _submitted =
          widget.selectedAnswer != null && widget.selectedAnswer!.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLocked => _submitted || widget.showFeedback;

  bool get _isCorrect =>
      widget.selectedAnswer != null &&
      widget.question.isCorrectAnswer(widget.selectedAnswer!);

  void _submit() {
    final answer = _controller.text.trim();
    if (answer.isEmpty || _isLocked) return;
    setState(() => _submitted = true);
    widget.onAnswerSelected?.call(answer);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isMultiplayer) const MultiplayerBadge(),
        QuestionCardStack(
          key: ValueKey('ft-${widget.question.id}'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.question.question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F353B),
                  height: 1.3,
                ),
              ),
              if (widget.question.showHint &&
                  widget.question.powerUpHint?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                HintPanel(hint: widget.question.powerUpHint!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          enabled: !_isLocked,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2F353B),
          ),
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLocked ? null : _submit,
            icon: const Icon(Icons.check_rounded),
            label: const Text(
              'Submit Answer',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (widget.showFeedback && widget.selectedAnswer != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isCorrect
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isCorrect
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _isCorrect
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isCorrect ? 'Correct!' : 'Incorrect',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _isCorrect
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                if (!_isCorrect) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Correct answer: ${widget.question.correctAnswer}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
