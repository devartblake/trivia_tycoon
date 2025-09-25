import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../providers/quiz_results_provider.dart';
import '../providers/xp_provider.dart';
import '../controllers/achievement_controller.dart';
import '../services/profile_service.dart';

// Educational Statistics Model
class EducationalStats {
  final int totalQuizzes;
  final int correctAnswers;
  final double averageScore;
  final int currentStreak;
  final int maxStreak;
  final Map<String, SubjectStats> subjectStats;
  final List<QuizResults> recentQuizzes;
  final DateTime? lastQuizDate;

  EducationalStats({
    this.totalQuizzes = 0,
    this.correctAnswers = 0,
    this.averageScore = 0.0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.subjectStats = const {},
    this.recentQuizzes = const [],
    this.lastQuizDate,
  });

  EducationalStats copyWith({
    int? totalQuizzes,
    int? correctAnswers,
    double? averageScore,
    int? currentStreak,
    int? maxStreak,
    Map<String, SubjectStats>? subjectStats,
    List<QuizResults>? recentQuizzes,
    DateTime? lastQuizDate,
  }) {
    return EducationalStats(
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      averageScore: averageScore ?? this.averageScore,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      subjectStats: subjectStats ?? this.subjectStats,
      recentQuizzes: recentQuizzes ?? this.recentQuizzes,
      lastQuizDate: lastQuizDate ?? this.lastQuizDate,
    );
  }
}

// Subject-specific statistics
class SubjectStats {
  final String subject;
  final int quizzesCompleted;
  final double averageScore;
  final int totalQuestions;
  final int correctAnswers;
  final int masteryLevel; // 1-5 stars
  final DateTime? lastQuizDate;

  SubjectStats({
    required this.subject,
    this.quizzesCompleted = 0,
    this.averageScore = 0.0,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.masteryLevel = 1,
    this.lastQuizDate,
  });

  SubjectStats copyWith({
    String? subject,
    int? quizzesCompleted,
    double? averageScore,
    int? totalQuestions,
    int? correctAnswers,
    int? masteryLevel,
    DateTime? lastQuizDate,
  }) {
    return SubjectStats(
      subject: subject ?? this.subject,
      quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
      averageScore: averageScore ?? this.averageScore,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      lastQuizDate: lastQuizDate ?? this.lastQuizDate,
    );
  }
}

// Educational Statistics Service
class EducationalStatsService {
  static const String _statsBoxName = 'educational_stats';
  static const String _quizHistoryKey = 'quiz_history';
  static const String _streakDataKey = 'streak_data';
  static const String _subjectStatsKey = 'subject_stats';

  // Safe type casting utilities for Hive
  static Map<String, dynamic> _safeCastMap(dynamic data) {
    if (data == null) return <String, dynamic>{};

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _safeCastMapList(dynamic data) {
    if (data == null) return <Map<String, dynamic>>[];

    if (data is List<Map<String, dynamic>>) {
      return data;
    }

    if (data is List) {
      return data
          .where((item) => item is Map)
          .map((item) => _safeCastMap(item))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  Future<void> initialize() async {
    try {
      await Hive.openBox(_statsBoxName);
    } catch (e) {
      debugPrint('Failed to initialize EducationalStatsService: $e');
    }
  }

  Future<void> recordQuizResult(QuizResults result) async {
    try {
      final box = await Hive.openBox(_statsBoxName);

      // Get existing quiz history with safe casting
      final dynamic historyData = box.get(_quizHistoryKey, defaultValue: []);
      final List<Map<String, dynamic>> quizHistory = _safeCastMapList(historyData);

      // Add new result with explicit typing
      final Map<String, dynamic> resultData = {
        'score': result.score,
        'totalQuestions': result.totalQuestions,
        'category': result.category,
        'classLevel': result.classLevel,
        'date': DateTime.now().toIso8601String(),
        'duration': result.quizDuration.inSeconds,
        'xpEarned': result.totalXP,
      };

      quizHistory.add(resultData);

      // Keep only last 100 quizzes
      if (quizHistory.length > 100) {
        quizHistory.removeAt(0);
      }

      await box.put(_quizHistoryKey, quizHistory);

      // Update streak
      await _updateStreak(result);

      // Update subject stats
      await _updateSubjectStats(result);

      debugPrint('Quiz completion processed successfully');

    } catch (e) {
      debugPrint('Failed to record quiz result: $e');
    }
  }

  Future<EducationalStats> getEducationalStats() async {
    try {
      final box = await Hive.openBox(_statsBoxName);

      // Get quiz history with safe casting
      final dynamic historyData = box.get(_quizHistoryKey, defaultValue: []);
      final List<Map<String, dynamic>> quizHistory = _safeCastMapList(historyData);

      // Calculate overall stats
      int totalQuizzes = quizHistory.length;
      int totalCorrect = 0;
      int totalQuestions = 0;

      for (final quiz in quizHistory) {
        totalCorrect += (quiz['score'] as num? ?? 0).toInt();
        totalQuestions += (quiz['totalQuestions'] as num? ?? 0).toInt();
      }

      double averageScore = totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;

      // Get streak data with safe casting
      final dynamic streakRaw = box.get(_streakDataKey, defaultValue: {'current': 0, 'max': 0});
      final Map<String, dynamic> streakData = _safeCastMap(streakRaw);
      int currentStreak = (streakData['current'] as num? ?? 0).toInt();
      int maxStreak = (streakData['max'] as num? ?? 0).toInt();

      // Get subject stats
      final Map<String, SubjectStats> subjectStats = await _getSubjectStats();

      // Get recent quizzes (convert to QuizResults objects)
      final recentQuizzes = quizHistory.take(10).map((data) {
        return QuizResults(
          score: (data['score'] as num? ?? 0).toInt(),
          totalQuestions: (data['totalQuestions'] as num? ?? 0).toInt(),
          category: data['category'] as String? ?? 'Mixed',
          classLevel: data['classLevel'] as String? ?? '1',
          totalXP: (data['xpEarned'] as num? ?? 0).toInt(),
          quizDuration: Duration(seconds: (data['duration'] as num? ?? 300).toInt()),
          // Add default values for other required fields
          coins: 0,
          diamonds: 0,
          stars: 0,
          categoryScores: <String, int>{},
          achievements: <String>[],
        );
      }).toList();

      DateTime? lastQuizDate;
      if (quizHistory.isNotEmpty) {
        final lastQuizData = quizHistory.last;
        lastQuizDate = DateTime.tryParse(lastQuizData['date'] as String? ?? '');
      }

      debugPrint('Educational data updated successfully for quiz completion');

      return EducationalStats(
        totalQuizzes: totalQuizzes,
        correctAnswers: totalCorrect,
        averageScore: averageScore,
        currentStreak: currentStreak,
        maxStreak: maxStreak,
        subjectStats: subjectStats,
        recentQuizzes: recentQuizzes,
        lastQuizDate: lastQuizDate,
      );

    } catch (e) {
      debugPrint('Failed to get educational stats: $e');
      return EducationalStats();
    }
  }

  Future<void> _updateStreak(QuizResults result) async {
    try {
      final box = await Hive.openBox(_statsBoxName);
      final dynamic streakRaw = box.get(_streakDataKey, defaultValue: {'current': 0, 'max': 0, 'lastDate': ''});
      final Map<String, dynamic> streakData = _safeCastMap(streakRaw);

      final today = DateTime.now();
      final lastDateStr = streakData['lastDate'] as String? ?? '';

      DateTime? lastDate;
      if (lastDateStr.isNotEmpty) {
        lastDate = DateTime.tryParse(lastDateStr);
      }

      int currentStreak = (streakData['current'] as num? ?? 0).toInt();
      int maxStreak = (streakData['max'] as num? ?? 0).toInt();

      if (lastDate == null) {
        // First quiz ever
        currentStreak = 1;
      } else {
        final daysDifference = today.difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;

        if (daysDifference == 0) {
          // Same day, streak continues
        } else if (daysDifference == 1) {
          // Consecutive day, increment streak
          currentStreak++;
        } else {
          // Streak broken, reset
          currentStreak = 1;
        }
      }

      // Update max streak
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }

      final Map<String, dynamic> updatedStreakData = {
        'current': currentStreak,
        'max': maxStreak,
        'lastDate': DateTime(today.year, today.month, today.day).toIso8601String(),
      };

      await box.put(_streakDataKey, updatedStreakData);

    } catch (e) {
      debugPrint('Failed to update streak: $e');
    }
  }

  Future<void> _updateSubjectStats(QuizResults result) async {
    try {
      final box = await Hive.openBox(_statsBoxName);
      final dynamic allSubjectRaw = box.get(_subjectStatsKey, defaultValue: {});
      final Map<String, dynamic> allSubjectData = _safeCastMap(allSubjectRaw);

      final String subject = result.category;
      final Map<String, dynamic> subjectData = _safeCastMap(allSubjectData[subject]);

      // Update stats
      int quizzesCompleted = (subjectData['quizzesCompleted'] as num? ?? 0).toInt() + 1;
      int totalQuestions = (subjectData['totalQuestions'] as num? ?? 0).toInt() + result.totalQuestions;
      int correctAnswers = (subjectData['correctAnswers'] as num? ?? 0).toInt() + result.score;
      double averageScore = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

      // Calculate mastery level (1-5 stars based on performance)
      int masteryLevel = 1;
      if (quizzesCompleted >= 5) {
        if (averageScore >= 95) masteryLevel = 5;
        else if (averageScore >= 85) masteryLevel = 4;
        else if (averageScore >= 75) masteryLevel = 3;
        else if (averageScore >= 65) masteryLevel = 2;
      }

      final Map<String, dynamic> updatedSubjectData = {
        'subject': subject,
        'quizzesCompleted': quizzesCompleted,
        'averageScore': averageScore,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'masteryLevel': masteryLevel,
        'lastQuizDate': DateTime.now().toIso8601String(),
      };

      allSubjectData[subject] = updatedSubjectData;
      await box.put(_subjectStatsKey, allSubjectData);

    } catch (e) {
      debugPrint('Failed to update subject stats: $e');
    }
  }

  Future<Map<String, SubjectStats>> _getSubjectStats() async {
    try {
      final box = await Hive.openBox(_statsBoxName);
      final dynamic allSubjectRaw = box.get(_subjectStatsKey, defaultValue: {});
      final Map<String, dynamic> allSubjectData = _safeCastMap(allSubjectRaw);

      final Map<String, SubjectStats> subjectStats = {};

      for (final entry in allSubjectData.entries) {
        final Map<String, dynamic> data = _safeCastMap(entry.value);
        subjectStats[entry.key] = SubjectStats(
          subject: data['subject'] as String? ?? entry.key,
          quizzesCompleted: (data['quizzesCompleted'] as num? ?? 0).toInt(),
          averageScore: (data['averageScore'] as num? ?? 0.0).toDouble(),
          totalQuestions: (data['totalQuestions'] as num? ?? 0).toInt(),
          correctAnswers: (data['correctAnswers'] as num? ?? 0).toInt(),
          masteryLevel: (data['masteryLevel'] as num? ?? 1).toInt(),
          lastQuizDate: data['lastQuizDate'] != null ? DateTime.tryParse(data['lastQuizDate']) : null,
        );
      }

      return subjectStats;
    } catch (e) {
      debugPrint('Failed to get subject stats: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivity() async {
    try {
      final box = await Hive.openBox(_statsBoxName);
      final dynamic historyData = box.get(_quizHistoryKey, defaultValue: []);
      final List<Map<String, dynamic>> quizHistory = _safeCastMapList(historyData);

      final now = DateTime.now();
      final List<Map<String, dynamic>> weeklyData = [];

      // Generate last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

        // Count quizzes for this day
        int quizCount = 0;
        double totalScore = 0;
        int totalQuestions = 0;

        for (final quiz in quizHistory) {
          final quizDate = DateTime.tryParse(quiz['date'] as String? ?? '');
          if (quizDate != null) {
            final quizDay = DateTime(quizDate.year, quizDate.month, quizDate.day);
            final targetDay = DateTime(date.year, date.month, date.day);

            if (quizDay.isAtSameMomentAs(targetDay)) {
              quizCount++;
              totalScore += (quiz['score'] as num? ?? 0).toDouble();
              totalQuestions += (quiz['totalQuestions'] as num? ?? 0).toInt();
            }
          }
        }

        final averageScore = totalQuestions > 0 ? (totalScore / totalQuestions) * 100 : 0;

        weeklyData.add({
          'day': dayName,
          'quizzes': quizCount,
          'score': averageScore.round(),
        });
      }

      return weeklyData;
    } catch (e) {
      debugPrint('Failed to get weekly activity: $e');
      return [];
    }
  }
}

// Providers
final educationalStatsServiceProvider = Provider<EducationalStatsService>((ref) {
  return EducationalStatsService();
});

final educationalStatsProvider = FutureProvider<EducationalStats>((ref) async {
  final service = ref.read(educationalStatsServiceProvider);
  return await service.getEducationalStats();
});

final weeklyActivityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(educationalStatsServiceProvider);
  return await service.getWeeklyActivity();
});

// Quiz completion notifier to update stats when quiz is completed
final quizCompletionNotifierProvider = Provider<QuizCompletionNotifier>((ref) {
  return QuizCompletionNotifier(ref);
});

class QuizCompletionNotifier {
  final Ref ref;

  QuizCompletionNotifier(this.ref);

  Future<void> onQuizCompleted(QuizResults result) async {
    try {
      // Record in educational stats
      final statsService = ref.read(educationalStatsServiceProvider);
      await statsService.recordQuizResult(result);

      // Update XP
      incrementXP(ref as WidgetRef, result.totalXP);

      // Check for achievements
      await _checkEducationalAchievements(result);

      // Refresh providers
      ref.invalidate(educationalStatsProvider);
      ref.invalidate(weeklyActivityProvider);

    } catch (e) {
      debugPrint('Failed to process quiz completion: $e');
    }
  }

  Future<void> _checkEducationalAchievements(QuizResults result) async {
    try {
      final stats = await ref.read(educationalStatsServiceProvider).getEducationalStats();
      final profileService = ref.read(profileServiceProvider);

      // Example achievement checks
      if (stats.totalQuizzes == 1) {
        // First quiz achievement
        debugPrint('Achievement unlocked: First Steps!');
      }

      if (stats.currentStreak == 7) {
        // Week streak achievement
        debugPrint('Achievement unlocked: Weekly Warrior!');
      }

      if (stats.totalQuizzes == 25 && result.category == 'Mathematics') {
        // Math wizard achievement
        debugPrint('Achievement unlocked: Math Wizard!');
      }

      // Perfect week check
      final weeklyData = await ref.read(educationalStatsServiceProvider).getWeeklyActivity();
      final thisWeekQuizzes = weeklyData.where((day) => day['quizzes'] > 0).toList();
      if (thisWeekQuizzes.length >= 7) {
        final allScores90Plus = thisWeekQuizzes.every((day) => day['score'] >= 90);
        if (allScores90Plus) {
          debugPrint('Achievement unlocked: Perfect Week!');
        }
      }

    } catch (e) {
      debugPrint('Failed to check achievements: $e');
    }
  }
}
