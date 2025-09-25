import 'package:flutter_riverpod/flutter_riverpod.dart';

// Updated QuizResults class with safe constructors
class QuizResults {
  final int score;
  final int totalQuestions;
  final int totalXP;
  final int coins;
  final int diamonds;
  final int stars;
  final String classLevel;
  final String category;
  final Map<String, int> categoryScores;
  final List<String> achievements;
  final Duration quizDuration;

  QuizResults({
    required this.score,
    required this.totalQuestions,
    required this.totalXP,
    required this.coins,
    required this.diamonds,
    required this.stars,
    required this.classLevel,
    required this.category,
    required this.categoryScores,
    required this.achievements,
    required this.quizDuration,
  });

  // Safe factory constructor for Hive data
  factory QuizResults.fromHiveData(Map<dynamic, dynamic> data) {
    return QuizResults(
      score: (data['score'] as num? ?? 0).toInt(),
      totalQuestions: (data['totalQuestions'] as num? ?? 0).toInt(),
      totalXP: (data['totalXP'] as num? ?? 0).toInt(),
      coins: (data['coins'] as num? ?? 0).toInt(),
      diamonds: (data['diamonds'] as num? ?? 0).toInt(),
      stars: (data['stars'] as num? ?? 0).toInt(),
      classLevel: data['classLevel'] as String? ?? '1',
      category: data['category'] as String? ?? 'Mixed',
      categoryScores: _safeCastIntMap(data['categoryScores']),
      achievements: _safeCastStringList(data['achievements']),
      quizDuration: Duration(
        milliseconds: (data['quizDurationMs'] as num? ?? 300000).toInt(),
      ),
    );
  }

  // Safe factory constructor for JSON data
  factory QuizResults.fromJson(Map<String, dynamic> json) {
    return QuizResults(
      score: (json['score'] as num? ?? 0).toInt(),
      totalQuestions: (json['totalQuestions'] as num? ?? 0).toInt(),
      totalXP: (json['totalXP'] as num? ?? 0).toInt(),
      coins: (json['coins'] as num? ?? 0).toInt(),
      diamonds: (json['diamonds'] as num? ?? 0).toInt(),
      stars: (json['stars'] as num? ?? 0).toInt(),
      classLevel: json['classLevel'] as String? ?? '1',
      category: json['category'] as String? ?? 'Mixed',
      categoryScores: _safeCastIntMap(json['categoryScores']),
      achievements: _safeCastStringList(json['achievements']),
      quizDuration: Duration(
        milliseconds: (json['quizDurationMs'] as num? ?? 300000).toInt(),
      ),
    );
  }

  // Safe casting helper methods
  static Map<String, int> _safeCastIntMap(dynamic data) {
    if (data == null) return <String, int>{};

    if (data is Map<String, int>) return data;

    if (data is Map) {
      final result = <String, int>{};
      data.forEach((key, value) {
        if (key != null && value != null) {
          result[key.toString()] = (value as num? ?? 0).toInt();
        }
      });
      return result;
    }

    return <String, int>{};
  }

  static List<String> _safeCastStringList(dynamic data) {
    if (data == null) return <String>[];

    if (data is List<String>) return data;

    if (data is List) {
      return data
          .where((item) => item != null)
          .map((item) => item.toString())
          .toList();
    }

    return <String>[];
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'totalQuestions': totalQuestions,
      'totalXP': totalXP,
      'coins': coins,
      'diamonds': diamonds,
      'stars': stars,
      'classLevel': classLevel,
      'category': category,
      'categoryScores': categoryScores,
      'achievements': achievements,
      'quizDurationMs': quizDuration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

final quizResultsProvider = StateProvider<QuizResults?>((ref) => null);
