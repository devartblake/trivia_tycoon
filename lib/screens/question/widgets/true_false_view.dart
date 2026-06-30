import 'package:flutter/material.dart';
import '../../../game/models/question_model.dart';
import 'answer_option_card.dart';
import 'question_power_ups.dart';

/// True/False question renderer
class TrueFalseView extends StatelessWidget {
  final QuestionModel question;
  final void Function(String)? onAnswerSelected;
  final bool showFeedback;
  final String? selectedAnswer;
  final bool isMultiplayer;

  const TrueFalseView({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMultiplayer) const MultiplayerBadge(),
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        if (question.isBoostedTime ||
            question.isShielded ||
            question.multiplier != null)
          PowerUpIndicators(
            isBoostedTime: question.isBoostedTime,
            isShielded: question.isShielded,
            multiplier: question.multiplier,
          ),
        if (question.showHint && question.powerUpHint?.isNotEmpty == true)
          HintPanel(hint: question.powerUpHint!),
        Row(
          children: [
            Expanded(
              child: AnswerOptionCard(
                text: 'True',
                onPressed: showFeedback || onAnswerSelected == null
                    ? null
                    : () => onAnswerSelected!('True'),
                isSelected: 'True' == selectedAnswer,
                isCorrect: question.isCorrectAnswer('True'),
                showFeedback: showFeedback,
                isMultiplayer: isMultiplayer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnswerOptionCard(
                text: 'False',
                onPressed: showFeedback || onAnswerSelected == null
                    ? null
                    : () => onAnswerSelected!('False'),
                isSelected: 'False' == selectedAnswer,
                isCorrect: question.isCorrectAnswer('False'),
                showFeedback: showFeedback,
                isMultiplayer: isMultiplayer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
