import 'dart:async';
import 'dart:math';

import '../../domain/arcade_difficulty.dart';
import '../../domain/arcade_game_id.dart';
import '../../domain/arcade_result.dart';
import 'pattern_sprint_models.dart';

class PatternSprintState {
  final PatternSprintQuestion question;
  final int score;
  final int correct;
  final int wrong;
  final int streak;
  final int maxStreak;
  final int questionsAnswered;
  final Duration remaining;
  final bool isOver;

  const PatternSprintState({
    required this.question,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.streak,
    required this.maxStreak,
    required this.questionsAnswered,
    required this.remaining,
    required this.isOver,
  });

  PatternSprintState copyWith({
    PatternSprintQuestion? question,
    int? score,
    int? correct,
    int? wrong,
    int? streak,
    int? maxStreak,
    int? questionsAnswered,
    Duration? remaining,
    bool? isOver,
  }) {
    return PatternSprintState(
      question: question ?? this.question,
      score: score ?? this.score,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      streak: streak ?? this.streak,
      maxStreak: maxStreak ?? this.maxStreak,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      remaining: remaining ?? this.remaining,
      isOver: isOver ?? this.isOver,
    );
  }
}

class PatternSprintController {
  final ArcadeDifficulty difficulty;
  final PatternSprintConfig config;
  final Random _rng;

  late PatternSprintState _state;
  PatternSprintState get state => _state;

  Timer? _timer;
  bool _locked = false;

  PatternSprintController({
    required this.difficulty,
    Random? rng,
  })  : _rng = rng ?? Random(),
        config = PatternSprintConfig.fromDifficulty(difficulty) {
    final first = _generateQuestion();
    _state = PatternSprintState(
      question: first,
      score: 0,
      correct: 0,
      wrong: 0,
      streak: 0,
      maxStreak: 0,
      questionsAnswered: 0,
      remaining: config.timeLimit,
      isOver: false,
    );
  }

  void start(void Function(PatternSprintState) onTick) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.isOver) return;
      final next = _state.remaining - const Duration(seconds: 1);
      if (next.inSeconds <= 0) {
        _state = _state.copyWith(remaining: Duration.zero, isOver: true);
        onTick(_state);
        _timer?.cancel();
        return;
      }
      _state = _state.copyWith(remaining: next);
      onTick(_state);
    });
  }

  void dispose() {
    _timer?.cancel();
  }

  /// Returns true if correct, false otherwise.
  bool answer(int selected, void Function(PatternSprintState) onUpdate) {
    if (_state.isOver || _locked) return false;
    _locked = true;

    final isCorrect = selected == _state.question.answer;

    final nextQuestions = _state.questionsAnswered + 1;

    if (isCorrect) {
      final nextStreak = _state.streak + 1;
      final streakBonusMultiplier = (1.0 + (nextStreak * 0.06)).clamp(1.0, 2.0);

      final timeBonus =
          (_state.remaining.inSeconds / config.timeLimit.inSeconds)
              .clamp(0.25, 1.0);

      final gained = (config.basePoints *
              streakBonusMultiplier *
              (0.75 + (0.25 * timeBonus)))
          .round();

      _state = _state.copyWith(
        score: _state.score + gained,
        correct: _state.correct + 1,
        streak: nextStreak,
        maxStreak: max(_state.maxStreak, nextStreak),
        questionsAnswered: nextQuestions,
      );
    } else {
      // Wrong answer: reset streak, small score penalty (never below 0)
      final penalty = (config.basePoints * 0.25).round();
      _state = _state.copyWith(
        score: max(0, _state.score - penalty),
        wrong: _state.wrong + 1,
        streak: 0,
        questionsAnswered: nextQuestions,
      );
    }

    // Next question
    _state = _state.copyWith(question: _generateQuestion());
    onUpdate(_state);

    // Unlock quickly so UI feels responsive
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      _locked = false;
    });

    return isCorrect;
  }

  ArcadeResult toResult() {
    final accuracy = _state.questionsAnswered == 0
        ? 0.0
        : (_state.correct / _state.questionsAnswered);

    return ArcadeResult(
      gameId: ArcadeGameId.patternSprint,
      difficulty: difficulty,
      score: _state.score,
      duration: Duration.zero, // shell attaches canonical duration
      metadata: {
        'correct': _state.correct,
        'wrong': _state.wrong,
        'questionsAnswered': _state.questionsAnswered,
        'maxStreak': _state.maxStreak,
        'accuracy': accuracy,
      },
    );
  }

  PatternSprintQuestion _generateQuestion() {
    // Three families of patterns:
    // - arithmetic progression
    // - geometric progression (small ints)
    // - alternating add/sub pattern
    final type = _rng.nextInt(_patternTypeCount());

    switch (type) {
      case 0:
        return _arithmetic();
      case 1:
        return _geometric();
      default:
        return _alternating();
    }
  }

  int _patternTypeCount() {
    switch (difficulty) {
      case ArcadeDifficulty.easy:
        return 2; // arithmetic, alternating
      case ArcadeDifficulty.normal:
        return 3; // arithmetic, geometric, alternating
      case ArcadeDifficulty.hard:
        return 3;
      case ArcadeDifficulty.insane:
        return 3;
    }
  }

  PatternSprintQuestion _arithmetic() {
    final length = _seqLength();
    final start = _rngRange(1, _maxStart());
    final step = _rngRange(1, _maxStep());

    final values = List<int>.generate(length, (i) => start + (i * step));

    return _toQuestion(values);
  }

  PatternSprintQuestion _geometric() {
    final length = _seqLength();
    final start = _rngRange(1, _maxStart().clamp(3, 12));
    final ratio = _rngRange(2, _maxRatio());
    final values = <int>[];

    int v = start;
    for (int i = 0; i < length; i++) {
      values.add(v);
      v = v * ratio;
      // prevent huge numbers
      if (v > 999) break;
    }

    // ensure minimum length
    while (values.length < length) {
      values.add(values.last + _rngRange(3, 9));
    }

    return _toQuestion(values.take(length).toList());
  }

  PatternSprintQuestion _alternating() {
    final length = _seqLength();
    final start = _rngRange(10, _maxStart() + 20);
    final a = _rngRange(2, _maxStep() + 2);
    final b = _rngRange(3, _maxStep() + 3);

    final values = <int>[start];
    for (int i = 1; i < length; i++) {
      final prev = values[i - 1];
      final next = (i % 2 == 1) ? (prev + a) : (prev - b);
      values.add(next);
    }

    return _toQuestion(values);
  }

  PatternSprintQuestion _toQuestion(List<int> values) {
    final length = values.length;
    final missingIndex = _rng.nextInt(length);
    final answer = values[missingIndex];

    final sequence = <String>[];
    for (int i = 0; i < length; i++) {
      sequence.add(i == missingIndex ? '?' : values[i].toString());
    }

    final options = _buildOptions(answer);
    return PatternSprintQuestion(
      sequence: sequence,
      missingIndex: missingIndex,
      answer: answer,
      options: options,
    );
  }

  List<int> _buildOptions(int answer) {
    final set = <int>{answer};

    final spread = _optionSpread();
    while (set.length < 4) {
      final delta = _rngRange(-spread, spread);
      final candidate = answer + delta;
      if (candidate != answer) set.add(candidate);
    }

    final list = set.toList()..shuffle(_rng);
    return list;
  }

  int _seqLength() {
    switch (difficulty) {
      case ArcadeDifficulty.easy:
        return 5;
      case ArcadeDifficulty.normal:
        return 6;
      case ArcadeDifficulty.hard:
        return 7;
      case ArcadeDifficulty.insane:
        return 7;
    }
  }

  int _maxStart() {
    switch (difficulty) {
      case ArcadeDifficulty.easy:
        return 25;
      case ArcadeDifficulty.normal:
        return 40;
      case ArcadeDifficulty.hard:
        return 60;
      case ArcadeDifficulty.insane:
        return 70;
    }
  }

  int _maxStep() {
    switch (difficulty) {
      case ArcadeDifficulty.easy:
        return 6;
      case ArcadeDifficulty.normal:
        return 9;
      case ArcadeDifficulty.hard:
        return 13;
      case ArcadeDifficulty.insane:
        return 16;
    }
  }

  int _maxRatio() {
    switch (difficulty) {
      case ArcadeDifficulty.easy:
        return 3;
      case ArcadeDifficulty.normal:
        return 4;
      case ArcadeDifficulty.hard:
        return 5;
      case ArcadeDifficulty.insane:
        return 5;
    }
  }

  int _optionSpread() {
    switch (difficulty) {
      case ArcadeDifficulty.easy:
        return 12;
      case ArcadeDifficulty.normal:
        return 18;
      case ArcadeDifficulty.hard:
        return 26;
      case ArcadeDifficulty.insane:
        return 30;
    }
  }

  int _rngRange(int minInclusive, int maxInclusive) {
    if (maxInclusive <= minInclusive) return minInclusive;
    return minInclusive + _rng.nextInt((maxInclusive - minInclusive) + 1);
  }
}
