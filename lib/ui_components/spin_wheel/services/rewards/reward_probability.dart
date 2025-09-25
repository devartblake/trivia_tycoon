import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../../../core/services/settings/app_settings.dart';
import '../../models/spin_system_models.dart';

/// Enhanced reward probability engine with advanced algorithms
class EnhancedRewardProbability {
  final RewardConfig config;
  final UserProfile userProfile;
  final math.Random _random;

  const EnhancedRewardProbability({
    required this.config,
    required this.userProfile,
    required math.Random random,
  }) : _random = random;

  EnhancedRewardProbability.withDefaultRandom({
    required this.config,
    required this.userProfile,
  }) : _random = math.Random();

  /// Calculate dynamic probabilities based on user profile
  RewardProbabilities calculateProbabilities() {
    final baseProbabilities = config.baseProbabilities;

    // Apply user level modifiers
    final levelModifier = _calculateLevelModifier();

    // Apply streak modifiers
    final streakModifier = _calculateStreakModifier();

    // Apply jackpot cooldown
    final jackpotModifier = _calculateJackpotModifier();

    // Apply exclusive currency bonuses
    final currencyModifier = _calculateCurrencyModifier();

    // Apply pity timer for rare rewards
    final pityModifier = _calculatePityModifier();

    // Calculate final probabilities
    double jackpotChance = math.max(
        config.minimumJackpotChance,
        baseProbabilities.jackpot *
            jackpotModifier *
            currencyModifier *
            streakModifier *
            pityModifier
    );

    double rareChance = baseProbabilities.rare *
        levelModifier *
        streakModifier;

    double uncommonChance = baseProbabilities.uncommon *
        levelModifier;

    double commonChance = baseProbabilities.common;

    // Normalize probabilities to ensure they sum to 1.0
    return _normalizeProbabilities(RewardProbabilities(
      jackpot: jackpotChance,
      rare: rareChance,
      uncommon: uncommonChance,
      common: commonChance,
    ));
  }

  /// Calculate level-based modifier
  double _calculateLevelModifier() {
    // Higher levels get slightly better rewards
    return 1.0 + (userProfile.level * config.levelBonusMultiplier);
  }

  /// Calculate streak-based modifier
  double _calculateStreakModifier() {
    if (userProfile.winStreak <= 0) return 1.0;

    // Gradual improvement with diminishing returns
    return 1.0 + math.min(
        userProfile.winStreak * config.streakBonusMultiplier,
        config.maxStreakBonus
    );
  }

  /// Calculate jackpot cooldown modifier
  double _calculateJackpotModifier() {
    if (userProfile.lastJackpotWin == null) return 1.0;

    final timeSinceJackpot = DateTime.now().difference(userProfile.lastJackpotWin!);
    final cooldownHours = config.jackpotCooldownHours;

    if (timeSinceJackpot.inHours < cooldownHours) {
      // Reduce jackpot chance during cooldown
      final cooldownProgress = timeSinceJackpot.inHours / cooldownHours;
      return config.jackpotCooldownReduction +
          (1.0 - config.jackpotCooldownReduction) * cooldownProgress;
    }

    return 1.0;
  }

  /// Calculate exclusive currency modifier
  double _calculateCurrencyModifier() {
    if (userProfile.exclusiveCurrency <= 0) return 1.0;

    // Logarithmic scaling to prevent excessive bonuses
    return 1.0 + math.min(
        math.log(userProfile.exclusiveCurrency + 1) * config.currencyBonusMultiplier,
        config.maxCurrencyBonus
    );
  }

  /// Calculate pity timer modifier for rare rewards
  double _calculatePityModifier() {
    if (userProfile.spinsSinceLastRare <= config.pityTimerThreshold) return 1.0;

    // Exponential increase after pity threshold
    final excessSpins = userProfile.spinsSinceLastRare - config.pityTimerThreshold;
    return 1.0 + (excessSpins * config.pityTimerMultiplier);
  }

  /// Normalize probabilities to sum to 1.0
  RewardProbabilities _normalizeProbabilities(RewardProbabilities probs) {
    final total = probs.jackpot + probs.rare + probs.uncommon + probs.common;

    if (total <= 0) {
      // Fallback to default distribution
      return const RewardProbabilities(
        jackpot: 0.02,
        rare: 0.08,
        uncommon: 0.30,
        common: 0.60,
      );
    }

    return RewardProbabilities(
      jackpot: probs.jackpot / total,
      rare: probs.rare / total,
      uncommon: probs.uncommon / total,
      common: probs.common / total,
    );
  }

  /// Execute spin and return reward type
  RewardType spin() {
    final probabilities = calculateProbabilities();
    final roll = _random.nextDouble();
    double cumulative = 0.0;

    // Check in order of rarity (rarest first)
    cumulative += probabilities.jackpot;
    if (roll < cumulative) return RewardType.jackpot;

    cumulative += probabilities.rare;
    if (roll < cumulative) return RewardType.rare;

    cumulative += probabilities.uncommon;
    if (roll < cumulative) return RewardType.uncommon;

    return RewardType.common;
  }

  /// Get detailed spin analysis for debugging
  SpinAnalysis analyzeSpinProbabilities() {
    final probabilities = calculateProbabilities();

    return SpinAnalysis(
      probabilities: probabilities,
      levelModifier: _calculateLevelModifier(),
      streakModifier: _calculateStreakModifier(),
      jackpotModifier: _calculateJackpotModifier(),
      currencyModifier: _calculateCurrencyModifier(),
      pityModifier: _calculatePityModifier(),
      userProfile: userProfile,
    );
  }
}

/// Reward configuration settings
@immutable
class RewardConfig {
  final RewardProbabilities baseProbabilities;
  final double minimumJackpotChance;
  final double levelBonusMultiplier;
  final double streakBonusMultiplier;
  final double maxStreakBonus;
  final double currencyBonusMultiplier;
  final double maxCurrencyBonus;
  final int jackpotCooldownHours;
  final double jackpotCooldownReduction;
  final int pityTimerThreshold;
  final double pityTimerMultiplier;

  const RewardConfig({
    this.baseProbabilities = const RewardProbabilities(
      jackpot: 0.02,
      rare: 0.08,
      uncommon: 0.30,
      common: 0.60,
    ),
    this.minimumJackpotChance = 0.005,
    this.levelBonusMultiplier = 0.002,
    this.streakBonusMultiplier = 0.005,
    this.maxStreakBonus = 0.05,
    this.currencyBonusMultiplier = 0.01,
    this.maxCurrencyBonus = 0.03,
    this.jackpotCooldownHours = 24,
    this.jackpotCooldownReduction = 0.1,
    this.pityTimerThreshold = 50,
    this.pityTimerMultiplier = 0.01,
  });

  /// Factory constructors for different difficulty modes
  factory RewardConfig.generous() {
    return const RewardConfig(
      baseProbabilities: RewardProbabilities(
        jackpot: 0.03,
        rare: 0.12,
        uncommon: 0.35,
        common: 0.50,
      ),
      levelBonusMultiplier: 0.003,
      streakBonusMultiplier: 0.008,
      maxStreakBonus: 0.08,
    );
  }

  factory RewardConfig.strict() {
    return const RewardConfig(
      baseProbabilities: RewardProbabilities(
        jackpot: 0.01,
        rare: 0.05,
        uncommon: 0.25,
        common: 0.69,
      ),
      levelBonusMultiplier: 0.001,
      streakBonusMultiplier: 0.003,
      maxStreakBonus: 0.03,
    );
  }

  factory RewardConfig.balanced() {
    return const RewardConfig(); // Uses default values
  }
}

/// Probability distribution for rewards
@immutable
class RewardProbabilities {
  final double jackpot;
  final double rare;
  final double uncommon;
  final double common;

  const RewardProbabilities({
    required this.jackpot,
    required this.rare,
    required this.uncommon,
    required this.common,
  });

  Map<String, double> toMap() {
    return {
      'jackpot': jackpot,
      'rare': rare,
      'uncommon': uncommon,
      'common': common,
    };
  }

  @override
  String toString() {
    return 'RewardProbabilities(jackpot: ${(jackpot * 100).toStringAsFixed(2)}%, '
        'rare: ${(rare * 100).toStringAsFixed(2)}%, '
        'uncommon: ${(uncommon * 100).toStringAsFixed(2)}%, '
        'common: ${(common * 100).toStringAsFixed(2)}%)';
  }
}

/// User profile for reward calculation
@immutable
class UserProfile {
  final int level;
  final int winStreak;
  final int exclusiveCurrency;
  final DateTime? lastJackpotWin;
  final int spinsSinceLastRare;
  final int totalSpins;

  const UserProfile({
    required this.level,
    required this.winStreak,
    required this.exclusiveCurrency,
    this.lastJackpotWin,
    required this.spinsSinceLastRare,
    required this.totalSpins,
  });

  factory UserProfile.defaultProfile() {
    return const UserProfile(
      level: 1,
      winStreak: 0,
      exclusiveCurrency: 0,
      spinsSinceLastRare: 0,
      totalSpins: 0,
    );
  }

  UserProfile copyWith({
    int? level,
    int? winStreak,
    int? exclusiveCurrency,
    DateTime? lastJackpotWin,
    int? spinsSinceLastRare,
    int? totalSpins,
  }) {
    return UserProfile(
      level: level ?? this.level,
      winStreak: winStreak ?? this.winStreak,
      exclusiveCurrency: exclusiveCurrency ?? this.exclusiveCurrency,
      lastJackpotWin: lastJackpotWin ?? this.lastJackpotWin,
      spinsSinceLastRare: spinsSinceLastRare ?? this.spinsSinceLastRare,
      totalSpins: totalSpins ?? this.totalSpins,
    );
  }
}

/// Reward types enum
enum RewardType {
  jackpot,
  rare,
  uncommon,
  common;

  String get displayName {
    switch (this) {
      case RewardType.jackpot:
        return 'Jackpot';
      case RewardType.rare:
        return 'Rare';
      case RewardType.uncommon:
        return 'Uncommon';
      case RewardType.common:
        return 'Common';
    }
  }

  Color get color {
    switch (this) {
      case RewardType.jackpot:
        return const Color(0xFFFFD700); // Gold
      case RewardType.rare:
        return const Color(0xFF8E44AD); // Purple
      case RewardType.uncommon:
        return const Color(0xFF3498DB); // Blue
      case RewardType.common:
        return const Color(0xFF27AE60); // Green
    }
  }
}

/// Analysis data for debugging and optimization
@immutable
class SpinAnalysis {
  final RewardProbabilities probabilities;
  final double levelModifier;
  final double streakModifier;
  final double jackpotModifier;
  final double currencyModifier;
  final double pityModifier;
  final UserProfile userProfile;

  const SpinAnalysis({
    required this.probabilities,
    required this.levelModifier,
    required this.streakModifier,
    required this.jackpotModifier,
    required this.currencyModifier,
    required this.pityModifier,
    required this.userProfile,
  });

  Map<String, dynamic> toMap() {
    return {
      'probabilities': probabilities.toMap(),
      'modifiers': {
        'level': levelModifier,
        'streak': streakModifier,
        'jackpot': jackpotModifier,
        'currency': currencyModifier,
        'pity': pityModifier,
      },
      'userProfile': {
        'level': userProfile.level,
        'winStreak': userProfile.winStreak,
        'exclusiveCurrency': userProfile.exclusiveCurrency,
        'spinsSinceLastRare': userProfile.spinsSinceLastRare,
        'totalSpins': userProfile.totalSpins,
      },
    };
  }
}

/// Enhanced reward service with comprehensive features
class EnhancedRewardService {
  final RewardConfig config;
  final Map<RewardType, List<WheelSegment>> _rewardPools;

  EnhancedRewardService({
    RewardConfig? config,
    Map<RewardType, List<WheelSegment>>? customRewardPools,
  }) : config = config ?? RewardConfig.balanced(),
        _rewardPools = customRewardPools ?? _createDefaultRewardPools();

  /// Generate reward based on enhanced probability system
  Future<RewardResult> generateReward() async {
    try {
      // Load user profile
      final userProfile = await _loadUserProfile();

      // Create probability engine
      final probabilityEngine = EnhancedRewardProbability.withDefaultRandom(
        config: config,
        userProfile: userProfile,
      );

      // Execute spin
      final rewardType = probabilityEngine.spin();

      // Select specific reward from pool
      final segment = _selectRewardFromPool(rewardType);

      // Update user profile
      await _updateUserProfile(userProfile, rewardType);

      // Check for badge unlocks
      await _checkBadgeUnlocks(userProfile);

      return RewardResult(
        segment: segment,
        rewardType: rewardType,
        probabilities: probabilityEngine.calculateProbabilities(),
        analysis: probabilityEngine.analyzeSpinProbabilities(),
      );
    } catch (e) {
      debugPrint('Failed to generate reward: $e');
      // Fallback to common reward
      return RewardResult(
        segment: _selectRewardFromPool(RewardType.common),
        rewardType: RewardType.common,
        probabilities: config.baseProbabilities,
        analysis: null,
      );
    }
  }

  /// Load user profile from storage
  Future<UserProfile> _loadUserProfile() async {
    final level = await AppSettings.getInt("userLevel") ?? 1;
    final winStreak = await AppSettings.getWinStreak() ?? 0;
    final exclusiveCurrency = await AppSettings.getInt("exclusiveCurrency") ?? 0;
    final lastJackpot = await AppSettings.getJackpotTime();
    final spinsSinceRare = await AppSettings.getInt("spinsSinceLastRare") ?? 0;
    final totalSpins = await AppSettings.getTotalSpins() ?? 0;

    return UserProfile(
      level: level,
      winStreak: winStreak,
      exclusiveCurrency: exclusiveCurrency,
      lastJackpotWin: lastJackpot,
      spinsSinceLastRare: spinsSinceRare,
      totalSpins: totalSpins,
    );
  }

  /// Update user profile after spin
  Future<void> _updateUserProfile(UserProfile profile, RewardType rewardType) async {
    // Update win streak
    final newStreak = rewardType != RewardType.common ? profile.winStreak + 1 : 0;
    await AppSettings.setWinStreak(newStreak);

    // Update jackpot time
    if (rewardType == RewardType.jackpot) {
      await AppSettings.setJackpotTime(DateTime.now());
    }

    // Update spins since last rare
    final spinsSinceRare = (rewardType == RewardType.rare || rewardType == RewardType.jackpot)
        ? 0
        : profile.spinsSinceLastRare + 1;
    await AppSettings.setInt("spinsSinceLastRare", spinsSinceRare);

    // Increment total spins
    await AppSettings.incrementTotalSpins();
  }

  /// Select reward from appropriate pool
  WheelSegment _selectRewardFromPool(RewardType rewardType) {
    final pool = _rewardPools[rewardType];
    if (pool == null || pool.isEmpty) {
      // Fallback to default reward
      return _createDefaultSegment(rewardType);
    }

    // Randomly select from pool
    final random = math.Random();
    return pool[random.nextInt(pool.length)];
  }

  /// Check and unlock badges based on achievements
  Future<void> _checkBadgeUnlocks(UserProfile profile) async {
    final achievements = <String>[];

    // Spin-based achievements
    if (profile.totalSpins >= 10) achievements.add("10-Spins");
    if (profile.totalSpins >= 50) achievements.add("50-Spins");
    if (profile.totalSpins >= 100) achievements.add("100-Spins");
    if (profile.totalSpins >= 500) achievements.add("500-Spins");

    // Streak-based achievements
    if (profile.winStreak >= 5) achievements.add("Streak-Champion");
    if (profile.winStreak >= 10) achievements.add("Streak-Master");
    if (profile.winStreak >= 20) achievements.add("Streak-Legend");

    // Level-based achievements
    if (profile.level >= 10) achievements.add("Level-10");
    if (profile.level >= 25) achievements.add("Level-25");
    if (profile.level >= 50) achievements.add("Level-50");

    // Unlock all earned badges
    for (final achievement in achievements) {
      await AppSettings.unlockBadge(achievement);
    }
  }

  /// Create default reward pools
  static Map<RewardType, List<WheelSegment>> _createDefaultRewardPools() {
    return {
      RewardType.jackpot: [
        _createSegment("Ultimate Diamond", RewardType.jackpot, 1000, "diamond.png", const Color(0xFFFFD700)),
        _createSegment("Mega Jackpot", RewardType.jackpot, 750, "mega_diamond.png", const Color(0xFFFFD700)),
        _createSegment("Super Prize", RewardType.jackpot, 500, "super_prize.png", const Color(0xFFFFD700)),
      ],
      RewardType.rare: [
        _createSegment("Gold Chest", RewardType.rare, 300, "gold_chest.png", const Color(0xFF8E44AD)),
        _createSegment("Rare Gem", RewardType.rare, 250, "rare_gem.png", const Color(0xFF8E44AD)),
        _createSegment("Crystal Box", RewardType.rare, 200, "crystal_box.png", const Color(0xFF8E44AD)),
      ],
      RewardType.uncommon: [
        _createSegment("Silver Crate", RewardType.uncommon, 150, "silver_crate.png", const Color(0xFF3498DB)),
        _createSegment("Magic Pouch", RewardType.uncommon, 120, "magic_pouch.png", const Color(0xFF3498DB)),
        _createSegment("Treasure Box", RewardType.uncommon, 100, "treasure_box.png", const Color(0xFF3498DB)),
      ],
      RewardType.common: [
        _createSegment("Coin Bag", RewardType.common, 75, "coin_bag.png", const Color(0xFF27AE60)),
        _createSegment("Small Prize", RewardType.common, 50, "small_prize.png", const Color(0xFF27AE60)),
        _createSegment("Bonus Coins", RewardType.common, 25, "bonus_coins.png", const Color(0xFF27AE60)),
      ],
    };
  }

  /// Create wheel segment helper
  static WheelSegment _createSegment(
      String label,
      RewardType rewardType,
      int reward,
      String imageName,
      Color color,
      ) {
    return WheelSegment(
      id: '${rewardType.name}_${label.toLowerCase().replaceAll(' ', '_')}',
      label: label,
      rewardType: rewardType.name,
      reward: reward,
      imagePath: "assets/images/$imageName",
      color: color,
    );
  }

  /// Create default segment fallback
  WheelSegment _createDefaultSegment(RewardType rewardType) {
    switch (rewardType) {
      case RewardType.jackpot:
        return _createSegment("Ultimate Prize", rewardType, 500, "default_jackpot.png", rewardType.color);
      case RewardType.rare:
        return _createSegment("Rare Prize", rewardType, 250, "default_rare.png", rewardType.color);
      case RewardType.uncommon:
        return _createSegment("Good Prize", rewardType, 100, "default_uncommon.png", rewardType.color);
      case RewardType.common:
        return _createSegment("Small Prize", rewardType, 50, "default_common.png", rewardType.color);
    }
  }

  /// Get current probability distribution for display
  Future<RewardProbabilities> getCurrentProbabilities() async {
    final userProfile = await _loadUserProfile();
    final engine = EnhancedRewardProbability.withDefaultRandom(
      config: config,
      userProfile: userProfile,
    );
    return engine.calculateProbabilities();
  }

  /// Simulate multiple spins for testing
  Future<Map<RewardType, int>> simulateSpins(int count) async {
    final userProfile = await _loadUserProfile();
    final engine = EnhancedRewardProbability.withDefaultRandom(
      config: config,
      userProfile: userProfile,
    );

    final results = <RewardType, int>{
      RewardType.jackpot: 0,
      RewardType.rare: 0,
      RewardType.uncommon: 0,
      RewardType.common: 0,
    };

    for (int i = 0; i < count; i++) {
      final result = engine.spin();
      results[result] = (results[result] ?? 0) + 1;
    }

    return results;
  }
}

/// Result of reward generation
@immutable
class RewardResult {
  final WheelSegment segment;
  final RewardType rewardType;
  final RewardProbabilities probabilities;
  final SpinAnalysis? analysis;

  const RewardResult({
    required this.segment,
    required this.rewardType,
    required this.probabilities,
    this.analysis,
  });
}