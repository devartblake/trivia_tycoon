import '../domain/arcade_game_id.dart';

enum ArcadeMissionType {
  playRuns,
  scoreAtLeast,
  setNewPb,
}

class ArcadeMissionReward {
  final int coins;
  final int gems;

  const ArcadeMissionReward({
    required this.coins,
    required this.gems,
  });

  Map<String, dynamic> toJson() => {'coins': coins, 'gems': gems};

  factory ArcadeMissionReward.fromJson(Map<String, dynamic> json) {
    return ArcadeMissionReward(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
    );
  }
}

class ArcadeMission {
  final String id;
  final String title;
  final String subtitle;

  final ArcadeMissionType type;

  /// Optional filters/thresholds depending on mission type
  final ArcadeGameId? gameId;
  final int target; // e.g. 3 runs, score 800, 1 PB

  final ArcadeMissionReward reward;

  const ArcadeMission({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.target,
    required this.reward,
    this.gameId,
  });
}

class ArcadeMissionProgress {
  final String missionId;
  final int current;
  final bool claimed;

  const ArcadeMissionProgress({
    required this.missionId,
    required this.current,
    required this.claimed,
  });

  ArcadeMissionProgress copyWith({int? current, bool? claimed}) {
    return ArcadeMissionProgress(
      missionId: missionId,
      current: current ?? this.current,
      claimed: claimed ?? this.claimed,
    );
  }

  Map<String, dynamic> toJson() => {
    'missionId': missionId,
    'current': current,
    'claimed': claimed,
  };

  factory ArcadeMissionProgress.fromJson(Map<String, dynamic> json) {
    return ArcadeMissionProgress(
      missionId: (json['missionId'] as String?) ?? '',
      current: (json['current'] as num?)?.toInt() ?? 0,
      claimed: (json['claimed'] as bool?) ?? false,
    );
  }
}
