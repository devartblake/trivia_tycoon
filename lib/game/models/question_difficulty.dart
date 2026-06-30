/// Question difficulty enumeration for progression and reward calculation
enum QuestionDifficulty {
  easy,
  medium,
  hard,
  expert,
  boss,
}

extension QuestionDifficultyExtension on QuestionDifficulty {
  /// Convert enum to numeric value for storage/comparison
  int get value {
    switch (this) {
      case QuestionDifficulty.easy:
        return 1;
      case QuestionDifficulty.medium:
        return 2;
      case QuestionDifficulty.hard:
        return 3;
      case QuestionDifficulty.expert:
        return 4;
      case QuestionDifficulty.boss:
        return 5;
    }
  }

  /// Display name for UI
  String get displayName {
    switch (this) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
      case QuestionDifficulty.expert:
        return 'Expert';
      case QuestionDifficulty.boss:
        return 'Boss';
    }
  }

  /// XP multiplier for this difficulty (relative to easy=1.0)
  double get xpMultiplier {
    switch (this) {
      case QuestionDifficulty.easy:
        return 1.0;
      case QuestionDifficulty.medium:
        return 1.5;
      case QuestionDifficulty.hard:
        return 2.0;
      case QuestionDifficulty.expert:
        return 3.0;
      case QuestionDifficulty.boss:
        return 5.0;
    }
  }

  /// Coin multiplier for this difficulty (relative to easy=1.0)
  double get coinMultiplier {
    switch (this) {
      case QuestionDifficulty.easy:
        return 1.0;
      case QuestionDifficulty.medium:
        return 1.25;
      case QuestionDifficulty.hard:
        return 1.5;
      case QuestionDifficulty.expert:
        return 2.0;
      case QuestionDifficulty.boss:
        return 3.0;
    }
  }

  /// Streak multiplier bonus for this difficulty
  double get streakMultiplier {
    switch (this) {
      case QuestionDifficulty.easy:
        return 1.0;
      case QuestionDifficulty.medium:
        return 1.1;
      case QuestionDifficulty.hard:
        return 1.25;
      case QuestionDifficulty.expert:
        return 1.5;
      case QuestionDifficulty.boss:
        return 2.0;
    }
  }

  /// Time limit in seconds (if applicable)
  int? get timeLimitSeconds {
    switch (this) {
      case QuestionDifficulty.easy:
        return 30;
      case QuestionDifficulty.medium:
        return 25;
      case QuestionDifficulty.hard:
        return 20;
      case QuestionDifficulty.expert:
        return 15;
      case QuestionDifficulty.boss:
        return 10;
    }
  }

  /// Parse numeric value to enum (backward compatible with existing int system)
  static QuestionDifficulty fromInt(int value) {
    switch (value) {
      case 1:
        return QuestionDifficulty.easy;
      case 2:
        return QuestionDifficulty.medium;
      case 3:
        return QuestionDifficulty.hard;
      case 4:
        return QuestionDifficulty.expert;
      case 5:
        return QuestionDifficulty.boss;
      default:
        return QuestionDifficulty.easy;
    }
  }

  /// Parse string value to enum (backward compatible)
  static QuestionDifficulty fromString(String? value) {
    if (value == null || value.isEmpty) {
      return QuestionDifficulty.easy;
    }

    final normalized = value.toLowerCase().trim();

    switch (normalized) {
      case 'easy':
      case '1':
        return QuestionDifficulty.easy;
      case 'medium':
      case '2':
        return QuestionDifficulty.medium;
      case 'hard':
      case '3':
        return QuestionDifficulty.hard;
      case 'expert':
      case '4':
        return QuestionDifficulty.expert;
      case 'boss':
      case '5':
        return QuestionDifficulty.boss;
      default:
        return QuestionDifficulty.easy;
    }
  }

  /// Parse any value (int, String, or other) to enum
  static QuestionDifficulty parse(Object? value) {
    if (value is int) {
      return fromInt(value);
    } else if (value is String) {
      return fromString(value);
    } else if (value is num) {
      return fromInt(value.toInt());
    }
    return QuestionDifficulty.easy;
  }
}
