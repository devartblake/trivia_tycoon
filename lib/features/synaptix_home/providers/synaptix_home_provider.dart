import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/canonical_routes.dart';
import '../../../game/providers/account_rewards_provider.dart';
import '../../../game/providers/game_providers.dart';
import '../../../game/providers/onboarding_providers.dart';
import '../../../game/providers/wallet_providers.dart';
import '../../../game/providers/xp_provider.dart';
import '../models/synaptix_home_state.dart';
import '../theme/synaptix_home_theme.dart';

final synaptixHomeProvider = FutureProvider<SynaptixHomeState>((ref) async {
  final profileService = ref.read(playerProfileServiceProvider);
  final quizProgressService = ref.read(quizProgressServiceProvider);
  final onboardingProgress = ref.watch(onboardingProgressProvider).progress;
  final rewardClaims = ref.watch(accountRewardsProvider).valueOrNull;
  final coins = ref.watch(playerCoinsProvider);
  final gems = ref.watch(playerGemsProvider);
  final xp = ref.watch(playerXPProvider);

  final displayName = await profileService.getPlayerName();
  final username = await profileService.getUsername();
  final preferredCategories = await profileService.getPreferredCategories();
  final level = (xp ~/ 1000) + 1;
  const targetXp = 1000;
  final currentLevelXp = xp % 1000;

  final recent = quizProgressService
      .getRecentQuizzes()
      .take(4)
      .map(
        (quiz) => SynaptixRecentActivity(
          title: quiz['title'] ?? 'Recent quiz',
          score: quiz['score'] ?? '--',
          date: quiz['date'] ?? 'Recently',
        ),
      )
      .toList();

  final playerName = username?.trim().isNotEmpty == true
      ? username!.trim()
      : displayName.trim();
  final claimed = rewardClaims ?? const <String>{};
  final remainingRewards = accountRewardDefinitions
      .where((reward) => !claimed.contains(reward.key))
      .length;

  final player = SynaptixHomePlayer(
    displayName: displayName.trim().isEmpty ? 'Player' : displayName.trim(),
    handle: playerName.isEmpty ? 'player' : playerName,
    title: _playerTitle(level),
    level: level,
    currentXp: currentLevelXp,
    targetXp: targetXp,
    coins: coins,
    gems: gems,
    wins: 0,
    matches: recent.length,
    rank: 24,
    streak: recent.length,
    bestStreak: 7,
    rating: 1200 + xp ~/ 8 + coins ~/ 25,
    rankTier: _rankTierFor(level),
    preferredCategories: preferredCategories,
  );

  return SynaptixHomeState(
    player: player,
    primaryActions: const [
      SynaptixHomeAction(
        icon: Icons.flash_on_rounded,
        title: 'Quick Quiz',
        subtitle: 'Jump into a classic round.',
        route: '/quiz/start/classic',
        color: SynaptixHomeTheme.blue,
      ),
      SynaptixHomeAction(
        icon: Icons.leaderboard_rounded,
        title: 'Arena',
        subtitle: 'Check ranks and competition.',
        route: canonicalArenaRoute,
        color: SynaptixHomeTheme.purple,
      ),
      SynaptixHomeAction(
        icon: Icons.science_rounded,
        title: 'Labs',
        subtitle: 'Arcade challenges and bonuses.',
        route: canonicalLabsRoute,
        color: SynaptixHomeTheme.green,
      ),
      SynaptixHomeAction(
        icon: Icons.person_rounded,
        title: 'Journey',
        subtitle: 'Profile, progress, and identity.',
        route: canonicalJourneyRoute,
        color: SynaptixHomeTheme.amber,
      ),
    ],
    missions: _missionsFor(
      preferredCategories: preferredCategories,
      recentCount: recent.length,
      remainingRewards: remainingRewards,
    ),
    leaderboard: _leaderboardFor(player),
    recentActivity: recent,
    recommendations: _recommendationsFor(preferredCategories),
    achievements: _achievementsFor(
      level: level,
      preferredCategories: preferredCategories,
      remainingRewards: remainingRewards,
    ),
    featuredEvent: const SynaptixFeaturedEvent(
      icon: Icons.auto_awesome_rounded,
      title: 'Weekend Showdown',
      subtitle: 'Double XP and exclusive rewards this weekend only.',
      timeRemaining: '1d 14h left',
      route: canonicalArenaRoute,
    ),
    newsItem: const SynaptixNewsItem(
      title: 'Synaptix news',
      body: 'New arcade challenges and dashboard upgrades are rolling out.',
      route: canonicalLabsRoute,
    ),
    dailyReward: SynaptixRewardPrompt(
      title: 'Daily reward',
      body: remainingRewards > 0
          ? '$remainingRewards account rewards waiting.'
          : 'Come back tomorrow for more rewards.',
      route: remainingRewards > 0 ? canonicalRewardsRoute : canonicalStoreRoute,
      icon: Icons.card_giftcard_rounded,
    ),
    friends: const [
      SynaptixFriendPreview(initials: 'A', color: SynaptixHomeTheme.purple),
      SynaptixFriendPreview(initials: 'B', color: SynaptixHomeTheme.blue),
      SynaptixFriendPreview(initials: 'C', color: SynaptixHomeTheme.green),
      SynaptixFriendPreview(initials: 'D', color: SynaptixHomeTheme.amber),
      SynaptixFriendPreview(initials: 'E', color: SynaptixHomeTheme.orange),
    ],
    profileIncomplete:
        onboardingProgress.completed && !onboardingProgress.hasCompletedProfile,
    remainingAccountRewards: remainingRewards,
  );
});

String _playerTitle(int level) {
  if (level >= 30) return 'Knowledge Architect';
  if (level >= 15) return 'Trivia Strategist';
  if (level >= 5) return 'Rising Challenger';
  return 'New Challenger';
}

String _rankTierFor(int level) {
  if (level >= 30) return 'Grandmaster I';
  if (level >= 20) return 'Master II';
  if (level >= 10) return 'Scholar III';
  return 'Rookie I';
}

List<SynaptixHomeMission> _missionsFor({
  required List<String> preferredCategories,
  required int recentCount,
  required int remainingRewards,
}) {
  return [
    SynaptixHomeMission(
      icon: Icons.quiz_rounded,
      title: 'Play 3 quiz rounds',
      current: recentCount.clamp(0, 3).toInt(),
      target: 3,
      rewardCoins: 150,
    ),
    SynaptixHomeMission(
      icon: Icons.category_rounded,
      title: 'Pick 3 favorite categories',
      current: preferredCategories.length.clamp(0, 3).toInt(),
      target: 3,
      rewardCoins: 100,
    ),
    SynaptixHomeMission(
      icon: Icons.card_giftcard_rounded,
      title: 'Claim account rewards',
      current: accountRewardDefinitions.length - remainingRewards,
      target: accountRewardDefinitions.length,
      rewardCoins: 250,
    ),
  ];
}

List<SynaptixHomeLeaderboardEntry> _leaderboardFor(SynaptixHomePlayer player) {
  final playerScore = player.currentXp + player.coins ~/ 10;
  return [
    const SynaptixHomeLeaderboardEntry(
      rank: 1,
      username: 'Daily Champion',
      score: 3200,
    ),
    const SynaptixHomeLeaderboardEntry(
      rank: 2,
      username: 'Study Streak',
      score: 2850,
    ),
    const SynaptixHomeLeaderboardEntry(
      rank: 3,
      username: 'Arcade Ace',
      score: 2420,
    ),
    SynaptixHomeLeaderboardEntry(
      rank: playerScore >= 2420 ? 3 : 24,
      username: player.handle,
      score: playerScore,
      isCurrentUser: true,
    ),
  ];
}

List<SynaptixRecommendation> _recommendationsFor(List<String> categories) {
  final category = categories.isNotEmpty ? categories.first : 'General';
  return [
    SynaptixRecommendation(
      icon: Icons.auto_awesome_rounded,
      title: '$category practice',
      subtitle: 'Keep momentum in your selected focus area.',
      route:
          categories.isEmpty ? '/all-categories' : '/category-quiz/$category',
    ),
    const SynaptixRecommendation(
      icon: Icons.calendar_month_rounded,
      title: 'Daily quiz',
      subtitle: 'A fresh set for today.',
      route: '/daily-quiz',
    ),
    const SynaptixRecommendation(
      icon: Icons.storefront_rounded,
      title: 'Rewards store',
      subtitle: 'Spend coins or review unlocks.',
      route: canonicalStoreRoute,
    ),
  ];
}

List<SynaptixAchievement> _achievementsFor({
  required int level,
  required List<String> preferredCategories,
  required int remainingRewards,
}) {
  return [
    SynaptixAchievement(
      icon: Icons.workspace_premium_rounded,
      title: 'Level $level',
      subtitle: 'Current rank',
    ),
    SynaptixAchievement(
      icon: Icons.category_rounded,
      title: '${preferredCategories.length}',
      subtitle: 'Focus areas',
    ),
    SynaptixAchievement(
      icon: Icons.card_giftcard_rounded,
      title: '${accountRewardDefinitions.length - remainingRewards}',
      subtitle: 'Rewards claimed',
    ),
  ];
}
