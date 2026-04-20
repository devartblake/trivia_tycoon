import 'package:flutter/foundation.dart';
import '../models/question_model.dart';

@immutable
class QuestionState {
  final List<QuestionModel> questions;
  final int currentIndex;
  final int timeLeft;
  final String? selectedAnswer;
  final int score;
  final int money;
  final int diamonds;
  final bool powerUpUsed;

  /// In-session streak / accuracy tracking (used by skill effects).
  final int streakCount; // consecutive correct answers this game
  final int correctCount; // total correct answers (for accuracyBonus)
  final int totalAnswered; // total questions answered  (for accuracyBonus)

  const QuestionState({
    this.questions = const [],
    this.currentIndex = 0,
    this.timeLeft = 30,
    this.selectedAnswer,
    this.score = 0,
    this.money = 0,
    this.diamonds = 0,
    this.powerUpUsed = false,
    this.streakCount = 0,
    this.correctCount = 0,
    this.totalAnswered = 0,
  });

  QuestionModel? get currentQuestion =>
      (questions.isNotEmpty && currentIndex < questions.length)
          ? questions[currentIndex]
          : null;

  bool get isQuizOver => currentIndex >= questions.length;

  double get accuracy => totalAnswered > 0 ? correctCount / totalAnswered : 0.0;

  QuestionState copyWith({
    List<QuestionModel>? questions,
    int? currentIndex,
    int? timeLeft,
    String? selectedAnswer,
    int? score,
    int? money,
    int? diamonds,
    bool? powerUpUsed,
    int? streakCount,
    int? correctCount,
    int? totalAnswered,
  }) {
    return QuestionState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      timeLeft: timeLeft ?? this.timeLeft,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      score: score ?? this.score,
      money: money ?? this.money,
      diamonds: diamonds ?? this.diamonds,
      powerUpUsed: powerUpUsed ?? this.powerUpUsed,
      streakCount: streakCount ?? this.streakCount,
      correctCount: correctCount ?? this.correctCount,
      totalAnswered: totalAnswered ?? this.totalAnswered,
    );
  }

  factory QuestionState.initial() => const QuestionState();
}
