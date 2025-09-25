import 'package:flutter/material.dart';
import '../../game/models/tier_model.dart';
import '../../game/state/tier_update_result.dart';
import '../services/settings/general_key_value_storage_service.dart';
import '../services/settings/player_profile_service.dart';

class TierManager {
  final GeneralKeyValueStorageService _storage;
  final PlayerProfileService _profileService;

  static const String _tierProgressKey = 'tier_progress';
  static const String _currentTierKey = 'current_tier';
  static const String _unlockedTiersKey = 'unlocked_tiers';

  TierManager(this._storage, this._profileService);

  // Default tier definitions
  static final List<TierModel> _defaultTiers = [
    TierModel(
      id: 0,
      name: 'Bronze Rookie',
      description: 'Starting your trivia journey',
      icon: Icons.emoji_events,
      primaryColor: const Color(0xFFCD7F32),
      secondaryColor: const Color(0xFFA0522D),
      requiredXP: 0,
      requiredLevel: 1,
      rewards: ['Welcome Badge', '100 Coins'],
    ),
    TierModel(
      id: 1,
      name: 'Silver Scholar',
      description: 'Knowledge is growing',
      icon: Icons.star_border,
      primaryColor: const Color(0xFFC0C0C0),
      secondaryColor: const Color(0xFF808080),
      requiredXP: 500,
      requiredLevel: 5,
      rewards: ['Scholar Badge', '250 Coins', '5 Gems'],
    ),
    TierModel(
      id: 2,
      name: 'Gold Master',
      description: 'True mastery achieved',
      icon: Icons.star,
      primaryColor: const Color(0xFFFFD700),
      secondaryColor: const Color(0xFFFFA500),
      requiredXP: 1200,
      requiredLevel: 10,
      rewards: ['Master Badge', '500 Coins', '15 Gems'],
    ),
    TierModel(
      id: 3,
      name: 'Platinum Elite',
      description: 'Among the elite players',
      icon: Icons.shield,
      primaryColor: const Color(0xFFE5E4E2),
      secondaryColor: const Color(0xFFB8B8B8),
      requiredXP: 2500,
      requiredLevel: 18,
      rewards: ['Elite Badge', '1000 Coins', '30 Gems'],
    ),
    TierModel(
      id: 4,
      name: 'Diamond Legend',
      description: 'Legendary knowledge',
      icon: Icons.diamond,
      primaryColor: const Color(0xFFB9F2FF),
      secondaryColor: const Color(0xFF87CEEB),
      requiredXP: 5000,
      requiredLevel: 25,
      rewards: ['Legend Badge', '2000 Coins', '50 Gems'],
    ),
    TierModel(
      id: 5,
      name: 'Master Sage',
      description: 'Wisdom beyond measure',
      icon: Icons.workspace_premium,
      primaryColor: const Color(0xFF6A0DAD),
      secondaryColor: const Color(0xFF4B0082),
      requiredXP: 10000,
      requiredLevel: 35,
      rewards: ['Sage Badge', '5000 Coins', '100 Gems'],
    ),
    TierModel(
      id: 6,
      name: 'Grandmaster',
      description: 'Peak of trivia mastery',
      icon: Icons.military_tech,
      primaryColor: const Color(0xFFDC143C),
      secondaryColor: const Color(0xFF8B0000),
      requiredXP: 20000,
      requiredLevel: 50,
      rewards: ['Grandmaster Badge', '10000 Coins', '200 Gems'],
    ),
    TierModel(
      id: 7,
      name: 'Champion',
      description: 'Ultimate trivia champion',
      icon: Icons.emoji_events_outlined,
      primaryColor: const Color(0xFFFF4500),
      secondaryColor: const Color(0xFFFF6347),
      requiredXP: 35000,
      requiredLevel: 75,
      rewards: ['Champion Badge', '20000 Coins', '500 Gems'],
    ),
    TierModel(
      id: 8,
      name: 'Elite Overlord',
      description: 'Beyond mortal comprehension',
      icon: Icons.workspace_premium_outlined,
      primaryColor: const Color(0xFFFF1493),
      secondaryColor: const Color(0xFFFF69B4),
      requiredXP: 50000,
      requiredLevel: 100,
      rewards: ['Overlord Badge', '50000 Coins', '1000 Gems'],
    ),
    TierModel(
      id: 9,
      name: 'Trivia Tycoon',
      description: 'The ultimate trivia tycoon',
      icon: Icons.monetization_on_outlined,
      primaryColor: const Color(0xFF008B8B),
      secondaryColor: const Color(0xFF20B2AA),
      requiredXP: 100000,
      requiredLevel: 150,
      rewards: ['Tycoon Badge', '100000 Coins', '2000 Gems', 'Exclusive Avatar'],
    ),
  ];

  /// Get all tiers with current unlock status
  Future<List<TierModel>> getAllTiers() async {
    final profile = _profileService.getProfile();
    final currentXP = profile['currentXP'] ?? 0;
    final currentLevel = profile['level'] ?? 1;

    final unlockedTierIds = await _getUnlockedTierIds();
    final currentTierId = await getCurrentTierId();

    return _defaultTiers.map((tier) {
      final isUnlocked = _isTierUnlocked(tier, currentXP, currentLevel) ||
          unlockedTierIds.contains(tier.id);
      final isCurrent = tier.id == currentTierId;

      return tier.copyWith(
        isUnlocked: isUnlocked,
        isCurrent: isCurrent,
      );
    }).toList();
  }

  /// Get current tier ID
  Future<int> getCurrentTierId() async {
    final stored = await _storage.getInt(_currentTierKey);
    if (stored != null) return stored;

    // Calculate based on XP/Level if not stored
    final profile = _profileService.getProfile();
    final currentXP = profile['currentXP'] ?? 0;
    final currentLevel = profile['level'] ?? 1;

    return _calculateCurrentTier(currentXP, currentLevel);
  }

  /// Calculate current tier based on XP and level
  int _calculateCurrentTier(int xp, int level) {
    int currentTier = 0;

    for (int i = _defaultTiers.length - 1; i >= 0; i--) {
      final tier = _defaultTiers[i];
      if (xp >= tier.requiredXP && level >= tier.requiredLevel) {
        currentTier = tier.id;
        break;
      }
    }

    return currentTier;
  }

  /// Check if player qualifies for tier unlock
  bool _isTierUnlocked(TierModel tier, int currentXP, int currentLevel) {
    return currentXP >= tier.requiredXP && currentLevel >= tier.requiredLevel;
  }

  /// Update tier progress and check for new unlocks
  Future<TierUpdateResult> updateTierProgress() async {
    final profile = _profileService.getProfile();
    final currentXP = profile['currentXP'] ?? 0;
    final currentLevel = profile['level'] ?? 1;

    final oldTierId = await getCurrentTierId();
    final newTierId = _calculateCurrentTier(currentXP, currentLevel);

    final newUnlocks = <TierModel>[];
    final unlockedIds = await _getUnlockedTierIds();

    // Check for newly unlocked tiers
    for (final tier in _defaultTiers) {
      if (!unlockedIds.contains(tier.id) &&
          _isTierUnlocked(tier, currentXP, currentLevel)) {
        newUnlocks.add(tier);
        unlockedIds.add(tier.id);
      }
    }

    // Save updated progress
    await _storage.setInt(_currentTierKey, newTierId);
    await _saveUnlockedTierIds(unlockedIds);

    return TierUpdateResult(
      oldTierId: oldTierId,
      newTierId: newTierId,
      tierChanged: oldTierId != newTierId,
      newUnlocks: newUnlocks,
    );
  }

  /// Get unlocked tier IDs
  Future<List<int>> _getUnlockedTierIds() async {
    final stored = await _storage.getString(_unlockedTiersKey);
    if (stored == null || stored.isEmpty) return [0]; // Bronze always unlocked

    return stored.split(',').map((id) => int.parse(id)).toList();
  }

  /// Save unlocked tier IDs
  Future<void> _saveUnlockedTierIds(List<int> tierIds) async {
    await _storage.setString(_unlockedTiersKey, tierIds.join(','));
  }

  /// Get tier by ID
  TierModel? getTierById(int id) {
    try {
      return _defaultTiers.firstWhere((tier) => tier.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get current tier model
  Future<TierModel?> getCurrentTier() async {
    final currentId = await getCurrentTierId();
    return getTierById(currentId);
  }

  /// Reset tier progress (for testing/admin)
  Future<void> resetTierProgress() async {
    await _storage.remove(_currentTierKey);
    await _storage.remove(_unlockedTiersKey);
  }

  /// Award tier rewards
  Future<void> awardTierRewards(TierModel tier) async {
    // Implement reward distribution logic here
    // This would interact with your currency manager, badge system, etc.

    // Example:
    // final currencyManager = ref.read(currencyManagerProvider);
    // Parse and award rewards from tier.rewards list
  }
}
