import '../../game/models/question_model.dart';

class QuestionAnswerSubmission {
  const QuestionAnswerSubmission({
    required this.question,
    required this.selectedAnswer,
    this.answerTimeMs,
  });

  final QuestionModel question;
  final String selectedAnswer;
  final int? answerTimeMs;
}

class QuestionAnswerCheckResult {
  const QuestionAnswerCheckResult({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    this.correctAnswer,
    this.source = 'backend',
    this.metadata = const <String, dynamic>{},
  });

  final String questionId;
  final String selectedAnswer;
  final bool isCorrect;
  final String? correctAnswer;
  final String source;
  final Map<String, dynamic> metadata;
}

/// Server-authoritative XP awarded for a graded quiz session.
/// Mirrors the backend's QuizXpAwardDto on POST /questions/check-batch.
class QuizXpAward {
  const QuizXpAward({
    required this.xpAwarded,
    required this.totalXp,
    required this.tierUpgraded,
    this.newTierId,
    this.seasonPointsAwarded = 0,
  });

  final double xpAwarded;
  final double totalXp;
  final bool tierUpgraded;
  final String? newTierId;

  /// Season rank points earned by this quiz session (server-capped per day).
  final int seasonPointsAwarded;

  static QuizXpAward? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    return QuizXpAward(
      xpAwarded: (map['xpAwarded'] as num?)?.toDouble() ?? 0,
      totalXp: (map['totalXp'] as num?)?.toDouble() ?? 0,
      tierUpgraded: (map['tierUpgraded'] as bool?) ?? false,
      newTierId: map['newTierId']?.toString(),
      seasonPointsAwarded: (map['seasonPointsAwarded'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Result of a batch answer check: per-question grading plus, when the
/// backend awarded quiz XP server-side, the authoritative award summary.
class QuestionBatchCheckOutcome {
  const QuestionBatchCheckOutcome({
    required this.results,
    this.xpAward,
  });

  final List<QuestionAnswerCheckResult> results;
  final QuizXpAward? xpAward;
}
