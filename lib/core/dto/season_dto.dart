class SeasonDto {
  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;

  const SeasonDto({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
  });

  factory SeasonDto.fromJson(Map<String, dynamic> j) => SeasonDto(
        id: j['id'] as String,
        name: j['name'] as String,
        startsAt: DateTime.parse(j['startsAt'] as String),
        endsAt: DateTime.parse(j['endsAt'] as String),
        isActive: j['isActive'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startsAt': startsAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
        'isActive': isActive,
      };
}

/// Eligibility for a season-tier reward (`GET /seasons/rewards/eligibility/{playerId}`).
class RewardEligibilityDto {
  final String seasonId;
  final String playerId;
  final bool eligible;

  /// Eligible | Placement | NotInTop20 | AlreadyClaimed | ...
  final String reason;
  final int tier;
  final int tierRank;
  final int rankPoints;
  final int rewardCoins;
  final int rewardXp;
  final DateTime? nextClaimAtUtc;

  const RewardEligibilityDto({
    required this.seasonId,
    required this.playerId,
    required this.eligible,
    required this.reason,
    required this.tier,
    required this.tierRank,
    required this.rankPoints,
    required this.rewardCoins,
    required this.rewardXp,
    this.nextClaimAtUtc,
  });

  factory RewardEligibilityDto.fromJson(Map<String, dynamic> j) =>
      RewardEligibilityDto(
        seasonId: j['seasonId'] as String,
        playerId: j['playerId'] as String,
        eligible: j['eligible'] as bool? ?? false,
        reason: j['reason'] as String? ?? '',
        tier: j['tier'] as int? ?? 0,
        tierRank: j['tierRank'] as int? ?? 0,
        rankPoints: j['rankPoints'] as int? ?? 0,
        rewardCoins: j['rewardCoins'] as int? ?? 0,
        rewardXp: j['rewardXp'] as int? ?? 0,
        nextClaimAtUtc: DateTime.tryParse(j['nextClaimAtUtc'] as String? ?? ''),
      );
}

/// Result of claiming a season reward (`POST /seasons/rewards/claim/{playerId}`).
class ClaimSeasonRewardResultDto {
  final String eventId;
  final String seasonId;
  final String playerId;

  /// Applied | Duplicate | NotEligible
  final String status;
  final int awardedCoins;
  final int awardedXp;

  const ClaimSeasonRewardResultDto({
    required this.eventId,
    required this.seasonId,
    required this.playerId,
    required this.status,
    required this.awardedCoins,
    required this.awardedXp,
  });

  bool get applied => status == 'Applied';

  factory ClaimSeasonRewardResultDto.fromJson(Map<String, dynamic> j) =>
      ClaimSeasonRewardResultDto(
        eventId: j['eventId'] as String? ?? '',
        seasonId: j['seasonId'] as String? ?? '',
        playerId: j['playerId'] as String? ?? '',
        status: j['status'] as String? ?? 'Unknown',
        awardedCoins: j['awardedCoins'] as int? ?? 0,
        awardedXp: j['awardedXp'] as int? ?? 0,
      );
}

class PlayerSeasonStateDto {
  final String playerId;
  final String seasonId;
  final int tier;
  final int xp;
  final int rank;
  final int guardiansDefeated;
  final int tilesControlled;

  const PlayerSeasonStateDto({
    required this.playerId,
    required this.seasonId,
    required this.tier,
    required this.xp,
    required this.rank,
    required this.guardiansDefeated,
    required this.tilesControlled,
  });

  factory PlayerSeasonStateDto.fromJson(Map<String, dynamic> j) =>
      PlayerSeasonStateDto(
        playerId: j['playerId'] as String,
        seasonId: j['seasonId'] as String,
        tier: j['tier'] as int? ?? 1,
        xp: j['xp'] as int? ?? 0,
        rank: j['rank'] as int? ?? 0,
        guardiansDefeated: j['guardiansDefeated'] as int? ?? 0,
        tilesControlled: j['tilesControlled'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'seasonId': seasonId,
        'tier': tier,
        'xp': xp,
        'rank': rank,
        'guardiansDefeated': guardiansDefeated,
        'tilesControlled': tilesControlled,
      };
}
