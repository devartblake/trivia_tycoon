import 'package:flutter/material.dart';
import '../../../game/models/question_model.dart';
import '../../../game/models/question_difficulty.dart';

/// Displays question metadata: category, difficulty, tags
class QuestionMetadata extends StatelessWidget {
  final QuestionModel question;
  final bool showDifficultyBadge;
  final bool showTags;

  const QuestionMetadata({
    super.key,
    required this.question,
    this.showDifficultyBadge = true,
    this.showTags = true,
  });

  Color _getDifficultyColor(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return Colors.green;
      case QuestionDifficulty.medium:
        return Colors.blue;
      case QuestionDifficulty.hard:
        return Colors.orange;
      case QuestionDifficulty.expert:
        return Colors.red;
      case QuestionDifficulty.boss:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.category.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              question.category,
              style: TextStyle(
                fontSize: 12,
                // Rendered on the dark quiz canvas — keep it light.
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Row(
          children: [
            if (showDifficultyBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  // Slightly stronger fill so the badge reads on the dark canvas.
                  color: _getDifficultyColor(question.difficulty).withValues(alpha: 0.18),
                  border: Border.all(
                    color: _getDifficultyColor(question.difficulty).withValues(alpha: 0.55),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getDifficultyIcon(question.difficulty),
                      size: 12,
                      color: _getDifficultyColor(question.difficulty),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      question.difficulty.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getDifficultyColor(question.difficulty),
                      ),
                    ),
                  ],
                ),
              ),
            if (showTags && question.tags?.isNotEmpty == true) ...[
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: question.tags!
                        .take(3)
                        .map(
                          (tag) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  IconData _getDifficultyIcon(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return Icons.sentiment_satisfied;
      case QuestionDifficulty.medium:
        return Icons.sentiment_neutral;
      case QuestionDifficulty.hard:
        return Icons.sentiment_dissatisfied;
      case QuestionDifficulty.expert:
        return Icons.whatshot;
      case QuestionDifficulty.boss:
        return Icons.star;
    }
  }
}
