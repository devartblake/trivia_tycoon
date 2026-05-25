import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/game/services/educational_stats_service.dart';
import 'package:trivia_tycoon/game/providers/quiz_results_provider.dart';

QuizResults _makeResult({
  int score = 8,
  int totalQuestions = 10,
  String category = 'Science',
  String classLevel = '5',
  int totalXP = 100,
  int coins = 0,
  int diamonds = 0,
  int stars = 0,
  Duration quizDuration = const Duration(minutes: 3),
}) =>
    QuizResults(
      score: score,
      totalQuestions: totalQuestions,
      category: category,
      classLevel: classLevel,
      totalXP: totalXP,
      coins: coins,
      diamonds: diamonds,
      stars: stars,
      categoryScores: const {},
      achievements: const [],
      quizDuration: quizDuration,
    );

void main() {
  late Directory tempDir;
  late EducationalStatsService svc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('educational_stats_test_');
    Hive.init(tempDir.path);
    svc = EducationalStatsService();
    await svc.initialize();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // EducationalStats data class
  // ---------------------------------------------------------------------------

  group('EducationalStats data class defaults', () {
    test('totalQuizzes is 0', () {
      expect(EducationalStats().totalQuizzes, 0);
    });

    test('correctAnswers is 0', () {
      expect(EducationalStats().correctAnswers, 0);
    });

    test('averageScore is 0.0', () {
      expect(EducationalStats().averageScore, 0.0);
    });

    test('currentStreak is 0', () {
      expect(EducationalStats().currentStreak, 0);
    });

    test('maxStreak is 0', () {
      expect(EducationalStats().maxStreak, 0);
    });

    test('subjectStats is empty', () {
      expect(EducationalStats().subjectStats, isEmpty);
    });

    test('recentQuizzes is empty', () {
      expect(EducationalStats().recentQuizzes, isEmpty);
    });

    test('lastQuizDate is null', () {
      expect(EducationalStats().lastQuizDate, isNull);
    });
  });

  group('EducationalStats copyWith', () {
    test('totalQuizzes updated', () {
      expect(EducationalStats().copyWith(totalQuizzes: 5).totalQuizzes, 5);
    });

    test('averageScore updated', () {
      expect(
          EducationalStats().copyWith(averageScore: 75.5).averageScore, 75.5);
    });

    test('currentStreak updated', () {
      expect(EducationalStats().copyWith(currentStreak: 3).currentStreak, 3);
    });

    test('maxStreak updated', () {
      expect(EducationalStats().copyWith(maxStreak: 7).maxStreak, 7);
    });

    test('preserves unchanged fields', () {
      final s = EducationalStats(totalQuizzes: 10, currentStreak: 3);
      expect(s.copyWith(maxStreak: 5).totalQuizzes, 10);
      expect(s.copyWith(maxStreak: 5).currentStreak, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // SubjectStats data class
  // ---------------------------------------------------------------------------

  group('SubjectStats data class', () {
    test('requires subject field', () {
      final ss = SubjectStats(subject: 'Math');
      expect(ss.subject, 'Math');
    });

    test('defaults: quizzesCompleted is 0', () {
      expect(SubjectStats(subject: 'Math').quizzesCompleted, 0);
    });

    test('defaults: averageScore is 0.0', () {
      expect(SubjectStats(subject: 'Math').averageScore, 0.0);
    });

    test('defaults: masteryLevel is 1', () {
      expect(SubjectStats(subject: 'Math').masteryLevel, 1);
    });

    test('defaults: lastQuizDate is null', () {
      expect(SubjectStats(subject: 'Math').lastQuizDate, isNull);
    });

    test('copyWith subject updated', () {
      final ss = SubjectStats(subject: 'History');
      expect(ss.copyWith(subject: 'Art').subject, 'Art');
    });

    test('copyWith quizzesCompleted updated', () {
      final ss = SubjectStats(subject: 'Science');
      expect(ss.copyWith(quizzesCompleted: 10).quizzesCompleted, 10);
    });

    test('copyWith masteryLevel updated', () {
      final ss = SubjectStats(subject: 'Science');
      expect(ss.copyWith(masteryLevel: 3).masteryLevel, 3);
    });

    test('copyWith preserves unchanged fields', () {
      final ss = SubjectStats(
          subject: 'Geography', quizzesCompleted: 5, masteryLevel: 2);
      final updated = ss.copyWith(averageScore: 80.0);
      expect(updated.subject, 'Geography');
      expect(updated.quizzesCompleted, 5);
      expect(updated.masteryLevel, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // EducationalStatsService — empty state
  // ---------------------------------------------------------------------------

  group('getEducationalStats — empty state', () {
    test('totalQuizzes is 0 before any records', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.totalQuizzes, 0);
    });

    test('correctAnswers is 0 before any records', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.correctAnswers, 0);
    });

    test('averageScore is 0.0 before any records', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.averageScore, 0.0);
    });

    test('currentStreak is 0 before any records', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.currentStreak, 0);
    });

    test('subjectStats is empty before any records', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.subjectStats, isEmpty);
    });

    test('recentQuizzes is empty before any records', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.recentQuizzes, isEmpty);
    });

    test('lastQuizDate is null before any records', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.lastQuizDate, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // EducationalStatsService — after one recordQuizResult
  // ---------------------------------------------------------------------------

  group('getEducationalStats — after one record', () {
    setUp(() async {
      await svc.recordQuizResult(_makeResult(score: 8, totalQuestions: 10));
    });

    test('totalQuizzes is 1', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.totalQuizzes, 1);
    });

    test('correctAnswers equals score', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.correctAnswers, 8);
    });

    test('averageScore calculated: 8/10 * 100 = 80.0', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.averageScore, closeTo(80.0, 0.01));
    });

    test('currentStreak is 1 (first quiz)', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.currentStreak, 1);
    });

    test('maxStreak is 1 (first quiz)', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.maxStreak, 1);
    });

    test('lastQuizDate is not null', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.lastQuizDate, isNotNull);
    });

    test('recentQuizzes has 1 entry', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.recentQuizzes.length, 1);
    });

    test('recentQuizzes entry has correct score', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.recentQuizzes.first.score, 8);
    });
  });

  // ---------------------------------------------------------------------------
  // EducationalStatsService — multiple records
  // ---------------------------------------------------------------------------

  group('getEducationalStats — multiple records', () {
    setUp(() async {
      await svc.recordQuizResult(
          _makeResult(score: 7, totalQuestions: 10, category: 'Science'));
      await svc.recordQuizResult(
          _makeResult(score: 9, totalQuestions: 10, category: 'Science'));
      await svc.recordQuizResult(
          _makeResult(score: 5, totalQuestions: 10, category: 'History'));
    });

    test('totalQuizzes is 3', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.totalQuizzes, 3);
    });

    test('correctAnswers sums all scores', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.correctAnswers, 21); // 7 + 9 + 5
    });

    test('averageScore: 21/30 * 100 ≈ 70.0', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.averageScore, closeTo(70.0, 0.01));
    });

    test('subjectStats contains Science', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.subjectStats.containsKey('Science'), isTrue);
    });

    test('subjectStats contains History', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.subjectStats.containsKey('History'), isTrue);
    });

    test('Science quizzesCompleted is 2', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.subjectStats['Science']!.quizzesCompleted, 2);
    });

    test('History quizzesCompleted is 1', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.subjectStats['History']!.quizzesCompleted, 1);
    });

    test('recentQuizzes has up to 10 entries', () async {
      final stats = await svc.getEducationalStats();
      expect(stats.recentQuizzes.length, lessThanOrEqualTo(10));
    });
  });

  // ---------------------------------------------------------------------------
  // Streak tracking
  // ---------------------------------------------------------------------------

  group('streak tracking', () {
    test('streak is 1 after first quiz', () async {
      await svc.recordQuizResult(_makeResult());
      final stats = await svc.getEducationalStats();
      expect(stats.currentStreak, 1);
      expect(stats.maxStreak, 1);
    });

    test('streak same day: stays at 1 after second quiz same day', () async {
      await svc.recordQuizResult(_makeResult());
      await svc.recordQuizResult(_makeResult());
      final stats = await svc.getEducationalStats();
      // Same day → streak doesn't increment beyond 1
      expect(stats.currentStreak, 1);
    });

    test('maxStreak updated when streak grows', () async {
      await svc.recordQuizResult(_makeResult());
      final stats = await svc.getEducationalStats();
      expect(stats.maxStreak, greaterThanOrEqualTo(stats.currentStreak));
    });
  });

  // ---------------------------------------------------------------------------
  // Subject stats details
  // ---------------------------------------------------------------------------

  group('subject stats', () {
    test('totalQuestions accumulated per subject', () async {
      await svc.recordQuizResult(
          _makeResult(score: 8, totalQuestions: 10, category: 'Math'));
      await svc.recordQuizResult(
          _makeResult(score: 6, totalQuestions: 10, category: 'Math'));
      final stats = await svc.getEducationalStats();
      final mathStats = stats.subjectStats['Math']!;
      expect(mathStats.totalQuestions, 20);
    });

    test('correctAnswers accumulated per subject', () async {
      await svc.recordQuizResult(
          _makeResult(score: 9, totalQuestions: 10, category: 'Literature'));
      await svc.recordQuizResult(
          _makeResult(score: 7, totalQuestions: 10, category: 'Literature'));
      final stats = await svc.getEducationalStats();
      final litStats = stats.subjectStats['Literature']!;
      expect(litStats.correctAnswers, 16); // 9 + 7
    });

    test('averageScore calculated for subject', () async {
      await svc.recordQuizResult(
          _makeResult(score: 10, totalQuestions: 10, category: 'Geography'));
      final stats = await svc.getEducationalStats();
      final geoStats = stats.subjectStats['Geography']!;
      expect(geoStats.averageScore, closeTo(100.0, 0.01));
    });

    test('masteryLevel is 1 for fewer than 5 quizzes', () async {
      await svc.recordQuizResult(
          _makeResult(score: 10, totalQuestions: 10, category: 'Technology'));
      final stats = await svc.getEducationalStats();
      expect(stats.subjectStats['Technology']!.masteryLevel, 1);
    });

    test('lastQuizDate is set after recording', () async {
      await svc.recordQuizResult(_makeResult(category: 'Health'));
      final stats = await svc.getEducationalStats();
      expect(stats.subjectStats['Health']!.lastQuizDate, isNotNull);
    });

    test('subject field matches category', () async {
      await svc.recordQuizResult(_makeResult(category: 'Arts'));
      final stats = await svc.getEducationalStats();
      expect(stats.subjectStats['Arts']!.subject, 'Arts');
    });
  });

  // ---------------------------------------------------------------------------
  // EducationalStatsService — cap at 100 quizzes
  // ---------------------------------------------------------------------------

  group('history cap at 100', () {
    test('stores at most 100 quiz history entries', () async {
      for (int i = 0; i < 105; i++) {
        await svc.recordQuizResult(_makeResult(score: i % 10));
      }
      final stats = await svc.getEducationalStats();
      expect(stats.totalQuizzes, 100);
    });
  });

  // ---------------------------------------------------------------------------
  // getWeeklyActivity
  // ---------------------------------------------------------------------------

  group('getWeeklyActivity', () {
    test('returns 7 entries', () async {
      final activity = await svc.getWeeklyActivity();
      expect(activity.length, 7);
    });

    test('each entry has day/quizzes/score keys', () async {
      final activity = await svc.getWeeklyActivity();
      for (final day in activity) {
        expect(day.containsKey('day'), isTrue);
        expect(day.containsKey('quizzes'), isTrue);
        expect(day.containsKey('score'), isTrue);
      }
    });

    test('day names are valid abbreviations', () async {
      final activity = await svc.getWeeklyActivity();
      final validDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'};
      for (final day in activity) {
        expect(validDays.contains(day['day']), isTrue,
            reason: 'Day "${day['day']}" is not a valid abbreviation');
      }
    });

    test('quizzes is 0 before any records', () async {
      final activity = await svc.getWeeklyActivity();
      final totalQuizzes =
          activity.fold<int>(0, (sum, d) => sum + (d['quizzes'] as int));
      expect(totalQuizzes, 0);
    });

    test('today has 1 quiz after recording', () async {
      await svc.recordQuizResult(_makeResult());
      final activity = await svc.getWeeklyActivity();
      final totalQuizzes =
          activity.fold<int>(0, (sum, d) => sum + (d['quizzes'] as int));
      expect(totalQuizzes, 1);
    });

    test('score is numeric', () async {
      await svc.recordQuizResult(_makeResult(score: 8, totalQuestions: 10));
      final activity = await svc.getWeeklyActivity();
      for (final day in activity) {
        expect(day['score'], isA<num>());
      }
    });
  });

  // ---------------------------------------------------------------------------
  // initialize is idempotent
  // ---------------------------------------------------------------------------

  group('initialize', () {
    test('can call initialize multiple times without error', () async {
      await expectLater(svc.initialize(), completes);
      await expectLater(svc.initialize(), completes);
    });
  });
}
