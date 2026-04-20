import 'dart:async';
import 'dart:math';

import '../../domain/arcade_difficulty.dart';
import '../../domain/arcade_game_id.dart';
import '../../domain/arcade_result.dart';
import 'quick_math_models.dart';

class QuickMathState {
  final QuickMathQuestion question;

  final int score;
  final int correct;
  final int wrong;
  final int answered;

  final int streak;
  final int maxStreak;

  final Duration remaining;
  final bool isOver;

  // “pace” indicator, optional
  final double paceProgress; // 0..1

  const QuickMathState({
    required this.question,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.answered,
    required this.streak,
    required this.maxStreak,
    required this.remaining,
    required this.isOver,
    required this.paceProgress,
  });

  QuickMathState copyWith({
    QuickMathQuestion? question,
    int? score,
    int? correct,
    int? wrong,
    int? answered,
    int? streak,
    int? maxStreak,
    Duration? remaining,
    bool? isOver,
    double? paceProgress,
  }) {
    return QuickMathState(
      question: question ?? this.question,
      score: score ?? this.score,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      answered: answered ?? this.answered,
      streak: streak ?? this.streak,
      maxStreak: maxStreak ?? this.maxStreak,
      remaining: remaining ?? this.remaining,
      isOver: isOver ?? this.isOver,
      paceProgress: paceProgress ?? this.paceProgress,
    );
  }
}

class QuickMathController {
  final ArcadeDifficulty difficulty;
  final QuickMathConfig config;
  final Random _rng;

  late QuickMathState _state;
  QuickMathState get state => _state;

  Timer? _timer;
  Timer? _paceTimer;

  bool _locked = false;

  QuickMathController({
    required this.difficulty,
    Random? rng,
  })  : _rng = rng ?? Random(),
        config = QuickMathConfig.fromDifficulty(difficulty) {
    final q = _generateQuestion();
    _state = QuickMathState(
      question: q,
      score: 0,
      correct: 0,
      wrong: 0,
      answered: 0,
      streak: 0,
      maxStreak: 0,
      remaining: config.timeLimit,
      isOver: false,
      paceProgress: 0,
    );
  }

  void start(void Function(QuickMathState) onUpdate) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.isOver) return;

      final next = _state.remaining - const Duration(seconds: 1);
      if (next.inSeconds <= 0) {
        _state = _state.copyWith(remaining: Duration.zero, isOver: true);
        onUpdate(_state);
        _timer?.cancel();
        _paceTimer?.cancel();
        return;
      }

      _state = _state.copyWith(remaining: next);
      onUpdate(_state);
    });

    // pace indicator resets each new question
    _paceTimer?.cancel();
    _paceTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_state.isOver) return;
      final inc = 50 / config.perQuestionTime.inMilliseconds;
      final next = (_state.paceProgress + inc).clamp(0.0, 1.0);
      _state = _state.copyWith(paceProgress: next);
      onUpdate(_state);
    });
  }

  void dispose() {
    _timer?.cancel();
    _paceTimer?.cancel();
  }

  bool answer(int selected, void Function(QuickMathState) onUpdate) {
    if (_state.isOver || _locked) return false;
    _locked = true;

    final isCorrect = selected == _state.question.answer;
    final nextAnswered = _state.answered + 1;

    if (isCorrect) {
      final nextStreak = _state.streak + 1;
      final streakMult =
          (1.0 + (nextStreak * config.streakMultiplierStep)).clamp(1.0, 2.5);

      // time bonus based on remaining total time (encourages speed)
      final total = config.timeLimit.inSeconds.clamp(1, 9999);
      final rem = _state.remaining.inSeconds.clamp(0, total);
      final timeFactor = (0.75 + 0.55 * (rem / total)).clamp(0.75, 1.3);

      // pace factor: answering before pace bar fills yields slightly higher points
      final paceFactor = (1.15 - (_state.paceProgress * 0.25)).clamp(0.9, 1.15);

      final gained = (config.basePoints * streakMult * timeFactor * paceFactor)
          .round()
          .clamp(10, 900);

      _state = _state.copyWith(
        score: _state.score + gained,
        correct: _state.correct + 1,
        streak: nextStreak,
        maxStreak: max(_state.maxStreak, nextStreak),
        answered: nextAnswered,
      );
    } else {
      final penalty = config.wrongPenalty;
      _state = _state.copyWith(
        score: max(0, _state.score - penalty),
        wrong: _state.wrong + 1,
        streak: 0,
        answered: nextAnswered,
      );
    }

    // next question
    _state = _state.copyWith(
      question: _generateQuestion(),
      paceProgress: 0,
    );
    onUpdate(_state);

    // unlock shortly
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      _locked = false;
    });

    return isCorrect;
  }

  ArcadeResult toResult() {
    final answered = _state.answered == 0 ? 1 : _state.answered;
    final accuracy = (_state.correct / answered).clamp(0.0, 1.0);

    return ArcadeResult(
      gameId: ArcadeGameId.quickMathRush,
      difficulty: difficulty,
      score: _state.score,
      duration: Duration.zero, // shell sets canonical duration
      metadata: {
        'correct': _state.correct,
        'wrong': _state.wrong,
        'answered': _state.answered,
        'maxStreak': _state.maxStreak,
        'accuracy': accuracy,
      },
    );
  }

  QuickMathQuestion _generateQuestion() {
    final op = config.ops[_rng.nextInt(config.ops.length)];

    int a = _rngRange(config.minA, config.maxA);
    int b = _rngRange(config.minB, config.maxB);

    // Ensure non-trivial subtraction (avoid negative unless insane)
    if (op == QuickMathOp.sub) {
      if (difficulty != ArcadeDifficulty.insane && b > a) {
        final t = a;
        a = b;
        b = t;
      }
    }

    // For division ensure integer results
    if (op == QuickMathOp.div) {
      // choose a multiple of b
      b = _rngRange(max(2, config.minB), config.maxB);
      final q = _rngRange(2, (config.maxA / b).floor().clamp(2, 12));
      a = b * q;
    }

    final answer = _eval(a, b, op);
    final options = _buildOptions(answer, op);

    return QuickMathQuestion(
      a: a,
      b: b,
      op: op,
      answer: answer,
      options: options,
    );
  }

  int _eval(int a, int b, QuickMathOp op) {
    switch (op) {
      case QuickMathOp.add:
        return a + b;
      case QuickMathOp.sub:
        return a - b;
      case QuickMathOp.mul:
        return a * b;
      case QuickMathOp.div:
        return (a / b).round(); // should already be exact
    }
  }

  List<int> _buildOptions(int answer, QuickMathOp op) {
    final set = <int>{answer};

    // Spread depends on magnitude and operation type
    final magnitude = answer.abs().clamp(1, 999);
    final baseSpread = (magnitude * 0.25).round().clamp(3, 40);

    final spread = switch (op) {
      QuickMathOp.mul => (baseSpread + 6).clamp(6, 55),
      QuickMathOp.div => (baseSpread).clamp(3, 35),
      _ => baseSpread,
    };

    while (set.length < config.optionCount) {
      final delta = _rngRange(-spread, spread);
      final candidate = answer + delta;
      if (candidate != answer) set.add(candidate);
    }

    final list = set.toList()..shuffle(_rng);
    return list;
  }

  int _rngRange(int minInclusive, int maxInclusive) {
    if (maxInclusive <= minInclusive) return minInclusive;
    return minInclusive + _rng.nextInt((maxInclusive - minInclusive) + 1);
  }
}
