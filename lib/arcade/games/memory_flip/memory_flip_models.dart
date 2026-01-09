import '../../domain/arcade_difficulty.dart';

class MemoryFlipConfig {
  final int gridSize; // total cards (must be even)
  final Duration timeLimit;
  final int baseMatchPoints;
  final int missPenalty;

  const MemoryFlipConfig({
    required this.gridSize,
    required this.timeLimit,
    required this.baseMatchPoints,
    required this.missPenalty,
  });

  static MemoryFlipConfig fromDifficulty(ArcadeDifficulty d) {
    switch (d) {
      case ArcadeDifficulty.easy:
        return const MemoryFlipConfig(
          gridSize: 12, // 3x4
          timeLimit: Duration(seconds: 60),
          baseMatchPoints: 90,
          missPenalty: 12,
        );
      case ArcadeDifficulty.normal:
        return const MemoryFlipConfig(
          gridSize: 16, // 4x4
          timeLimit: Duration(seconds: 70),
          baseMatchPoints: 110,
          missPenalty: 14,
        );
      case ArcadeDifficulty.hard:
        return const MemoryFlipConfig(
          gridSize: 20, // 4x5
          timeLimit: Duration(seconds: 75),
          baseMatchPoints: 130,
          missPenalty: 16,
        );
      case ArcadeDifficulty.insane:
        return const MemoryFlipConfig(
          gridSize: 24, // 4x6
          timeLimit: Duration(seconds: 80),
          baseMatchPoints: 150,
          missPenalty: 18,
        );
    }
  }
}

class MemoryCard {
  final int id; // pair id
  final int index;
  final bool isMatched;
  final bool isFaceUp;

  const MemoryCard({
    required this.id,
    required this.index,
    required this.isMatched,
    required this.isFaceUp,
  });

  MemoryCard copyWith({
    int? id,
    int? index,
    bool? isMatched,
    bool? isFaceUp,
  }) {
    return MemoryCard(
      id: id ?? this.id,
      index: index ?? this.index,
      isMatched: isMatched ?? this.isMatched,
      isFaceUp: isFaceUp ?? this.isFaceUp,
    );
  }
}
