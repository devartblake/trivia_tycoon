import 'package:flutter/material.dart';
import '../../../game/models/question_model.dart';

class EnhancedQuestionDisplay extends StatelessWidget {
  final String question;
  final String category;
  final int difficulty;
  final String? imageUrl;
  final String classLevel;
  final bool hasHint;
  final String? hint;

  const EnhancedQuestionDisplay({
    super.key,
    required this.question,
    required this.category,
    required this.difficulty,
    this.imageUrl,
    this.classLevel = '1',
    this.hasHint = false,
    this.hint,
  });

  Color _getClassColor() {
    switch (classLevel.toLowerCase()) {
      case 'kindergarten':
      case 'k':
        return Colors.pink;
      case '1':
        return Colors.orange;
      case '2':
        return Colors.blue;
      case '3':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  IconData _getDifficultyIcon() {
    switch (difficulty) {
      case 1:
        return Icons.star_outline;
      case 2:
        return Icons.star_half;
      case 3:
        return Icons.star;
      default:
        return Icons.help_outline;
    }
  }

  Color _getDifficultyColor() {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final classColor = _getClassColor();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: classColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: classColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category and Difficulty Tags
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: classColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category,
                      size: 14,
                      color: classColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: classColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDifficultyColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getDifficultyIcon(),
                      size: 14,
                      color: _getDifficultyColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ['EASY', 'MEDIUM', 'HARD'][difficulty - 1],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getDifficultyColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Question Image (if available)
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 48),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Question Text
          Text(
            question,
            style: TextStyle(
              fontSize: _getQuestionFontSize(),
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),

          // Hint (if available and shown)
          if (hasHint && hint != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hint:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hint!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
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

  double _getQuestionFontSize() {
    // Age-appropriate font sizes
    switch (classLevel.toLowerCase()) {
      case 'kindergarten':
      case 'k':
        return 20;
      case '1':
        return 19;
      case '2':
        return 18;
      case '3':
        return 18;
      default:
        return 17;
    }
  }
}
