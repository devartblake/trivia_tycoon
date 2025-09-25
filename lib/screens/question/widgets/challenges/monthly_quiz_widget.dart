import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../game/services/question_loader_service.dart';
import '../../../../game/models/question_model.dart';

// Provider for monthly quiz preview data
final monthlyQuizPreviewProvider = FutureProvider<MonthlyQuizPreview>((ref) async {
  final loader = AdaptedQuestionLoaderService();
  final now = DateTime.now();

  // Monthly themes
  final monthThemes = {
    1: 'science', 2: 'history', 3: 'literature', 4: 'geography',
    5: 'music', 6: 'sports', 7: 'technology', 8: 'entertainment',
    9: 'science', 10: 'history', 11: 'world', 12: 'general',
  };

  final currentTheme = monthThemes[now.month] ?? 'general';

  try {
    // Get a preview of questions for the monthly challenge
    final questions = await loader.getMixedQuiz(
      questionCount: 3, // Just for preview
      categories: [currentTheme],
      difficulties: ['medium', 'hard'],
    );

    return MonthlyQuizPreview(
      theme: currentTheme,
      monthName: _getMonthName(now.month),
      totalQuestions: 15, // Full monthly quiz has 15 questions
      previewQuestions: questions,
      difficulty: 'Medium-Hard',
      xpReward: 375, // 15 questions * 25 XP each
      isCompleted: false, // TODO: Check completion status
      completionRate: 0.0, // TODO: Get from user progress
    );
  } catch (e) {
    debugPrint('Error loading monthly quiz preview: $e');
    rethrow;
  }
});

class MonthlyQuizWidget extends ConsumerWidget {
  const MonthlyQuizWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyPreviewAsync = ref.watch(monthlyQuizPreviewProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade500, Colors.blue.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: monthlyPreviewAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stackTrace) => _buildErrorState(context, ref),
        data: (preview) => _buildDataState(context, preview),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Monthly Challenge",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Loading...",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 80,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.calendar_month,
            color: Colors.white,
            size: 35,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Monthly Challenge",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Error loading challenge",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(monthlyQuizPreviewProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            color: Colors.white,
            size: 35,
          ),
        ),
      ],
    );
  }

  Widget _buildDataState(BuildContext context, MonthlyQuizPreview preview) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getThemeIcon(preview.theme),
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "${preview.monthName} Challenge",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "${preview.theme.toUpperCase()} • ${preview.totalQuestions} questions",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              if (preview.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "COMPLETED",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (preview.completionRate > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${(preview.completionRate * 100).round()}% Complete",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: preview.completionRate,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _handleMonthlyChallengeTap(context, preview),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: Text(
                  preview.isCompleted ? "View Results" : "Start Challenge",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getThemeIcon(preview.theme),
                color: Colors.white,
                size: 35,
              ),
            ),
            if (!preview.isCompleted)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${preview.totalQuestions}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _handleMonthlyChallengeTap(BuildContext context, MonthlyQuizPreview preview) {
    // Navigate to monthly quiz screen (full dedicated screen)
    context.push('/monthly-quiz');
  }

  IconData _getThemeIcon(String theme) {
    switch (theme.toLowerCase()) {
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'literature':
        return Icons.menu_book;
      case 'geography':
        return Icons.public;
      case 'music':
        return Icons.music_note;
      case 'sports':
        return Icons.sports_soccer;
      case 'technology':
        return Icons.computer;
      case 'entertainment':
        return Icons.movie;
      case 'world':
        return Icons.language;
      default:
        return Icons.quiz;
    }
  }
}

// Data model for monthly quiz preview
class MonthlyQuizPreview {
  final String theme;
  final String monthName;
  final int totalQuestions;
  final List<QuestionModel> previewQuestions;
  final String difficulty;
  final int xpReward;
  final bool isCompleted;
  final double completionRate;

  const MonthlyQuizPreview({
    required this.theme,
    required this.monthName,
    required this.totalQuestions,
    required this.previewQuestions,
    required this.difficulty,
    required this.xpReward,
    required this.isCompleted,
    required this.completionRate,
  });
}

// Helper function
String _getMonthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month - 1];
}
