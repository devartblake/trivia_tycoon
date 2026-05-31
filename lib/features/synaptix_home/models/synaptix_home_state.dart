import 'package:flutter/material.dart';

class SynaptixHomeState {
  final SynaptixHomePlayer player;
  final List<SynaptixHomeAction> primaryActions;
  final List<SynaptixHomeMission> missions;
  final List<SynaptixHomeLeaderboardEntry> leaderboard;
  final List<SynaptixRecentActivity> recentActivity;
  final List<SynaptixRecommendation> recommendations;
  final List<SynaptixAchievement> achievements;
  final SynaptixFeaturedEvent featuredEvent;
  final SynaptixNewsItem newsItem;
  final SynaptixRewardPrompt dailyReward;
  final List<SynaptixFriendPreview> friends;
  final bool profileIncomplete;
  final int remainingAccountRewards;

  const SynaptixHomeState({
    required this.player,
    required this.primaryActions,
    required this.missions,
    required this.leaderboard,
    required this.recentActivity,
    required this.recommendations,
    required this.achievements,
    required this.featuredEvent,
    required this.newsItem,
    required this.dailyReward,
    required this.friends,
    required this.profileIncomplete,
    required this.remainingAccountRewards,
  });
}

class SynaptixHomePlayer {
  final String displayName;
  final String handle;
  final String title;
  final int level;
  final int currentXp;
  final int targetXp;
  final int coins;
  final int gems;
  final int wins;
  final int matches;
  final int rank;
  final int streak;
  final int bestStreak;
  final int rating;
  final String rankTier;
  final List<String> preferredCategories;

  const SynaptixHomePlayer({
    required this.displayName,
    required this.handle,
    required this.title,
    required this.level,
    required this.currentXp,
    required this.targetXp,
    required this.coins,
    required this.gems,
    required this.wins,
    required this.matches,
    required this.rank,
    required this.streak,
    required this.bestStreak,
    required this.rating,
    required this.rankTier,
    required this.preferredCategories,
  });

  double get xpProgress {
    if (targetXp <= 0) return 0;
    return (currentXp / targetXp).clamp(0, 1).toDouble();
  }

  double get winRate {
    if (matches <= 0) return 0;
    return wins / matches;
  }
}

class SynaptixHomeAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  const SynaptixHomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });
}

class SynaptixHomeMission {
  final String title;
  final int current;
  final int target;
  final int rewardCoins;
  final IconData icon;

  const SynaptixHomeMission({
    required this.title,
    required this.current,
    required this.target,
    required this.rewardCoins,
    required this.icon,
  });

  double get progress {
    if (target <= 0) return 0;
    return (current / target).clamp(0, 1).toDouble();
  }

  String get progressLabel => '$current/$target';
}

class SynaptixHomeLeaderboardEntry {
  final int rank;
  final String username;
  final int score;
  final bool isCurrentUser;

  const SynaptixHomeLeaderboardEntry({
    required this.rank,
    required this.username,
    required this.score,
    this.isCurrentUser = false,
  });
}

class SynaptixRecentActivity {
  final String title;
  final String score;
  final String date;

  const SynaptixRecentActivity({
    required this.title,
    required this.score,
    required this.date,
  });
}

class SynaptixRecommendation {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const SynaptixRecommendation({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

class SynaptixAchievement {
  final IconData icon;
  final String title;
  final String subtitle;

  const SynaptixAchievement({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class SynaptixFeaturedEvent {
  final IconData icon;
  final String title;
  final String subtitle;
  final String timeRemaining;
  final String route;

  const SynaptixFeaturedEvent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timeRemaining,
    required this.route,
  });
}

class SynaptixNewsItem {
  final String title;
  final String body;
  final String route;

  const SynaptixNewsItem({
    required this.title,
    required this.body,
    required this.route,
  });
}

class SynaptixRewardPrompt {
  final String title;
  final String body;
  final String route;
  final IconData icon;

  const SynaptixRewardPrompt({
    required this.title,
    required this.body,
    required this.route,
    required this.icon,
  });
}

class SynaptixFriendPreview {
  final String initials;
  final Color color;

  const SynaptixFriendPreview({
    required this.initials,
    required this.color,
  });
}
