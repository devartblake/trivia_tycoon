class SeasonRewardPreview {
  final String seasonId;
  final String playerId;
  final bool eligible;
  final int tier;
  final int tierRank;
  final int rewardXp;
  final int rewardCoins;

  const SeasonRewardPreview({
    required this.seasonId,
    required this.playerId,
    required this.eligible,
    required this.tier,
    required this.tierRank,
    required this.rewardXp,
    required this.rewardCoins,
  });

  factory SeasonRewardPreview.fromJson(Map<String, dynamic> j) {
    return SeasonRewardPreview(
      seasonId: j['seasonId'] as String,
      playerId: j['playerId'] as String,
      eligible: j['eligible'] as bool,
      tier: j['tier'] as int,
      tierRank: j['tierRank'] as int,
      rewardXp: j['rewardXp'] as int,
      rewardCoins: j['rewardCoins'] as int,
    );
  }
}
