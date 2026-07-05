import 'package:flutter/material.dart';
import '../../../game/models/question_model.dart';
import 'answer_option_card.dart';
import 'question_card_stack.dart';
import 'question_power_ups.dart';

/// Multiple choice question renderer
class MultipleChoiceView extends StatelessWidget {
  final QuestionModel question;
  final void Function(String)? onAnswerSelected;
  final bool showFeedback;
  final String? selectedAnswer;
  final bool isMultiplayer;

  const MultipleChoiceView({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayOptions = question.reducedOptions ?? question.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMultiplayer) const MultiplayerBadge(),
        QuestionCardStack(
          key: ValueKey('mc-${question.id}'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                question.question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F353B),
                  height: 1.3,
                ),
              ),
              if (question.isBoostedTime ||
                  question.isShielded ||
                  question.multiplier != null) ...[
                const SizedBox(height: 16),
                PowerUpIndicators(
                  isBoostedTime: question.isBoostedTime,
                  isShielded: question.isShielded,
                  multiplier: question.multiplier,
                ),
              ],
              if (question.showHint &&
                  question.powerUpHint?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                HintPanel(hint: question.powerUpHint!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        ...displayOptions.map(
          (option) => AnswerOptionCard(
            text: option,
            onPressed: showFeedback || onAnswerSelected == null
                ? null
                : () => onAnswerSelected!(option),
            isSelected: option == selectedAnswer,
            isCorrect: question.isCorrectAnswer(option),
            showFeedback: showFeedback,
            isMultiplayer: isMultiplayer,
          ),
        ),
      ],
    );
  }
}
