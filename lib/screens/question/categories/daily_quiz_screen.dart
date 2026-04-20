import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/challenges/daily_quiz_widget.dart';

class DailyQuizScreen extends ConsumerWidget {
  const DailyQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyQuizAsync = ref.watch(dailyQuizProvider);
    final dailyQuizStatus = ref.watch(dailyQuizStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: dailyQuizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Unable to load the daily quiz: $error',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        data: (quizData) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.deepOrange.shade400
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.today, size: 28, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Daily Quiz',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dailyQuizStatus.canPlay
                          ? '${quizData.totalQuestions} curated questions ready today'
                          : 'Already completed today. Resets in ${dailyQuizStatus.timeUntilReset}.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current streak: ${dailyQuizStatus.completionStreak}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Today\'s Preview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: quizData.questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final question = quizData.questions[index];
                    return ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withValues(alpha: 0.14),
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        question.question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${question.category} • difficulty ${question.difficulty}',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      dailyQuizStatus.canPlay && quizData.questions.isNotEmpty
                          ? () {
                              context.push('/quiz/play', extra: {
                                'questions': quizData.questions,
                                'questionCount': quizData.questions.length,
                                'classLevel': '9',
                                'displayTitle': 'Daily Quiz',
                              });
                            }
                          : null,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Start Daily Quiz'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
