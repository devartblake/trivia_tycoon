import 'package:flutter/material.dart';

/// Displays feedback after answer submission (correct/incorrect with explanation)
class QuestionFeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String? explanation;
  final String? hint;
  final VoidCallback? onNext;
  final int? xpEarned;
  final int? coinsEarned;
  final bool? streakBonus;

  const QuestionFeedbackPanel({
    super.key,
    required this.isCorrect,
    this.explanation,
    this.hint,
    this.onNext,
    this.xpEarned,
    this.coinsEarned,
    this.streakBonus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          if (explanation != null) ...[
            const SizedBox(height: 12),
            Text(
              'Explanation',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              explanation!,
              style: TextStyle(
                fontSize: 14,
                color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
          if (hint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (xpEarned != null || coinsEarned != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (xpEarned != null)
                  _RewardChip(
                    icon: Icons.flash_on,
                    label: 'XP',
                    value: xpEarned.toString(),
                    color: Colors.amber,
                  ),
                if (coinsEarned != null)
                  _RewardChip(
                    icon: Icons.monetization_on,
                    label: 'Coins',
                    value: coinsEarned.toString(),
                    color: Colors.orange,
                  ),
                if (streakBonus == true)
                  _RewardChip(
                    icon: Icons.local_fire_department,
                    label: 'Streak!',
                    value: '🔥',
                    color: Colors.red,
                  ),
              ],
            ),
          ],
          if (onNext != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? Colors.green : Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Next Question',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RewardChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '+$value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
