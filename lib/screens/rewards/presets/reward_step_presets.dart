import 'package:flutter/material.dart';
import '../../../game/models/reward_step_models.dart';

/// Predefined reward step collections
class RewardStepPresets {
  static List<RewardStep> get dailySpinRewards => [
    const RewardStep(
      pointValue: 5,
      icon: Icons.inventory_2,
      backgroundColor: Color(0xFF795548),
      quantity: 1,
      description: 'Mystery Box',
      type: RewardType.mysteryBox,
    ),
    const RewardStep(
      pointValue: 20,
      icon: Icons.card_giftcard,
      backgroundColor: Color(0xFFFF9800),
      quantity: 1,
      description: 'Gift Card',
      type: RewardType.giftCard,
    ),
    const RewardStep(
      pointValue: 50,
      icon: Icons.monetization_on,
      backgroundColor: Color(0xFFFFA500),
      quantity: 300,
      description: 'Coins',
      type: RewardType.coins,
    ),
    const RewardStep(
      pointValue: 100,
      icon: Icons.card_giftcard,
      backgroundColor: Color(0xFFFF9800),
      quantity: 2,
      description: 'Premium Gift',
      type: RewardType.giftCard,
    ),
    const RewardStep(
      pointValue: 200,
      icon: Icons.monetization_on,
      backgroundColor: Color(0xFFFFA500),
      quantity: 500,
      description: 'Bonus Coins',
      type: RewardType.coins,
    ),
  ];

  static List<RewardStep> get levelUpRewards => [
    const RewardStep(
      pointValue: 10,
      icon: Icons.monetization_on,
      backgroundColor: Color(0xFFFFA500),
      quantity: 100,
      description: 'Coins',
      type: RewardType.coins,
    ),
    const RewardStep(
      pointValue: 25,
      icon: Icons.diamond,
      backgroundColor: Color(0xFF9C27B0),
      quantity: 10,
      description: 'Gems',
      type: RewardType.gems,
    ),
    const RewardStep(
      pointValue: 50,
      icon: Icons.flash_on,
      backgroundColor: Color(0xFF2196F3),
      quantity: 1,
      description: 'Power-Up',
      type: RewardType.powerUp,
    ),
    const RewardStep(
      pointValue: 100,
      icon: Icons.military_tech,
      backgroundColor: Color(0xFFF44336),
      quantity: 1,
      description: 'Badge',
      type: RewardType.badge,
    ),
    const RewardStep(
      pointValue: 250,
      icon: Icons.stars,
      backgroundColor: Color(0xFFFFD700),
      quantity: 1,
      description: 'Premium Access',
      type: RewardType.premiumAccess,
    ),
  ];

  static List<RewardStep> get achievementRewards => [
    const RewardStep(
      pointValue: 15,
      icon: Icons.trending_up,
      backgroundColor: Color(0xFF00BCD4),
      quantity: 1,
      description: 'XP Boost',
      type: RewardType.xpBoost,
    ),
    const RewardStep(
      pointValue: 30,
      icon: Icons.face,
      backgroundColor: Color(0xFF4CAF50),
      quantity: 1,
      description: 'Avatar',
      type: RewardType.avatar,
    ),
    const RewardStep(
      pointValue: 60,
      icon: Icons.palette,
      backgroundColor: Color(0xFFE91E63),
      quantity: 1,
      description: 'Theme',
      type: RewardType.theme,
    ),
  ];
}