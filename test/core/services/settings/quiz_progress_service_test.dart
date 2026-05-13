import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/quiz_progress_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quiz_progress_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<QuizProgressService> _make() =>
      QuizProgressService.initialize();

  // Open settings box so sync methods work
  Future<void> _openSettingsBox() async {
    await Hive.openBox('settings');
  }

  // -------------------------------------------------------------------------
  // saveQuizProgress / getQuizProgress
  // -------------------------------------------------------------------------

  group('saveQuizProgress / getQuizProgress', () {
    test('stores and retrieves quiz progress map', () async {
      final svc = await _make();
      await svc.saveQuizProgress({'score': 85, 'question': 3});
      final result = await svc.getQuizProgress();
      expect(result['score'], 85);
      expect(result['question'], 3);
    });

    test('returns empty map when nothing stored', () async {
      final svc = await _make();
      expect(await svc.getQuizProgress(), isEmpty);
    });

    test('overwrites previous progress', () async {
      final svc = await _make();
      await svc.saveQuizProgress({'score': 50});
      await svc.saveQuizProgress({'score': 75});
      expect((await svc.getQuizProgress())['score'], 75);
    });
  });

  // -------------------------------------------------------------------------
  // onboarding
  // -------------------------------------------------------------------------

  group('setOnboardingCompleted / getOnboardingStatus', () {
    test('false by default', () async {
      final svc = await _make();
      expect(await svc.getOnboardingStatus(), isFalse);
    });

    test('true after setOnboardingCompleted', () async {
      final svc = await _make();
      await svc.setOnboardingCompleted();
      expect(await svc.getOnboardingStatus(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // player name
  // -------------------------------------------------------------------------

  group('savePlayerName / getPlayerName', () {
    test('defaults to "Player"', () async {
      final svc = await _make();
      expect(await svc.getPlayerName(), 'Player');
    });

    test('returns saved name', () async {
      final svc = await _make();
      await svc.savePlayerName('Alice');
      expect(await svc.getPlayerName(), 'Alice');
    });

    test('overwrites previous name', () async {
      final svc = await _make();
      await svc.savePlayerName('Alice');
      await svc.savePlayerName('Bob');
      expect(await svc.getPlayerName(), 'Bob');
    });
  });

  // -------------------------------------------------------------------------
  // player progress
  // -------------------------------------------------------------------------

  group('savePlayerProgress / getPlayerProgress', () {
    test('returns empty map when nothing stored', () async {
      final svc = await _make();
      expect(await svc.getPlayerProgress(), isEmpty);
    });

    test('stores and retrieves progress', () async {
      final svc = await _make();
      await svc.savePlayerProgress({'score': 100, 'streak': 5});
      final result = await svc.getPlayerProgress();
      expect(result['score'], 100);
      expect(result['streak'], 5);
    });
  });

  // -------------------------------------------------------------------------
  // updateQuizStats
  // -------------------------------------------------------------------------

  group('updateQuizStats', () {
    test('increments total_questions', () async {
      final svc = await _make();
      await svc.updateQuizStats(questionsAnswered: 5);
      await svc.updateQuizStats(questionsAnswered: 3);
      final progress = await svc.getPlayerProgress();
      expect(progress['total_questions'], 8);
    });

    test('increments correct_answers', () async {
      final svc = await _make();
      await svc.updateQuizStats(correctAnswers: 4);
      await svc.updateQuizStats(correctAnswers: 2);
      final progress = await svc.getPlayerProgress();
      expect(progress['correct_answers'], 6);
    });

    test('sets current_streak', () async {
      final svc = await _make();
      await svc.updateQuizStats(currentStreak: 7);
      final progress = await svc.getPlayerProgress();
      expect(progress['current_streak'], 7);
    });

    test('updates best_streak only when higher', () async {
      final svc = await _make();
      await svc.updateQuizStats(bestStreak: 5);
      await svc.updateQuizStats(bestStreak: 3);
      final progress = await svc.getPlayerProgress();
      expect(progress['best_streak'], 5);
    });

    test('updates best_streak when higher', () async {
      final svc = await _make();
      await svc.updateQuizStats(bestStreak: 5);
      await svc.updateQuizStats(bestStreak: 8);
      final progress = await svc.getPlayerProgress();
      expect(progress['best_streak'], 8);
    });

    test('sets average_time', () async {
      final svc = await _make();
      await svc.updateQuizStats(averageTime: 3.5);
      final progress = await svc.getPlayerProgress();
      expect(progress['average_time'], 3.5);
    });

    test('sets last_updated', () async {
      final svc = await _make();
      final before = DateTime.now();
      await svc.updateQuizStats(questionsAnswered: 1);
      final progress = await svc.getPlayerProgress();
      final updated = DateTime.parse(progress['last_updated']);
      expect(updated.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // clearAllProgress
  // -------------------------------------------------------------------------

  group('clearAllProgress', () {
    test('clears quiz progress', () async {
      final svc = await _make();
      await svc.saveQuizProgress({'score': 100});
      await svc.clearAllProgress();
      expect(await svc.getQuizProgress(), isEmpty);
    });

    test('clears player progress', () async {
      final svc = await _make();
      await svc.savePlayerProgress({'score': 100});
      await svc.clearAllProgress();
      expect(await svc.getPlayerProgress(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // getProgressSummary
  // -------------------------------------------------------------------------

  group('getProgressSummary', () {
    test('has_quiz_progress false when empty', () async {
      final svc = await _make();
      await _openSettingsBox();
      final summary = svc.getProgressSummary();
      expect(summary['has_quiz_progress'], isFalse);
    });

    test('total_questions default 0', () async {
      final svc = await _make();
      await _openSettingsBox();
      final summary = svc.getProgressSummary();
      expect(summary['total_questions'], 0);
    });

    test('best_streak reflected in summary', () async {
      final svc = await _make();
      await svc.updateQuizStats(bestStreak: 10);
      final summary = svc.getProgressSummary();
      expect(summary['best_streak'], 10);
    });
  });

  // -------------------------------------------------------------------------
  // autoSave / restoreFromAutoSave
  // -------------------------------------------------------------------------

  group('autoSave / restoreFromAutoSave', () {
    test('restoreFromAutoSave returns null when nothing saved', () async {
      final svc = await _make();
      expect(await svc.restoreFromAutoSave(), isNull);
    });

    test('restores auto-saved data', () async {
      final svc = await _make();
      await svc.saveQuizProgress({'q': 1});
      await svc.autoSave();
      final restored = await svc.restoreFromAutoSave();
      expect(restored, isNotNull);
      expect(restored!.containsKey('timestamp'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // syncProgress / getLastSyncTime
  // -------------------------------------------------------------------------

  group('syncProgress / getLastSyncTime', () {
    test('getLastSyncTime returns null before sync', () async {
      final svc = await _make();
      expect(await svc.getLastSyncTime(), isNull);
    });

    test('syncProgress sets last sync time', () async {
      final svc = await _make();
      final before = DateTime.now();
      await svc.syncProgress();
      final syncTime = await svc.getLastSyncTime();
      expect(syncTime, isNotNull);
      expect(
          syncTime!.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // saveCurrentProgress (lifecycle)
  // -------------------------------------------------------------------------

  group('saveCurrentProgress', () {
    test('adds last_saved and save_reason to quiz progress', () async {
      final svc = await _make();
      await svc.saveQuizProgress({'score': 10});
      await svc.saveCurrentProgress();
      final result = await svc.getQuizProgress();
      expect(result['last_saved'], isNotNull);
      expect(result['save_reason'], 'lifecycle_pause');
    });
  });

  // -------------------------------------------------------------------------
  // Daily quiz tracking
  // -------------------------------------------------------------------------

  group('Daily quiz tracking', () {
    test('getDailyQuizLastCompletedDateSync returns null initially', () async {
      await _make();
      await _openSettingsBox();
      final svc = await _make();
      expect(svc.getDailyQuizLastCompletedDateSync(), isNull);
    });

    test('getDailyQuizStreakSync returns 0 initially', () async {
      await _make();
      await _openSettingsBox();
      final svc = await _make();
      expect(svc.getDailyQuizStreakSync(), 0);
    });

    test('markDailyQuizCompleted sets streak to 1 on first completion',
        () async {
      await _openSettingsBox();
      final svc = await _make();
      await svc.markDailyQuizCompleted();
      expect(svc.getDailyQuizStreakSync(), 1);
    });

    test('markDailyQuizCompleted sets lastCompletedDate to today', () async {
      await _openSettingsBox();
      final svc = await _make();
      await svc.markDailyQuizCompleted();
      final date = svc.getDailyQuizLastCompletedDateSync();
      expect(date, isNotNull);
      final now = DateTime.now();
      expect(date!.year, now.year);
      expect(date.month, now.month);
      expect(date.day, now.day);
    });

    test('markDailyQuizCompleted is idempotent on same day', () async {
      await _openSettingsBox();
      final svc = await _make();
      await svc.markDailyQuizCompleted();
      await svc.markDailyQuizCompleted();
      expect(svc.getDailyQuizStreakSync(), 1);
    });
  });

  // -------------------------------------------------------------------------
  // Monthly quiz tracking
  // -------------------------------------------------------------------------

  group('Monthly quiz tracking', () {
    test('getMonthlyQuizCompletedSync false initially', () async {
      await _openSettingsBox();
      final svc = await _make();
      expect(svc.getMonthlyQuizCompletedSync(2025, 6), isFalse);
    });

    test('getMonthlyQuizCompletionRateSync 0.0 initially', () async {
      await _openSettingsBox();
      final svc = await _make();
      expect(svc.getMonthlyQuizCompletionRateSync(2025, 6), 0.0);
    });

    test('markMonthlyQuizProgress sets completed when full', () async {
      await _openSettingsBox();
      final svc = await _make();
      await svc.markMonthlyQuizProgress(
          year: 2025, month: 6, questionsCompleted: 10, totalQuestions: 10);
      expect(svc.getMonthlyQuizCompletedSync(2025, 6), isTrue);
    });

    test('markMonthlyQuizProgress sets rate correctly', () async {
      await _openSettingsBox();
      final svc = await _make();
      await svc.markMonthlyQuizProgress(
          year: 2025, month: 6, questionsCompleted: 5, totalQuestions: 10);
      expect(svc.getMonthlyQuizCompletionRateSync(2025, 6), closeTo(0.5, 0.001));
    });

    test('markMonthlyQuizProgress not completed when partial', () async {
      await _openSettingsBox();
      final svc = await _make();
      await svc.markMonthlyQuizProgress(
          year: 2025, month: 6, questionsCompleted: 3, totalQuestions: 10);
      expect(svc.getMonthlyQuizCompletedSync(2025, 6), isFalse);
    });

    test('months are tracked independently', () async {
      await _openSettingsBox();
      final svc = await _make();
      await svc.markMonthlyQuizProgress(
          year: 2025, month: 6, questionsCompleted: 10, totalQuestions: 10);
      expect(svc.getMonthlyQuizCompletedSync(2025, 7), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // isFeaturedChallengeUnlocked
  // -------------------------------------------------------------------------

  group('isFeaturedChallengeUnlocked', () {
    test('unlocked when total_quizzes >= 3', () async {
      await _openSettingsBox();
      final svc = await _make();
      await svc.savePlayerProgress({'total_quizzes': 3});
      expect(svc.isFeaturedChallengeUnlocked(), isTrue);
    });

    test('locked when total_quizzes < 3', () async {
      await _openSettingsBox();
      final svc = await _make();
      await svc.savePlayerProgress({'total_quizzes': 2});
      expect(svc.isFeaturedChallengeUnlocked(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // getQuizStats
  // -------------------------------------------------------------------------

  group('getQuizStats', () {
    test('returns map with expected keys', () async {
      await _openSettingsBox();
      final svc = await _make();
      final stats = svc.getQuizStats();
      expect(stats.containsKey('totalQuizzes'), isTrue);
      expect(stats.containsKey('totalQuestions'), isTrue);
      expect(stats.containsKey('correctAnswers'), isTrue);
      expect(stats.containsKey('currentStreak'), isTrue);
      expect(stats.containsKey('bestStreak'), isTrue);
      expect(stats.containsKey('averageScore'), isTrue);
    });

    test('averageScore is 0 when no questions answered', () async {
      await _openSettingsBox();
      final svc = await _make();
      final stats = svc.getQuizStats();
      expect(stats['averageScore'], 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // updateQuizCompletion
  // -------------------------------------------------------------------------

  group('updateQuizCompletion', () {
    test('increments total_quizzes', () async {
      final svc = await _make();
      await svc.updateQuizCompletion(
          questionsTotal: 5,
          questionsCorrect: 3,
          category: 'science',
          completionTime: 30.0);
      final progress = await svc.getPlayerProgress();
      expect(progress['total_quizzes'], 1);
    });

    test('increments total_questions', () async {
      final svc = await _make();
      await svc.updateQuizCompletion(
          questionsTotal: 5,
          questionsCorrect: 5,
          category: 'history',
          completionTime: 20.0);
      final progress = await svc.getPlayerProgress();
      expect(progress['total_questions'], 5);
    });

    test('increments correct_answers', () async {
      final svc = await _make();
      await svc.updateQuizCompletion(
          questionsTotal: 5,
          questionsCorrect: 4,
          category: 'history',
          completionTime: 20.0);
      final progress = await svc.getPlayerProgress();
      expect(progress['correct_answers'], 4);
    });

    test('increments current_streak on perfect score', () async {
      final svc = await _make();
      await svc.updateQuizCompletion(
          questionsTotal: 5,
          questionsCorrect: 5,
          category: 'science',
          completionTime: 20.0);
      final progress = await svc.getPlayerProgress();
      expect(progress['current_streak'], 1);
    });

    test('resets current_streak on imperfect score', () async {
      final svc = await _make();
      await svc.savePlayerProgress({'current_streak': 5});
      await svc.updateQuizCompletion(
          questionsTotal: 5,
          questionsCorrect: 3,
          category: 'science',
          completionTime: 20.0);
      final progress = await svc.getPlayerProgress();
      expect(progress['current_streak'], 0);
    });

    test('tracks category_stats', () async {
      final svc = await _make();
      await svc.updateQuizCompletion(
          questionsTotal: 5,
          questionsCorrect: 4,
          category: 'Science',
          completionTime: 15.0);
      final progress = await svc.getPlayerProgress();
      final catStats = progress['category_stats'];
      expect(catStats['science']['total_quizzes'], 1);
      expect(catStats['science']['total_questions'], 5);
    });
  });

  // -------------------------------------------------------------------------
  // getRecentQuizzes / saveCompletedQuiz
  // -------------------------------------------------------------------------

  group('getRecentQuizzes / saveCompletedQuiz', () {
    test('getRecentQuizzes returns default list when nothing stored', () async {
      await _openSettingsBox();
      final svc = await _make();
      final quizzes = svc.getRecentQuizzes();
      expect(quizzes, isNotEmpty);
      expect(quizzes.first.containsKey('title'), isTrue);
    });

    test('saveCompletedQuiz adds to front', () async {
      await _openSettingsBox();
      final svc = await _make();
      // Save one first to populate
      await svc.saveCompletedQuiz(
          title: 'My Quiz', score: '90%', category: 'math');
      final quizzes = svc.getRecentQuizzes();
      expect(quizzes.first['title'], 'My Quiz');
    });

    test('saveCompletedQuiz caps at 10 entries', () async {
      await _openSettingsBox();
      final svc = await _make();
      for (int i = 0; i < 12; i++) {
        await svc.saveCompletedQuiz(
            title: 'Quiz $i', score: '80%', category: 'cat');
      }
      final quizzes = svc.getRecentQuizzes();
      expect(quizzes.length, 10);
    });
  });
}
