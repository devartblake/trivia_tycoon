import 'package:flutter/material.dart';
import '../../../game/models/question_model.dart';

// Base Question Widget with Multiplayer Support
abstract class BaseMultiplayerQuestionWidget extends StatelessWidget {
  final QuestionModel question;
  final Function(String)? onAnswerSelected;
  final bool showFeedback;
  final String? selectedAnswer;
  final bool isMultiplayer;

  const BaseMultiplayerQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.showFeedback = false,
    this.selectedAnswer,
    this.isMultiplayer = false,
  });

  // Common styling for multiplayer mode
  Color get primaryColor => isMultiplayer
      ? const Color(0xFF6366F1)
      : Theme.of(context).primaryColor;

  Color get accentColor => isMultiplayer
      ? const Color(0xFF8B5CF6)
      : Theme.of(context).colorScheme.secondary;

  EdgeInsets get questionPadding => isMultiplayer
      ? const EdgeInsets.all(20)
      : const EdgeInsets.all(16);

  double get optionSpacing => isMultiplayer ? 16 : 12;

  BuildContext get context;
}

// Multiple Choice Question Widget for Multiplayer
class MultipleChoiceQuestionWidget extends BaseMultiplayerQuestionWidget {
  const MultipleChoiceQuestionWidget({
    super.key,
    required super.question,
    required super.onAnswerSelected,
    super.showFeedback = false,
    super.selectedAnswer,
    super.isMultiplayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: questionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text with multiplayer styling
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isMultiplayer
                  ? LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  accentColor.withOpacity(0.1),
                ],
              )
                  : null,
              color: isMultiplayer ? null : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: isMultiplayer
                  ? Border.all(color: primaryColor.withOpacity(0.3))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMultiplayer) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primaryColor, accentColor]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.quiz,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MULTIPLAYER QUESTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  question.question,
                  style: TextStyle(
                    fontSize: isMultiplayer ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: optionSpacing + 8),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
            final isSelected = selectedAnswer == option;
            final isCorrect = showFeedback && option == question.correctAnswer;
            final isWrong = showFeedback && isSelected && !isCorrect;

            return Padding(
              padding: EdgeInsets.only(bottom: optionSpacing),
              child: _buildOptionCard(
                optionLabel,
                option,
                isSelected,
                isCorrect,
                isWrong,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
      String label,
      String option,
      bool isSelected,
      bool isCorrect,
      bool isWrong,
      ) {
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.grey.shade800;
    IconData? icon;

    if (showFeedback) {
      if (isCorrect) {
        cardColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
      } else if (isWrong) {
        cardColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
      }
    } else if (isSelected) {
      if (isMultiplayer) {
        cardColor = primaryColor.withOpacity(0.1);
        borderColor = primaryColor;
        textColor = primaryColor;
      } else {
        cardColor = Colors.blue.shade50;
        borderColor = Colors.blue;
        textColor = Colors.blue.shade800;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isSelected || showFeedback ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected || showFeedback)
            BoxShadow(
              color: borderColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onAnswerSelected != null && !showFeedback
              ? () => onAnswerSelected!(option)
              : null,
          child: Padding(
            padding: EdgeInsets.all(isMultiplayer ? 20 : 16),
            child: Row(
              children: [
                // Option label (A, B, C, D)
                Container(
                  width: isMultiplayer ? 36 : 32,
                  height: isMultiplayer ? 36 : 32,
                  decoration: BoxDecoration(
                    color: isSelected || showFeedback
                        ? borderColor
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected || showFeedback
                            ? Colors.white
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: isMultiplayer ? 16 : 14,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: isMultiplayer ? 16 : 12),

                // Option text
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: isMultiplayer ? 16 : 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                ),

                // Feedback icon
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    color: borderColor,
                    size: isMultiplayer ? 24 : 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  BuildContext get context => throw UnimplementedError();
}

// True/False Question Widget for Multiplayer
class TrueFalseQuestionWidget extends BaseMultiplayerQuestionWidget {
  const TrueFalseQuestionWidget({
    super.key,
    required super.question,
    required super.onAnswerSelected,
    super.showFeedback = false,
    super.selectedAnswer,
    super.isMultiplayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: questionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text with multiplayer styling
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isMultiplayer
                  ? LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  accentColor.withOpacity(0.1),
                ],
              )
                  : null,
              color: isMultiplayer ? null : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: isMultiplayer
                  ? Border.all(color: primaryColor.withOpacity(0.3))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMultiplayer) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primaryColor, accentColor]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TRUE OR FALSE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  question.question,
                  style: TextStyle(
                    fontSize: isMultiplayer ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: optionSpacing + 8),

          // True/False options
          Row(
            children: [
              Expanded(
                child: _buildTrueFalseOption('True', true),
              ),
              SizedBox(width: optionSpacing),
              Expanded(
                child: _buildTrueFalseOption('False', false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrueFalseOption(String label, bool isTrue) {
    final optionValue = isTrue ? 'True' : 'False';
    final isSelected = selectedAnswer == optionValue;
    final isCorrect = showFeedback && optionValue == question.correctAnswer;
    final isWrong = showFeedback && isSelected && !isCorrect;

    Color cardColor = Colors.white;
    Color borderColor = isTrue ? Colors.green.shade300 : Colors.red.shade300;
    Color textColor = Colors.grey.shade800;
    IconData icon = isTrue ? Icons.check : Icons.close;

    if (showFeedback) {
      if (isCorrect) {
        cardColor = isTrue ? Colors.green.shade50 : Colors.red.shade50;
        borderColor = isTrue ? Colors.green : Colors.red;
        textColor = isTrue ? Colors.green.shade800 : Colors.red.shade800;
      } else if (isWrong) {
        cardColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade400;
        textColor = Colors.grey.shade600;
      }
    } else if (isSelected) {
      if (isMultiplayer) {
        cardColor = primaryColor.withOpacity(0.1);
        borderColor = primaryColor;
        textColor = primaryColor;
      } else {
        cardColor = Colors.blue.shade50;
        borderColor = Colors.blue;
        textColor = Colors.blue.shade800;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isMultiplayer ? 120 : 100,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isSelected || showFeedback ? 3 : 2,
        ),
        boxShadow: [
          if (isSelected || showFeedback)
            BoxShadow(
              color: borderColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onAnswerSelected != null && !showFeedback
              ? () => onAnswerSelected!(optionValue)
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: borderColor,
                  size: isMultiplayer ? 32 : 28,
                ),
              ),
              SizedBox(height: isMultiplayer ? 12 : 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isMultiplayer ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  BuildContext get context => throw UnimplementedError();
}

// Fill in the Blank Question Widget for Multiplayer
class FillBlankQuestionWidget extends BaseMultiplayerQuestionWidget {
  const FillBlankQuestionWidget({
    super.key,
    required super.question,
    required super.onAnswerSelected,
    super.showFeedback = false,
    super.selectedAnswer,
    super.isMultiplayer = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: selectedAnswer ?? '',
    );

    return Container(
      padding: questionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text with multiplayer styling
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isMultiplayer
                  ? LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  accentColor.withOpacity(0.1),
                ],
              )
                  : null,
              color: isMultiplayer ? null : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: isMultiplayer
                  ? Border.all(color: primaryColor.withOpacity(0.3))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMultiplayer) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primaryColor, accentColor]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FILL IN THE BLANK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  question.question,
                  style: TextStyle(
                    fontSize: isMultiplayer ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: optionSpacing + 8),

          // Text input field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: showFeedback
                    ? (selectedAnswer == question.correctAnswer
                    ? Colors.green
                    : Colors.red)
                    : (isMultiplayer ? primaryColor : Colors.grey.shade300),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              enabled: !showFeedback && onAnswerSelected != null,
              style: TextStyle(
                fontSize: isMultiplayer ? 18 : 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your answer here...',
                contentPadding: EdgeInsets.all(isMultiplayer ? 20 : 16),
                border: InputBorder.none,
                suffixIcon: !showFeedback && onAnswerSelected != null
                    ? IconButton(
                  onPressed: () {
                    final answer = controller.text.trim();
                    if (answer.isNotEmpty) {
                      onAnswerSelected!(answer);
                    }
                  },
                  icon: Icon(
                    Icons.send,
                    color: isMultiplayer ? primaryColor : Colors.blue,
                  ),
                )
                    : null,
              ),
              onSubmitted: onAnswerSelected != null && !showFeedback
                  ? (value) {
                final answer = value.trim();
                if (answer.isNotEmpty) {
                  onAnswerSelected!(answer);
                }
              }
                  : null,
            ),
          ),

          if (showFeedback) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Correct Answer:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.correctAnswer,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  BuildContext get context => throw UnimplementedError();
}
