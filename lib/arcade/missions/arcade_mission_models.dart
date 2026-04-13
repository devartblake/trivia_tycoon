import 'package:flutter/foundation.dart';

import '../domain/arcade_game_id.dart';

/// Mission tiers determine reset cadence and grouping.
enum ArcadeMissionTier {
  daily,
  weekly,
  season,
}

enum ArcadeMissionType {
  /// Increment when a run completes (any game, or filtered by gameId if set).
  playRuns,

  /// Set progress to target if score >= threshold (optionally filtered by gameId).
  scoreAtLeast,

  /// Increment when a run is marked as a new personal best.
  setNewPb,
}

@immutable
class ArcadeMissionReward {
  final int coins;
  final int gems;

  /// Optional XP reward (you added this; keep it).
  final int xp;

  const ArcadeMissionReward({
    required this.coins,
    required this.gems,
    this.xp = 0,
  });

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'gems': gems,
    'xp': xp,
  };

  factory ArcadeMissionReward.fromJson(Map<String, dynamic> json) {
    return ArcadeMissionReward(
      coins: (json['coins'] ?? 0) as int,
      gems: (json['gems'] ?? 0) as int,
      xp: (json['xp'] ?? 0) as int,
    );
  }
}

@immutable
class ArcadeMission {
  final String id;

  /// Daily / Weekly / Season
  final ArcadeMissionTier tier;

  /// What the mission measures.
  final ArcadeMissionType type;

  final String title;
  final String subtitle;

  /// Target progress to become claimable.
  final int target;

  /// Optional: restrict mission to a specific arcade game.
  final ArcadeGameId? gameId;

  /// Optional: further restrict to difficulty (backend-driven).
  final String? difficulty;

  /// Optional: minimum score threshold (backend-driven).
  /// For [ArcadeMissionType.scoreAtLeast], you can either use [target] or [minScore].
  /// Convention recommended: keep [target] as the "required score" and leave [minScore] null,
  /// OR use [minScore] and set [target] to 1. Up to your catalog/back-end design.
  final int? minScore;

  /// NEW: Season identifier for season-tier missions / backend config.
  /// For daily/weekly, this can be null.
  final String? seasonId;

  /// Reward for claiming.
  final ArcadeMissionReward reward;

  const ArcadeMission({
    required this.id,
    this.tier = ArcadeMissionTier.daily,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.target,
    required this.reward,
    this.gameId,
    this.difficulty,
    this.minScore,
    this.seasonId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tier': tier.name,
    'type': type.name,
    'title': title,
    'subtitle': subtitle,
    'target': target,
    'reward': reward.toJson(),
    'gameId': gameId?.name,
    'difficulty': difficulty,
    'minScore': minScore,
    'seasonId': seasonId,
  };

  // ---------
  // Parsing helpers (backend-tolerant)
  // ---------

  static ArcadeMissionTier _parseTier(dynamic v) {
    final s = (v ?? '').toString().trim().toLowerCase();
    switch (s) {
      case 'weekly':
        return ArcadeMissionTier.weekly;
      case 'season':
      case 'seasonal':
        return ArcadeMissionTier.season;
      case 'daily':
      default:
      // Also handles empty/unknown values safely.
        return ArcadeMissionTier.daily;
    }
  }

  static ArcadeMissionType _parseType(dynamic v) {
    final s = (v ?? '').toString().trim().toLowerCase();
    switch (s) {
      case 'scoreatleast':
      case 'score_at_least':
      case 'score':
        return ArcadeMissionType.scoreAtLeast;

      case 'setnewpb':
      case 'set_new_pb':
      case 'pb':
      case 'newpb':
        return ArcadeMissionType.setNewPb;

      case 'playruns':
      case 'play_runs':
      case 'runs':
      default:
        return ArcadeMissionType.playRuns;
    }
  }

  static ArcadeGameId? _parseGameId(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;

    for (final g in ArcadeGameId.values) {
      if (g.name == s) return g;
    }
    return null;
  }

  factory ArcadeMission.fromJson(Map<String, dynamic> json) {
    // Support both your exact enum names and backend-friendly variants.
    final tier = _parseTier(json['tier']);
    final type = _parseType(json['type']);

    // NOTE: Some backends may send "min_score" or "minScore".
    int? parseMinScore() {
      final a = json['minScore'];
      final b = json['min_score'];
      final v = a ?? b;
      if (v == null) return null;
      if (v is int) return v;
      final parsed = int.tryParse(v.toString());
      return parsed;
    }

    // NOTE: Some backends may send "season_id" or "seasonId".
    String? parseSeasonId() {
      final a = json['seasonId'];
      final b = json['season_id'];
      final v = a ?? b;
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final rewardRaw = (json['reward'] ?? const {});
    final rewardMap = rewardRaw is Map
        ? Map<String, dynamic>.from(rewardRaw)
        : <String, dynamic>{};

    return ArcadeMission(
      id: (json['id'] ?? '').toString(),
      tier: tier,
      type: type,
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      target: (json['target'] ?? 0) as int,
      reward: ArcadeMissionReward.fromJson(rewardMap),
      gameId: _parseGameId(json['gameId']),
      difficulty: json['difficulty']?.toString(),
      minScore: parseMinScore(),
      seasonId: parseSeasonId(),
    );
  }
}

/// Persisted mission progress.
/// This is your **anti-abuse lock**.
class ArcadeMissionProgress {
  final String missionId;

  /// Current progress (0..target)
  final int current;

  /// True once claimed. This is the persisted anti-double-claim lock.
  final bool claimed;

  /// Optional future-proofing:
  /// If you ever want cooldown, claimedAt, etc.
  final String? claimedAtUtcIso;

  const ArcadeMissionProgress({
    required this.missionId,
    required this.current,
    required this.claimed,
    this.claimedAtUtcIso,
  });

  ArcadeMissionProgress copyWith({
    int? current,
    bool? claimed,
    String? claimedAtUtcIso,
  }) {
    return ArcadeMissionProgress(
      missionId: missionId,
      current: current ?? this.current,
      claimed: claimed ?? this.claimed,
      claimedAtUtcIso: claimedAtUtcIso ?? this.claimedAtUtcIso,
    );
  }

  Map<String, dynamic> toJson() => {
    'missionId': missionId,
    'current': current,
    'claimed': claimed,
    'claimedAtUtcIso': claimedAtUtcIso,
  };

  factory ArcadeMissionProgress.fromJson(Map<String, dynamic> json) {
    return ArcadeMissionProgress(
      missionId: (json['missionId'] ?? '').toString(),
      current: (json['current'] ?? 0) as int,
      claimed: (json['claimed'] ?? false) as bool,
      claimedAtUtcIso: json['claimedAtUtcIso']?.toString(),
    );
  }
}
