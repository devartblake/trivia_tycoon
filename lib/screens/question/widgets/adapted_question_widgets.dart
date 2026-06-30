import 'package:flutter/material.dart';
import '../../../game/models/question_model.dart';
import 'question_renderer.dart';

/// Backward-compatible factory for adapted question widgets
/// Delegates to QuestionRenderer for type-safe rendering
class AdaptedQuestionWidget extends StatelessWidget {
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

  /// Factory constructor for backward compatibility
  factory AdaptedQuestionWidget.create({
    required QuestionModel question,
    required void Function(String)? onAnswerSelected,
    bool showFeedback = false,
    String? selectedAnswer,
    bool isMultiplayer = false,
  }) {
    return AdaptedQuestionWidget(
      question: question,
      onAnswerSelected: onAnswerSelected,
      showFeedback: showFeedback,
      selectedAnswer: selectedAnswer,
      isMultiplayer: isMultiplayer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionRenderer(
      question: question,
      onAnswerSelected: onAnswerSelected,
      showFeedback: showFeedback,
      selectedAnswer: selectedAnswer,
      isMultiplayer: isMultiplayer,
    );
  }
}
