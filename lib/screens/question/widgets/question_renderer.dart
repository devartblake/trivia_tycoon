import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../game/models/question_model.dart';
import '../../../game/models/question_type.dart';
import 'multiple_choice_view.dart';
import 'true_false_view.dart';
import 'image_question_view.dart';
import 'video_question_view.dart';
import 'audio_question_view.dart';
import 'drag_drop_view.dart';
import 'sorting_view.dart';
import 'matching_view.dart';
import 'free_text_view.dart';

/// Unified question renderer that dispatches to type-specific views
class QuestionRenderer extends StatelessWidget {
  final QuestionModel question;
  final void Function(String)? onAnswerSelected;
  final bool showFeedback;
  final String? selectedAnswer;
  final bool isMultiplayer;

  const QuestionRenderer({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return _buildQuestionView();
  }

  Widget _buildQuestionView() {
    switch (question.type) {
      case QuestionType.trueFalse:
        return TrueFalseView(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );

      case QuestionType.imageChoice:
        return ImageQuestionView(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );

      case QuestionType.videoChoice:
        return VideoQuestionView(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );

      case QuestionType.audioChoice:
        return AudioQuestionView(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );

      case QuestionType.dragDrop:
        return DragDropView(
          question: question,
          onAnswerSelected: (mapping) {
            onAnswerSelected?.call(jsonEncode(mapping));
          },
          showFeedback: showFeedback,
          selectedAnswer: _parseMapFromString(selectedAnswer),
          isMultiplayer: isMultiplayer,
        );

      case QuestionType.sorting:
        return SortingView(
          question: question,
          onAnswerSelected: (order) {
            onAnswerSelected?.call(jsonEncode(order));
          },
          showFeedback: showFeedback,
          selectedAnswer: _parseListFromString(selectedAnswer),
          isMultiplayer: isMultiplayer,
        );

      case QuestionType.matching:
        return MatchingView(
          question: question,
          onAnswerSelected: (mapping) {
            onAnswerSelected?.call(jsonEncode(mapping));
          },
          showFeedback: showFeedback,
          selectedAnswer: _parseMapFromString(selectedAnswer),
          isMultiplayer: isMultiplayer,
        );

      case QuestionType.freeText:
        return FreeTextView(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );

      case QuestionType.multipleChoice:
      default:
        return MultipleChoiceView(
          question: question,
          onAnswerSelected: onAnswerSelected,
          showFeedback: showFeedback,
          selectedAnswer: selectedAnswer,
          isMultiplayer: isMultiplayer,
        );
    }
  }

  Map<String, String>? _parseMapFromString(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return Map<String, String>.from(decoded);
      }
    } catch (_) {
      // Ignore parsing errors
    }
    return null;
  }

  List<String>? _parseListFromString(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return List<String>.from(decoded);
      }
    } catch (_) {
      // Ignore parsing errors
    }
    return null;
  }
}
