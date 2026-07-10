/// A spectator's no-loss prediction state for a Champion vs Tier match, from
/// GET /game-events/{id}/prediction (ChampionPredictionStateDto).
class ChampionPrediction {
  final String gameEventId;

  /// Predictions still accepted (event is in its Open window).
  final bool open;

  /// The caller's pick: true = champion defends, false = dethrone; null = none.
  final bool? myPrediction;

  final int defendCount;
  final int dethroneCount;
  final int rewardCoinPool;

  final bool resolved;
  final bool? wasCorrect;
  final int rewardCoins;
  final int rewardXp;

  const ChampionPrediction({
    required this.gameEventId,
    required this.open,
    required this.myPrediction,
    required this.defendCount,
    required this.dethroneCount,
    required this.rewardCoinPool,
    required this.resolved,
    required this.wasCorrect,
    required this.rewardCoins,
    required this.rewardXp,
  });

  int get totalPredictions => defendCount + dethroneCount;
  bool get hasPicked => myPrediction != null;

  factory ChampionPrediction.fromJson(Map<String, dynamic> j) {
    int i(String a, String b) => (j[a] ?? j[b] ?? 0) as int;
    bool? tri(String a, String b) => (j[a] ?? j[b]) as bool?;
    return ChampionPrediction(
      gameEventId: (j['gameEventId'] ?? j['GameEventId'] ?? '').toString(),
      open: (j['open'] ?? j['Open'] ?? false) as bool,
      myPrediction: tri('myPrediction', 'MyPrediction'),
      defendCount: i('defendCount', 'DefendCount'),
      dethroneCount: i('dethroneCount', 'DethroneCount'),
      rewardCoinPool: i('rewardCoinPool', 'RewardCoinPool'),
      resolved: (j['resolved'] ?? j['Resolved'] ?? false) as bool,
      wasCorrect: tri('wasCorrect', 'WasCorrect'),
      rewardCoins: i('rewardCoins', 'RewardCoins'),
      rewardXp: i('rewardXp', 'RewardXp'),
    );
  }
}
