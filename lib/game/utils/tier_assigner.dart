import '../models/leaderboard_entry.dart';

class TierAssigner {
  /// Assigns global rank, tier, and tierRank to all leaderboard entries.
  static List<LeaderboardEntry> assignTiers(List<LeaderboardEntry> entries) {
    // Sort all entries by score descending
    entries.sort((a, b) => b.score.compareTo(a.score));

    List<LeaderboardEntry> updated = [];
    for (int i = 0; i < entries.length; i++) {
      final globalRank = i + 1;
      final tier = _determineTier(globalRank);
      final tierRank = _calculateTierRank(globalRank);
      final isPromotable = tierRank <= 25;
      final isRewarded = tierRank <= 20;

      updated.add(entries[i].copyWith(
        rank: globalRank,
        tier: tier,
        tierRank: tierRank,
        isPromotionEligible: isPromotable,
        isRewardEligible: isRewarded,
      ));
    }

    return updated;
  }

  static int _determineTier(int globalRank) {
    if (globalRank > 1000) return 0;
    return 11 - ((globalRank - 1) ~/ 100 + 1);
  }

  static int _calculateTierRank(int globalRank) {
    return (globalRank - 1) % 100 + 1;
  }
}