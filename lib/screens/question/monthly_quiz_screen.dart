import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/services/question_loader_service.dart';
import '../../game/models/question_model.dart';

// Provider for monthly quiz questions
final monthlyQuizProvider = FutureProvider<List<QuestionModel>>((ref) async {
  final loader = AdaptedQuestionLoaderService();

  // Get current month to determine theme
  final now = DateTime.now();
  final monthThemes = {
    1: 'science',      // January - Science
    2: 'history',      // February - History
    3: 'literature',   // March - Literature
    4: 'geography',    // April - Geography
    5: 'music',        // May - Music
    6: 'sports',       // June - Sports
    7: 'technology',   // July - Technology
    8: 'entertainment',// August - Entertainment
    9: 'science',      // September - Science
    10: 'history',     // October - History
    11: 'world',       // November - World Affairs
    12: 'general',     // December - Year Review
  };

  final currentTheme = monthThemes[now.month] ?? 'general';

  // Get themed questions for the month
  return await loader.getMixedQuiz(
    questionCount: 15,
    categories: [currentTheme],
    difficulties: ['medium', 'hard'], // Monthly quiz is more challenging
    balanceDifficulties: true,
  );
});

class MonthlyQuizScreen extends ConsumerWidget {
  const MonthlyQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyQuizAsync = ref.watch(monthlyQuizProvider);
    final currentMonth = _getCurrentMonthName();
    final currentTheme = _getCurrentMonthTheme();

    return Scaffold(
      appBar: AppBar(
        title: Text('$currentMonth Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: monthlyQuizAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading monthly challenge...'),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text('Error loading monthly quiz: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(monthlyQuizProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (questions) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly Theme Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_getThemeColor().withOpacity(0.8), _getThemeColor()],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getThemeIcon(),
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$currentMonth Challenge',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${currentTheme.toUpperCase()} Theme',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getThemeDescription(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quiz Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Questions',
                      value: questions.length.toString(),
                      icon: Icons.quiz,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Difficulty',
                      value: 'Medium-Hard',
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'XP Reward',
                      value: '${questions.length * 25}',
                      icon: Icons.star,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Question Preview
              Text(
                'Preview Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),

              ...questions.take(3).map((question) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _QuestionPreviewCard(question: question),
              )),

              if (questions.length > 3)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${questions.length - 3} more questions...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),

              // Start Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to quiz with monthly questions
                    context.push('quiz/play', extra: {
                      'questions': questions,
                      'title': '$currentMonth Challenge',
                      'isMonthlyChallenge': true,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getThemeColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start $currentMonth Challenge',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentMonthName() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[DateTime.now().month - 1];
  }

  String _getCurrentMonthTheme() {
    final themes = {
      1: 'Science', 2: 'History', 3: 'Literature', 4: 'Geography',
      5: 'Music', 6: 'Sports', 7: 'Technology', 8: 'Entertainment',
      9: 'Science', 10: 'History', 11: 'World Affairs', 12: 'General Knowledge'
    };
    return themes[DateTime.now().month] ?? 'General Knowledge';
  }

  Color _getThemeColor() {
    final colors = {
      1: Colors.blue, 2: Colors.brown, 3: Colors.orange, 4: Colors.teal,
      5: Colors.deepPurple, 6: Colors.green, 7: Colors.purple, 8: Colors.pink,
      9: Colors.blue, 10: Colors.brown, 11: Colors.indigo, 12: Colors.grey,
    };
    return colors[DateTime.now().month] ?? Colors.grey;
  }

  IconData _getThemeIcon() {
    final icons = {
      1: Icons.science, 2: Icons.history_edu, 3: Icons.menu_book, 4: Icons.public,
      5: Icons.music_note, 6: Icons.sports_soccer, 7: Icons.computer, 8: Icons.movie,
      9: Icons.science, 10: Icons.history_edu, 11: Icons.language, 12: Icons.quiz,
    };
    return icons[DateTime.now().month] ?? Icons.quiz;
  }

  String _getThemeDescription() {
    final descriptions = {
      1: 'Explore the wonders of science and discovery',
      2: 'Journey through historical events and civilizations',
      3: 'Dive into classic and modern literature',
      4: 'Discover countries, capitals, and landmarks',
      5: 'Test your knowledge of music and artists',
      6: 'Challenge yourself with sports trivia',
      7: 'Explore technology and innovation',
      8: 'Entertainment, movies, and pop culture',
      9: 'Advanced science and research topics',
      10: 'Deep dive into historical mysteries',
      11: 'Current events and global affairs',
      12: 'Year-end mixed knowledge challenge',
    };
    return descriptions[DateTime.now().month] ?? 'Test your knowledge across various topics';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  final QuestionModel question;

  const _QuestionPreviewCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getDifficultyColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getDifficultyIcon(),
              color: _getDifficultyColor(),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              question.question,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (question.difficulty) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getDifficultyIcon() {
    switch (question.difficulty) {
      case 1: return Icons.star_outline;
      case 2: return Icons.star_half;
      case 3: return Icons.star;
      default: return Icons.help_outline;
    }
  }
}
