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

  const QuestionState({
    this.questions = const [],
    this.currentIndex = 0,
    this.timeLeft = 30,
    this.selectedAnswer,
    this.score = 0,
    this.money = 0,
    this.diamonds = 0,
    this.powerUpUsed = false,
  });

  QuestionModel? get currentQuestion =>
      (questions.isNotEmpty && currentIndex < questions.length)
          ? questions[currentIndex]
          : null;

  bool get isQuizOver => currentIndex >= questions.length;

  QuestionState copyWith({
    List<QuestionModel>? questions,
    int? currentIndex,
    int? timeLeft,
    String? selectedAnswer,
    int? score,
    int? money,
    int? diamonds,
    bool? powerUpUsed,
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
    );
  }

  // Inside question_state.dart
  factory QuestionState.initial() => QuestionState(
    questions: [],
    currentIndex: 0,
    selectedAnswer: null,
    score: 0,
    money: 0,
    diamonds: 0,
    powerUpUsed: false,
    timeLeft: 30,
  );

}
