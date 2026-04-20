import '../../domain/arcade_difficulty.dart';

class PatternSprintQuestion {
  final List<String> sequence; // includes '?' at missingIndex
  final int missingIndex;
  final int answer;
  final List<int> options;

  const PatternSprintQuestion({
    required this.sequence,
    required this.missingIndex,
    required this.answer,
    required this.options,
  });
}

class PatternSprintConfig {
  final Duration timeLimit;
  final int basePoints;

  const PatternSprintConfig({
    required this.timeLimit,
    required this.basePoints,
  });

  static PatternSprintConfig fromDifficulty(ArcadeDifficulty d) {
    switch (d) {
      case ArcadeDifficulty.easy:
        return const PatternSprintConfig(
            timeLimit: Duration(seconds: 45), basePoints: 60);
      case ArcadeDifficulty.normal:
        return const PatternSprintConfig(
            timeLimit: Duration(seconds: 40), basePoints: 80);
      case ArcadeDifficulty.hard:
        return const PatternSprintConfig(
            timeLimit: Duration(seconds: 35), basePoints: 105);
      case ArcadeDifficulty.insane:
        return const PatternSprintConfig(
            timeLimit: Duration(seconds: 30), basePoints: 135);
    }
  }
}
