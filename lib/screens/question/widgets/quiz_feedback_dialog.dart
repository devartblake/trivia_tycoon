import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../game/models/question_model.dart';

class QuizFeedbackDialog extends StatelessWidget {
  final bool isCorrect;
  final QuestionModel question;
  final int xpGained;
  final bool hasTimeBonus;
  final VoidCallback onNext;
  final bool isLastQuestion;

  const QuizFeedbackDialog({
    super.key,
    required this.isCorrect,
    required this.question,
    required this.xpGained,
    required this.hasTimeBonus,
    required this.onNext,
    required this.isLastQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Result icon with animation
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Result text
            Text(
              isCorrect ? "Correct!" : "Incorrect!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Correct answer (if wrong)
            if (!isCorrect) ...[
              Text(
                "Correct answer:",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.correctAnswer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // XP and bonuses
            if (isCorrect && xpGained > 0) ...[
              _buildRewardRow(
                icon: Icons.star,
                label: "XP Gained",
                value: "+$xpGained",
              ),

              if (hasTimeBonus) ...[
                const SizedBox(height: 8),
                _buildRewardRow(
                  icon: Icons.speed,
                  label: "Time Bonus",
                  value: "50% Extra!",
                ),
              ],

              if (question.multiplier != null && question.multiplier! > 1) ...[
                const SizedBox(height: 8),
                _buildRewardRow(
                  icon: Icons.whatshot,
                  label: "Multiplier",
                  value: "${question.multiplier}x",
                ),
              ],

              const SizedBox(height: 16),
            ],

            // Question explanation (if available)
            if (question.powerUpHint != null && !question.showHint) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Explanation:",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      question.powerUpHint!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                if (!isLastQuestion) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onNext();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Next Question",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to score summary
                        onNext();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "View Results",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper method to show the feedback dialog
Future<void> showQuizFeedbackDialog({
  required BuildContext context,
  required bool isCorrect,
  required QuestionModel question,
  required int xpGained,
  required bool hasTimeBonus,
  required VoidCallback onNext,
  required bool isLastQuestion,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => QuizFeedbackDialog(
      isCorrect: isCorrect,
      question: question,
      xpGained: xpGained,
      hasTimeBonus: hasTimeBonus,
      onNext: onNext,
      isLastQuestion: isLastQuestion,
    ),
  );
}
