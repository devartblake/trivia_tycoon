import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../game/services/question_loader_service.dart';
import '../../../../game/models/question_model.dart';

// Provider for daily quiz data
final dailyQuizProvider = FutureProvider<DailyQuizData>((ref) async {
  final loader = AdaptedQuestionLoaderService();

  try {
    final questions = await loader.getDailyQuiz(questionCount: 5);
    final stats = await loader.getAllDatasetStats();

    return DailyQuizData(
      questions: questions,
      totalQuestions: questions.length,
      totalXPReward: questions.length * 15, // 15 XP per question
      isCompleted: false, // TODO: Check completion status in persistent storage
      lastCompletedDate: null, // TODO: Get from user progress
    );
  } catch (e) {
    debugPrint('Error loading daily quiz: $e');
    rethrow;
  }
});

// Provider for checking if daily quiz is available
final dailyQuizStatusProvider = Provider<DailyQuizStatus>((ref) {
  final now = DateTime.now();
  final lastCompleted = DateTime(2024, 1, 1); // TODO: Get from user progress

  final isNewDay = !_isSameDay(now, lastCompleted);
  final timeUntilReset = _getTimeUntilMidnight();

  return DailyQuizStatus(
    isAvailable: isNewDay,
    timeUntilReset: timeUntilReset,
    canPlay: isNewDay,
    completionStreak: 0, // TODO: Get from user progress
  );
});

class DailyQuizWidget extends ConsumerWidget {
  const DailyQuizWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyQuizAsync = ref.watch(dailyQuizProvider);
    final quizStatus = ref.watch(dailyQuizStatusProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.yellow.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: dailyQuizAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stackTrace) => _buildErrorState(context, ref, error),
        data: (dailyQuizData) => _buildDataState(context, dailyQuizData, quizStatus),
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
                "Daily Quiz",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
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
                width: 100,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.help,
            color: Colors.white,
            size: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Daily Quiz",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Error loading quiz",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(dailyQuizProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            color: Colors.white,
            size: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildDataState(BuildContext context, DailyQuizData quizData, DailyQuizStatus status) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Daily Quiz",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (status.completionStreak > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${status.completionStreak}🔥',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                status.canPlay
                    ? "${quizData.totalQuestions} questions • ${quizData.totalXPReward} XP"
                    : "Completed! Reset in ${status.timeUntilReset}",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: status.canPlay
                    ? () => _handleDailyQuizTap(context, quizData)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: status.canPlay ? Colors.white : Colors.white54,
                  foregroundColor: Colors.orange.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  status.canPlay ? "Start Quiz" : "Completed",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status.canPlay ? Icons.play_arrow : Icons.check_circle,
                color: Colors.white,
                size: 40,
              ),
            ),
            if (status.canPlay && quizData.questions.isNotEmpty)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${quizData.totalQuestions}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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

  void _handleDailyQuizTap(BuildContext context, DailyQuizData quizData) {
    if (quizData.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No daily questions available. Please try again later.'),
        ),
      );
      return;
    }

    // Navigate to detailed daily quiz screen
    context.push('/daily-quiz');
  }
}

// Data models for daily quiz
class DailyQuizData {
  final List<QuestionModel> questions;
  final int totalQuestions;
  final int totalXPReward;
  final bool isCompleted;
  final DateTime? lastCompletedDate;

  const DailyQuizData({
    required this.questions,
    required this.totalQuestions,
    required this.totalXPReward,
    required this.isCompleted,
    this.lastCompletedDate,
  });
}

class DailyQuizStatus {
  final bool isAvailable;
  final String timeUntilReset;
  final bool canPlay;
  final int completionStreak;

  const DailyQuizStatus({
    required this.isAvailable,
    required this.timeUntilReset,
    required this.canPlay,
    required this.completionStreak,
  });
}

// Helper functions
bool _isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

String _getTimeUntilMidnight() {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final difference = tomorrow.difference(now);

  final hours = difference.inHours;
  final minutes = difference.inMinutes.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else {
    return '${minutes}m';
  }
}