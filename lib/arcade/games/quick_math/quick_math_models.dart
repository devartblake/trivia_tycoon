import '../../domain/arcade_difficulty.dart';

enum QuickMathOp { add, sub, mul, div }

extension QuickMathOpX on QuickMathOp {
  String get symbol {
    switch (this) {
      case QuickMathOp.add:
        return '+';
      case QuickMathOp.sub:
        return '−';
      case QuickMathOp.mul:
        return '×';
      case QuickMathOp.div:
        return '÷';
    }
  }
}

class QuickMathConfig {
  final Duration timeLimit;
  final Duration perQuestionTime; // optional “pace” feel
  final int optionCount;

  // ranges and enabled ops
  final int minA;
  final int maxA;
  final int minB;
  final int maxB;
  final List<QuickMathOp> ops;

  // scoring
  final int basePoints;
  final int wrongPenalty;
  final double streakMultiplierStep; // per streak level

  const QuickMathConfig({
    required this.timeLimit,
    required this.perQuestionTime,
    required this.optionCount,
    required this.minA,
    required this.maxA,
    required this.minB,
    required this.maxB,
    required this.ops,
    required this.basePoints,
    required this.wrongPenalty,
    required this.streakMultiplierStep,
  });

  static QuickMathConfig fromDifficulty(ArcadeDifficulty d) {
    switch (d) {
      case ArcadeDifficulty.easy:
        return const QuickMathConfig(
          timeLimit: Duration(seconds: 45),
          perQuestionTime: Duration(milliseconds: 2800),
          optionCount: 4,
          minA: 1,
          maxA: 20,
          minB: 1,
          maxB: 12,
          ops: [QuickMathOp.add, QuickMathOp.sub],
          basePoints: 55,
          wrongPenalty: 10,
          streakMultiplierStep: 0.08,
        );
      case ArcadeDifficulty.normal:
        return const QuickMathConfig(
          timeLimit: Duration(seconds: 50),
          perQuestionTime: Duration(milliseconds: 2400),
          optionCount: 4,
          minA: 3,
          maxA: 35,
          minB: 2,
          maxB: 18,
          ops: [QuickMathOp.add, QuickMathOp.sub, QuickMathOp.mul],
          basePoints: 75,
          wrongPenalty: 12,
          streakMultiplierStep: 0.10,
        );
      case ArcadeDifficulty.hard:
        return const QuickMathConfig(
          timeLimit: Duration(seconds: 55),
          perQuestionTime: Duration(milliseconds: 2100),
          optionCount: 4,
          minA: 6,
          maxA: 60,
          minB: 2,
          maxB: 24,
          ops: [
            QuickMathOp.add,
            QuickMathOp.sub,
            QuickMathOp.mul,
            QuickMathOp.div
          ],
          basePoints: 95,
          wrongPenalty: 14,
          streakMultiplierStep: 0.12,
        );
      case ArcadeDifficulty.insane:
        return const QuickMathConfig(
          timeLimit: Duration(seconds: 60),
          perQuestionTime: Duration(milliseconds: 1800),
          optionCount: 4,
          minA: 10,
          maxA: 99,
          minB: 2,
          maxB: 30,
          ops: [
            QuickMathOp.add,
            QuickMathOp.sub,
            QuickMathOp.mul,
            QuickMathOp.div
          ],
          basePoints: 120,
          wrongPenalty: 16,
          streakMultiplierStep: 0.14,
        );
    }
  }
}

class QuickMathQuestion {
  final int a;
  final int b;
  final QuickMathOp op;
  final int answer;
  final List<int> options;

  const QuickMathQuestion({
    required this.a,
    required this.b,
    required this.op,
    required this.answer,
    required this.options,
  });

  String get prompt => '$a ${op.symbol} $b = ?';
}
