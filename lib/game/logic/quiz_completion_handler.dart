import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_results_provider.dart';
import '../providers/riverpod_providers.dart';
import '../providers/xp_provider.dart';
import '../services/educational_stats_service.dart';

class QuizCompletionHandler {
  final WidgetRef ref;

  QuizCompletionHandler(this.ref);

  /// Main method to handle quiz completion with full integration
  Future<void> handleQuizCompletion(QuizResults result) async {
    try {
      debugPrint('Starting quiz completion processing...');

      // Initialize services if needed
      final educationalStatsService = ref.read(educationalStatsServiceProvider);
      await educationalStatsService.initialize();

      // Record the quiz result in educational statistics
      await educationalStatsService.recordQuizResult(result);

      // Update XP using your existing system
      incrementXP(ref, result.totalXP);

      // Update the quiz results provider
      ref.read(quizResultsProvider.notifier).state = result;

      // Trigger achievement checks
      await _checkForNewAchievements(result);

      // Refresh providers to show updated data
      ref.invalidate(educationalStatsProvider);
      ref.invalidate(weeklyActivityProvider);

      debugPrint('Quiz completion processed successfully');

    } catch (e) {
      debugPrint('Error processing quiz completion: $e');
      // Don't throw - we don't want to break the quiz flow if stats fail
    }
  }

  Future<void> _checkForNewAchievements(QuizResults result) async {
    try {
      final stats = await ref.read(educationalStatsServiceProvider).getEducationalStats();

      // Check for various achievements
      await _checkFirstQuizAchievement(stats);
      await _checkStreakAchievements(stats);
      await _checkSubjectMasteryAchievements(stats, result);
      await _checkPerfectScoreAchievements(result);
      await _checkVolumeAchievements(stats);

    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  Future<void> _checkFirstQuizAchievement(EducationalStats stats) async {
    if (stats.totalQuizzes == 1) {
      debugPrint('Achievement Unlocked: First Steps!');
    }
  }

  Future<void> _checkStreakAchievements(EducationalStats stats) async {
    switch (stats.currentStreak) {
      case 3:
        debugPrint('Achievement Unlocked: Getting Started (3-day streak)!');
        break;
      case 7:
        debugPrint('Achievement Unlocked: Weekly Warrior (7-day streak)!');
        break;
      case 30:
        debugPrint('Achievement Unlocked: Monthly Master (30-day streak)!');
        break;
      case 100:
        debugPrint('Achievement Unlocked: Dedication Legend (100-day streak)!');
        break;
    }
  }

  Future<void> _checkSubjectMasteryAchievements(EducationalStats stats, QuizResults result) async {
    final subjectStats = stats.subjectStats[result.category];
    if (subjectStats != null) {
      // Math achievements
      if (result.category.toLowerCase().contains('math')) {
        if (subjectStats.quizzesCompleted == 25) {
          debugPrint('Achievement Unlocked: Math Wizard!');
        }
        if (subjectStats.averageScore >= 95 && subjectStats.quizzesCompleted >= 10) {
          debugPrint('Achievement Unlocked: Math Genius!');
        }
      }

      // Science achievements
      if (result.category.toLowerCase().contains('science')) {
        if (subjectStats.correctAnswers >= 100) {
          debugPrint('Achievement Unlocked: Science Explorer!');
        }
        if (subjectStats.averageScore >= 90 && subjectStats.quizzesCompleted >= 15) {
          debugPrint('Achievement Unlocked: Future Scientist!');
        }
      }

      // History achievements
      if (result.category == 'History') {
        if (subjectStats.quizzesCompleted == 20) {
          debugPrint('Achievement Unlocked: History Buff!');
        }
      }

      // Literature achievements
      if (result.category == 'Literature') {
        if (subjectStats.quizzesCompleted == 15) {
          debugPrint('Achievement Unlocked: Bookworm!');
        }
      }
    }
  }

  Future<void> _checkPerfectScoreAchievements(QuizResults result) async {
    final scorePercentage = (result.score / result.totalQuestions) * 100;

    if (scorePercentage == 100) {
      debugPrint('Achievement Unlocked: Perfect Score!');
    }

    if (scorePercentage >= 95) {
      debugPrint('Achievement Unlocked: Nearly Perfect!');
    }
  }

  Future<void> _checkVolumeAchievements(EducationalStats stats) async {
    switch (stats.totalQuizzes) {
      case 10:
        debugPrint('Achievement Unlocked: Getting Serious (10 quizzes)!');
        break;
      case 50:
        debugPrint('Achievement Unlocked: Quiz Master (50 quizzes)!');
        break;
      case 100:
        debugPrint('Achievement Unlocked: Centennial Scholar (100 quizzes)!');
        break;
      case 250:
        debugPrint('Achievement Unlocked: Quiz Legend (250 quizzes)!');
        break;
    }

    // Check for weekly perfect performance
    await _checkWeeklyPerfectPerformance();
  }

  Future<void> _checkWeeklyPerfectPerformance() async {
    try {
      final weeklyData = await ref.read(educationalStatsServiceProvider).getWeeklyActivity();

      // Check if user completed at least one quiz each day this week
      final daysWithQuizzes = weeklyData.where((day) => day['quizzes'] > 0).length;
      if (daysWithQuizzes >= 7) {
        debugPrint('Achievement Unlocked: Weekly Dedication!');

        // Check if all scores this week were 90% or higher
        final allScoresHigh = weeklyData.every((day) =>
        day['quizzes'] == 0 || day['score'] >= 90
        );

        if (allScoresHigh && daysWithQuizzes >= 7) {
          debugPrint('Achievement Unlocked: Perfect Week!');
        }
      }
    } catch (e) {
      debugPrint('Error checking weekly performance: $e');
    }
  }
}

// Static utility class for easy integration
class ProfileDataUpdater {
  static Future<void> updateAfterQuiz(WidgetRef ref, QuizResults results) async {
    final handler = QuizCompletionHandler(ref);
    await handler.handleQuizCompletion(results);

    try {
      // Update profile with XP/level changes
      final profileService = ref.read(playerProfileServiceProvider);
      final xpResult = await profileService.addXP(results.totalXP);

      // Update quiz progress service
      final quizService = ref.read(quizProgressServiceProvider);
      await quizService.updateQuizCompletion(
        questionsTotal: results.totalQuestions,
        questionsCorrect: results.score,
        category: results.category,
        completionTime: results.quizDuration.inSeconds.toDouble(),
      );

      // Save completed quiz to recent history
      await quizService.saveCompletedQuiz(
        title: '${results.category} Quiz',
        score: '${((results.score / results.totalQuestions) * 100).round()}%',
        category: results.category,
      );

      // Update currency balances
      final coinNotifier = ref.read(coinBalanceProvider.notifier);
      final gemNotifier = ref.read(diamondNotifierProvider);
      await coinNotifier.add(results.coins);
      await gemNotifier.addValue(results.diamonds);

      // NEW: Check for tier progression
      final tierManager = ref.read(tierManagerProvider);
      final tierResult = await tierManager.updateTierProgress();

      if (tierResult.tierChanged) {
        debugPrint('Tier progression: ${tierResult.oldTierId} -> ${tierResult.newTierId}');

        // Award tier rewards
        final newTier = await tierManager.getCurrentTier();
        if (newTier != null) {
          await tierManager.awardTierRewards(newTier);

          // Trigger tier up celebration (confetti, sound, etc.)
          final confettiController = ref.read(confettiControllerProvider);
          confettiController.play();
        }
      }

      // Handle any new tier unlocks
      if (tierResult.hasNewUnlocks) {
        for (final tier in tierResult.newUnlocks) {
          debugPrint('New tier unlocked: ${tier.name}');
          await tierManager.awardTierRewards(tier);
        }
      }

      // Handle level up separately (existing logic)
      if (xpResult['leveledUp'] == true) {
        final confettiController = ref.read(confettiControllerProvider);
        confettiController.play();
      }

      debugPrint('Quiz completion processing finished successfully');
    } catch (e) {
      debugPrint('Error in ProfileDataUpdater.updateAfterQuiz: $e');
      rethrow;
    }
  }
}