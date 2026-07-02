import 'package:flutter/material.dart';

/// Comprehensive tier definitions for the leaderboard and progression system
class TierDefinition {
  final int tier;
  final String name;
  final String tagline;
  final int requiredXp;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final TierReward reward;

  const TierDefinition({
    required this.tier,
    required this.name,
    required this.tagline,
    required this.requiredXp,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.reward,
  });

  /// Get human-readable XP requirement (e.g., "500 XP")
  String get xpDisplay => '$requiredXp XP';

  /// Get human-readable XP requirement with commas (e.g., "50,000 XP")
  String get xpDisplayFormatted {
    return '${requiredXp.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} XP';
  }
}

/// Tier rewards (coins, gems, badges)
class TierReward {
  final int coins;
  final int gems;
  final String? badgeName;
  final String? badgeDescription;

  const TierReward({
    required this.coins,
    required this.gems,
    this.badgeName,
    this.badgeDescription,
  });
}

/// All 10 tier definitions
final tierDefinitions = <int, TierDefinition>{
  1: TierDefinition(
    tier: 1,
    name: 'ROOKIE',
    tagline: 'Just Getting Started!',
    requiredXp: 0,
    primaryColor: const Color(0xFFC17447), // Bronze/Orange
    secondaryColor: const Color(0xFF4CAF50), // Green
    icon: Icons.school,
    reward: const TierReward(
      coins: 100,
      gems: 5,
      badgeName: 'Rookie Badge',
      badgeDescription: 'Welcome to trivia!',
    ),
  ),
  2: TierDefinition(
    tier: 2,
    name: 'CONTENDER',
    tagline: 'Building Knowledge!',
    requiredXp: 500,
    primaryColor: const Color(0xFF7C3AED), // Purple
    secondaryColor: const Color(0xFFC0C0C0), // Silver
    icon: Icons.shield,
    reward: const TierReward(
      coins: 250,
      gems: 15,
      badgeName: 'Contender Badge',
      badgeDescription: 'Knowledge is building!',
    ),
  ),
  3: TierDefinition(
    tier: 3,
    name: 'CHALLENGER',
    tagline: 'On the Rise!',
    requiredXp: 1200,
    primaryColor: const Color(0xFF2196F3), // Blue
    secondaryColor: const Color(0xFFFFD700), // Gold
    icon: Icons.star,
    reward: const TierReward(
      coins: 500,
      gems: 30,
      badgeName: 'Challenger Badge',
      badgeDescription: 'Rising through the ranks!',
    ),
  ),
  4: TierDefinition(
    tier: 4,
    name: 'EXPERT',
    tagline: 'Trivia Pro!',
    requiredXp: 2500,
    primaryColor: const Color(0xFFE53935), // Red
    secondaryColor: const Color(0xFFFFD700), // Gold
    icon: Icons.verified,
    reward: const TierReward(
      coins: 1000,
      gems: 50,
      badgeName: 'Expert Badge',
      badgeDescription: 'Trivia expertise achieved!',
    ),
  ),
  5: TierDefinition(
    tier: 5,
    name: 'MASTER',
    tagline: 'Master of Facts!',
    requiredXp: 5000,
    primaryColor: const Color(0xFF009688), // Teal
    secondaryColor: const Color(0xFFFFD700), // Gold
    icon: Icons.diamond,
    reward: const TierReward(
      coins: 2000,
      gems: 100,
      badgeName: 'Master Badge',
      badgeDescription: 'Facts are your domain!',
    ),
  ),
  6: TierDefinition(
    tier: 6,
    name: 'ELITE',
    tagline: 'Among the Best!',
    requiredXp: 10000,
    primaryColor: const Color(0xFF1976D2), // Deep Blue
    secondaryColor: const Color(0xFFFFD700), // Gold
    icon: Icons.emoji_events,
    reward: const TierReward(
      coins: 4000,
      gems: 200,
      badgeName: 'Elite Badge',
      badgeDescription: 'You are elite!',
    ),
  ),
  7: TierDefinition(
    tier: 7,
    name: 'LEGEND',
    tagline: 'Trivia Legend!',
    requiredXp: 20000,
    primaryColor: const Color(0xFFC2185B), // Deep Magenta/Purple
    secondaryColor: const Color(0xFFFFD700), // Gold
    icon: Icons.auto_awesome,
    reward: const TierReward(
      coins: 8000,
      gems: 400,
      badgeName: 'Legend Badge',
      badgeDescription: 'Legendary status unlocked!',
    ),
  ),
  8: TierDefinition(
    tier: 8,
    name: 'ICON',
    tagline: 'Iconic Mind!',
    requiredXp: 35000,
    primaryColor: const Color(0xFF0D47A1), // Bright Blue
    secondaryColor: const Color(0xFFE8F5E9), // Light Green/White
    icon: Icons.psychology,
    reward: const TierReward(
      coins: 15000,
      gems: 750,
      badgeName: 'Icon Badge',
      badgeDescription: 'Your mind is iconic!',
    ),
  ),
  9: TierDefinition(
    tier: 9,
    name: 'G.O.A.T.',
    tagline: 'Greatest of All Time!',
    requiredXp: 50000,
    primaryColor: const Color(0xFFFFA500), // Gold/Orange
    secondaryColor: const Color(0xFFFBFBFB), // Off-White
    icon: Icons.lightbulb,
    reward: const TierReward(
      coins: 25000,
      gems: 1500,
      badgeName: 'G.O.A.T. Badge',
      badgeDescription: 'Greatest of All Time!',
    ),
  ),
  10: TierDefinition(
    tier: 10,
    name: 'TRIVIA TYCOON',
    tagline: 'Unrivaled Champion!',
    requiredXp: 100000,
    primaryColor: const Color(0xFF7C3AED), // Purple/Violet
    secondaryColor: const Color(0xFFFFD700), // Gold
    icon: Icons.workspace_premium,
    reward: const TierReward(
      coins: 50000,
      gems: 5000,
      badgeName: 'Trivia Tycoon Crown',
      badgeDescription: 'Unrivaled champion status!',
    ),
  ),
};

/// Get tier definition by tier number
TierDefinition? getTierDefinition(int tier) {
  return tierDefinitions[tier];
}

/// Get all tier definitions as a list
List<TierDefinition> getAllTierDefinitions() {
  return List.generate(10, (i) => tierDefinitions[i + 1]!);
}

/// Get tier by name
TierDefinition? getTierDefinitionByName(String name) {
  try {
    return tierDefinitions.values.firstWhere(
      (t) => t.name.toUpperCase() == name.toUpperCase(),
    );
  } catch (e) {
    return null;
  }
}

/// Get next tier after current tier
TierDefinition? getNextTier(int currentTier) {
  if (currentTier >= 10) return null;
  return tierDefinitions[currentTier + 1];
}

/// Get previous tier before current tier
TierDefinition? getPreviousTier(int currentTier) {
  if (currentTier <= 1) return null;
  return tierDefinitions[currentTier - 1];
}

/// Calculate XP needed to reach next tier from current XP
int xpNeededForNextTier(int currentTier, int currentXp) {
  final nextTier = getNextTier(currentTier);
  if (nextTier == null) return 0;
  final remaining = nextTier.requiredXp - currentXp;
  return remaining > 0 ? remaining : 0;
}

/// Calculate progress percentage to next tier
double progressToNextTier(int currentTier, int currentXp) {
  final current = tierDefinitions[currentTier]!;
  final next = getNextTier(currentTier);

  if (next == null) return 1.0; // Already at max tier

  final tierStart = current.requiredXp;
  final tierEnd = next.requiredXp;
  final tierRange = tierEnd - tierStart;

  if (tierRange <= 0) return 0.0;

  final progress = (currentXp - tierStart) / tierRange;
  return progress.clamp(0.0, 1.0);
}
