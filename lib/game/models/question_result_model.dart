import 'question_difficulty.dart';

/// Model for persisting question result data for analytics and progression
class QuestionResultModel {
  final String questionId;
  final String category;
  final QuestionDifficulty difficulty;
  final bool isCorrect;
  final int timeTakenSeconds;
  final int xpEarned;
  final int coinsEarned;
  final int streakCountAtAnswer;
  final DateTime answeredAt;

  QuestionResultModel({
    required this.questionId,
    required this.category,
    required this.difficulty,
    required this.isCorrect,
    required this.timeTakenSeconds,
    required this.xpEarned,
    required this.coinsEarned,
    this.streakCountAtAnswer = 0,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'category': category,
      'difficulty': difficulty.value,
      'isCorrect': isCorrect,
      'timeTakenSeconds': timeTakenSeconds,
      'xpEarned': xpEarned,
      'coinsEarned': coinsEarned,
      'streakCountAtAnswer': streakCountAtAnswer,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory QuestionResultModel.fromJson(Map<String, dynamic> json) {
    return QuestionResultModel(
      questionId: json['questionId'] as String,
      category: json['category'] as String,
      difficulty: QuestionDifficultyExtension.parse(json['difficulty']),
      isCorrect: json['isCorrect'] as bool,
      timeTakenSeconds: json['timeTakenSeconds'] as int,
      xpEarned: json['xpEarned'] as int,
      coinsEarned: json['coinsEarned'] as int,
      streakCountAtAnswer: json['streakCountAtAnswer'] as int? ?? 0,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
    );
  }

  /// Create a copy with optional modifications
  QuestionResultModel copyWith({
    String? questionId,
    String? category,
    QuestionDifficulty? difficulty,
    bool? isCorrect,
    int? timeTakenSeconds,
    int? xpEarned,
    int? coinsEarned,
    int? streakCountAtAnswer,
    DateTime? answeredAt,
  }) {
    return QuestionResultModel(
      questionId: questionId ?? this.questionId,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      isCorrect: isCorrect ?? this.isCorrect,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      xpEarned: xpEarned ?? this.xpEarned,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      streakCountAtAnswer: streakCountAtAnswer ?? this.streakCountAtAnswer,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  @override
  String toString() =>
      'QuestionResultModel(id: $questionId, correct: $isCorrect, xp: $xpEarned, coins: $coinsEarned)';
}
