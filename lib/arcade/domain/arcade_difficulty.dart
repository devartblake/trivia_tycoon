enum ArcadeDifficulty {
  easy,
  normal,
  hard,
  insane,
}

extension ArcadeDifficultyX on ArcadeDifficulty {
  String get label {
    switch (this) {
      case ArcadeDifficulty.easy:
        return 'Easy';
      case ArcadeDifficulty.normal:
        return 'Normal';
      case ArcadeDifficulty.hard:
        return 'Hard';
      case ArcadeDifficulty.insane:
        return 'Insane';
    }
  }

  double get rewardMultiplier {
    switch (this) {
      case ArcadeDifficulty.easy:
        return 1.0;
      case ArcadeDifficulty.normal:
        return 1.25;
      case ArcadeDifficulty.hard:
        return 1.6;
      case ArcadeDifficulty.insane:
        return 2.0;
    }
  }
}