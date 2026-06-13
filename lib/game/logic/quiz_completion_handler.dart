import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/quiz_results_provider.dart';
import '../providers/riverpod_providers.dart';
import '../providers/xp_provider.dart';
import '../providers/economy_providers.dart';
import '../services/educational_stats_service.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class QuizCompletionHandler {
  final WidgetRef ref;

  QuizCompletionHandler(this.ref);

  /// Main method to handle quiz completion with full integration
  Future<void> handleQuizCompletion(QuizResults result) async {
    try {
      LogManager.debug('Starting quiz completion processing...');

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
      await _recordMissionProgress(result);

      // Refresh providers to show updated data
      ref.invalidate(educationalStatsProvider);
      ref.invalidate(weeklyActivityProvider);

      LogManager.debug('Quiz completion processed successfully');
    } catch (e) {
      LogManager.debug('Error processing quiz completion: $e');
      // Don't throw - we don't want to break the quiz flow if stats fail
    }
  }

  Future<void> _recordMissionProgress(QuizResults result) async {
    try {
      final playerId = await ref.read(currentPlayerIdProvider.future);
      if (playerId == null || playerId.isEmpty) return;

      final service = ref.read(backendMissionServiceProvider);
      final isWin = result.totalQuestions > 0 &&
          (result.score / result.totalQuestions) > 0.5;
      final perfectRound =
          result.totalQuestions > 0 && result.score >= result.totalQuestions;
      final averageAnswerTimeMs = result.totalQuestions <= 0
          ? 0
          : (result.quizDuration.inMilliseconds / result.totalQuestions)
              .round();

      await service.recordMatchCompleted(
        eventId: const Uuid().v4(),
        playerId: playerId,
        isWin: isWin,
        correctAnswers: result.score,
        totalQuestions: result.totalQuestions,
        durationSeconds: result.quizDuration.inSeconds,
      );

      await service.recordRoundCompleted(
        eventId: const Uuid().v4(),
        playerId: playerId,
        perfectRound: perfectRound,
        averageAnswerTimeMs: averageAnswerTimeMs,
      );
    } catch (e) {
      LogManager.debug('Mission progress submission skipped: $e');
    }
  }

  Future<void> _checkForNewAchievements(QuizResults result) async {
    try {
      final stats =
          await ref.read(educationalStatsServiceProvider).getEducationalStats();

      // Check for various achievements
      await _checkFirstQuizAchievement(stats);
      await _checkStreakAchievements(stats);
      await _checkSubjectMasteryAchievements(stats, result);
      await _checkPerfectScoreAchievements(result);
      await _checkVolumeAchievements(stats);
    } catch (e) {
      LogManager.debug('Error checking achievements: $e');
    }
  }

  Future<void> _checkFirstQuizAchievement(EducationalStats stats) async {
    if (stats.totalQuizzes == 1) {
      LogManager.debug('Achievement Unlocked: First Steps!');
    }
  }

  Future<void> _checkStreakAchievements(EducationalStats stats) async {
    switch (stats.currentStreak) {
      case 3:
        LogManager.debug(
            'Achievement Unlocked: Getting Started (3-day streak)!');
        break;
      case 7:
        LogManager.debug(
            'Achievement Unlocked: Weekly Warrior (7-day streak)!');
        break;
      case 30:
        LogManager.debug(
            'Achievement Unlocked: Monthly Master (30-day streak)!');
        break;
      case 100:
        LogManager.debug(
            'Achievement Unlocked: Dedication Legend (100-day streak)!');
        break;
    }
  }

  Future<void> _checkSubjectMasteryAchievements(
      EducationalStats stats, QuizResults result) async {
    final subjectStats = stats.subjectStats[result.category];
    if (subjectStats != null) {
      // Math achievements
      if (result.category.toLowerCase().contains('math')) {
        if (subjectStats.quizzesCompleted == 25) {
          LogManager.debug('Achievement Unlocked: Math Wizard!');
        }
        if (subjectStats.averageScore >= 95 &&
            subjectStats.quizzesCompleted >= 10) {
          LogManager.debug('Achievement Unlocked: Math Genius!');
        }
      }

      // Science achievements
      if (result.category.toLowerCase().contains('science')) {
        if (subjectStats.correctAnswers >= 100) {
          LogManager.debug('Achievement Unlocked: Science Explorer!');
        }
        if (subjectStats.averageScore >= 90 &&
            subjectStats.quizzesCompleted >= 15) {
          LogManager.debug('Achievement Unlocked: Future Scientist!');
        }
      }

      // History achievements
      if (result.category == 'History') {
        if (subjectStats.quizzesCompleted == 20) {
          LogManager.debug('Achievement Unlocked: History Buff!');
        }
      }

      // Literature achievements
      if (result.category == 'Literature') {
        if (subjectStats.quizzesCompleted == 15) {
          LogManager.debug('Achievement Unlocked: Bookworm!');
        }
      }
    }
  }

  Future<void> _checkPerfectScoreAchievements(QuizResults result) async {
    final scorePercentage = (result.score / result.totalQuestions) * 100;

    if (scorePercentage == 100) {
      LogManager.debug('Achievement Unlocked: Perfect Score!');
    }

    if (scorePercentage >= 95) {
      LogManager.debug('Achievement Unlocked: Nearly Perfect!');
    }
  }

  Future<void> _checkVolumeAchievements(EducationalStats stats) async {
    switch (stats.totalQuizzes) {
      case 10:
        LogManager.debug('Achievement Unlocked: Getting Serious (10 quizzes)!');
        break;
      case 50:
        LogManager.debug('Achievement Unlocked: Quiz Master (50 quizzes)!');
        break;
      case 100:
        LogManager.debug(
            'Achievement Unlocked: Centennial Scholar (100 quizzes)!');
        break;
      case 250:
        LogManager.debug('Achievement Unlocked: Quiz Legend (250 quizzes)!');
        break;
    }

    // Check for weekly perfect performance
    await _checkWeeklyPerfectPerformance();
  }

  Future<void> _checkWeeklyPerfectPerformance() async {
    try {
      final weeklyData =
          await ref.read(educationalStatsServiceProvider).getWeeklyActivity();

      // Check if user completed at least one quiz each day this week
      final daysWithQuizzes =
          weeklyData.where((day) => day['quizzes'] > 0).length;
      if (daysWithQuizzes >= 7) {
        LogManager.debug('Achievement Unlocked: Weekly Dedication!');

        // Check if all scores this week were 90% or higher
        final allScoresHigh = weeklyData
            .every((day) => day['quizzes'] == 0 || day['score'] >= 90);

        if (allScoresHigh && daysWithQuizzes >= 7) {
          LogManager.debug('Achievement Unlocked: Perfect Week!');
        }
      }
    } catch (e) {
      LogManager.debug('Error checking weekly performance: $e');
    }
  }
}

// Static utility class for easy integration
class ProfileDataUpdater {
  static Future<void> updateAfterQuiz(
      WidgetRef ref, QuizResults results) async {
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
        LogManager.debug(
            'Tier progression: ${tierResult.oldTierId} -> ${tierResult.newTierId}');

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
          LogManager.debug('New tier unlocked: ${tier.name}');
          await tierManager.awardTierRewards(tier);
        }
      }

      // Handle level up separately (existing logic)
      if (xpResult['leveledUp'] == true) {
        final confettiController = ref.read(confettiControllerProvider);
        confettiController.play();
      }

      LogManager.debug('Quiz completion processing finished successfully');

      // Fire-and-forget: post solo quiz score to backend leaderboard.
      // Same pattern as _reportPity: async chain, errors swallowed so the
      // local completion flow is never blocked by a network failure.
      unawaited(
        ref.read(currentUserIdProvider.future).then((playerId) {
          return ref
              .read(leaderboardControllerProvider)
              .submitScore(playerId, results.score);
        }).catchError((_) {}),
      );

      // Fire-and-forget: authoritative server-side XP/coin grant with idempotency.
      // Backend deduplicates via EventId unique index (CompleteQuizHandler).
      unawaited(
        ref.read(currentUserIdProvider.future).then((playerId) {
          return ref.read(apiServiceProvider).submitQuizComplete(
                eventId: const Uuid().v4(),
                playerId: playerId,
                score: results.score,
                totalQuestions: results.totalQuestions,
                category: results.category,
                answers: results.answerSubmissions,
              );
        }).catchError((_) {}),
      );

      // Report win/loss to pity system (non-blocking, fire-and-forget)
      _reportPity(ref, results);

      // Invalidate cached wallet so walletSyncProvider re-fetches from backend.
      // Picks up any server-side balance changes (rewards, purchases, etc.).
      ref.invalidate(walletProvider);
    } catch (e) {
      LogManager.debug('Error in ProfileDataUpdater.updateAfterQuiz: $e');
      rethrow;
    }
  }

  /// Reports the quiz outcome to the pity system.
  /// A score above 50% of total questions is treated as a win.
  static void _reportPity(WidgetRef ref, QuizResults results) {
    ref.read(currentUserIdProvider.future).then((playerId) {
      final isWin = results.totalQuestions > 0 &&
          (results.score / results.totalQuestions) > 0.5;
      if (isWin) {
        ref.read(economyProvider.notifier).reportWin(playerId);
      } else {
        ref.read(economyProvider.notifier).reportLoss(playerId);
      }
    }).catchError((_) {
      // Pity reporting is non-blocking and should never interrupt the flow.
    });
  }
}
