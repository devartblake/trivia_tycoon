import 'package:flutter/material.dart';

/// Reusable answer option button with multiple states (normal, selected, correct, incorrect, disabled)
class AnswerOptionCard extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSelected;
  final bool isCorrect;
  final bool showFeedback;
  final bool isMultiplayer;

  const AnswerOptionCard({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSelected = false,
    this.isCorrect = false,
    this.showFeedback = false,
    this.isMultiplayer = false,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color? textColor;

    if (showFeedback && isSelected) {
      backgroundColor = isCorrect ? Colors.green : Colors.red;
      textColor = Colors.white;
    } else if (showFeedback && isCorrect) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    } else if (isSelected && isMultiplayer) {
      backgroundColor = const Color(0xFF6366F1).withValues(alpha: 0.1);
      textColor = const Color(0xFF6366F1);
    } else if (isSelected) {
      backgroundColor = Colors.blue.shade50;
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
          onPressed: showFeedback || onPressed == null ? null : onPressed,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
