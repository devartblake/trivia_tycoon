import 'package:flutter/material.dart';
import '../models/challenge_models.dart';

/// Service for managing challenges
/// TODO: Replace with actual API calls or repository pattern
class ChallengeService {
  // Cache to avoid rebuilding data on every call
  static final Map<ChallengeType, ChallengeBundle> _cache = {};
  static DateTime? _lastCacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Get challenges for a specific type with caching
  static ChallengeBundle getChallenges(ChallengeType type) {
    final now = DateTime.now();

    // Check cache validity
    if (_lastCacheTime != null &&
        now.difference(_lastCacheTime!) < _cacheTimeout &&
        _cache.containsKey(type)) {
      return _cache[type]!;
    }

    // Generate new data
    final bundle = _generateChallengeBundle(type);
    _cache[type] = bundle;
    _lastCacheTime = now;

    return bundle;
  }

  /// Clear cache (call when challenges are updated)
  static void clearCache() {
    _cache.clear();
    _lastCacheTime = null;
  }

  /// Generate challenge bundle for a type
  static ChallengeBundle _generateChallengeBundle(ChallengeType type) {
    final now = DateTime.now();
    final refreshTime = _getRefreshTime(type, now);
    final challenges = _getChallengeList(type);

    return ChallengeBundle(
      challenges: challenges,
      refreshTime: refreshTime,
    );
  }

  /// Calculate refresh time based on challenge type
  static DateTime _getRefreshTime(ChallengeType type, DateTime from) {
    return switch (type) {
      ChallengeType.daily => from.add(const Duration(hours: 12)),
      ChallengeType.weekly => from.add(const Duration(days: 3)),
      ChallengeType.special => from.add(const Duration(hours: 40)),
    };
  }

  /// Get challenge list by type
  static List<Challenge> _getChallengeList(ChallengeType type) {
    return switch (type) {
      ChallengeType.daily => _getDailyChallenges(),
      ChallengeType.weekly => _getWeeklyChallenges(),
      ChallengeType.special => _getSpecialChallenges(),
    };
  }

  static List<Challenge> _getDailyChallenges() {
    return const [
      Challenge(
        id: 'd1',
        type: ChallengeType.daily,
        title: 'Time Attack',
        description: 'Answer 20 questions as fast as you can.',
        rewardSummary: '+150 XP • Power-Up Box',
        icon: Icons.flash_on_rounded,
        progress: 0.4,
        completed: false,
      ),
      Challenge(
        id: 'd2',
        type: ChallengeType.daily,
        title: 'Perfect Streak',
        description: 'Get 10 correct answers in a row.',
        rewardSummary: '"Flawless Mind" badge',
        icon: Icons.auto_fix_high_rounded,
        progress: 1.0,
        completed: true,
      ),
    ];
  }

  static List<Challenge> _getWeeklyChallenges() {
    return const [
      Challenge(
        id: 'w1',
        type: ChallengeType.weekly,
        title: 'Tier Gauntlet',
        description: 'Win 3 ranked duels against your tier.',
        rewardSummary: 'Promotion Token • +300 XP',
        icon: Icons.emoji_events_rounded,
        progress: 0.25,
        completed: false,
      ),
      Challenge(
        id: 'w2',
        type: ChallengeType.weekly,
        title: 'Category Master: History',
        description: 'Score 5000 points in History this week.',
        rewardSummary: 'Gold Box • Season Points',
        icon: Icons.history_edu_rounded,
        progress: 0.6,
        completed: false,
      ),
    ];
  }

  static List<Challenge> _getSpecialChallenges() {
    return const [
      Challenge(
        id: 's1',
        type: ChallengeType.special,
        title: 'Global Festival Quiz',
        description: 'Worldwide event: contribute to the mega score!',
        rewardSummary: 'Seasonal Title • Legendary Skin chance',
        icon: Icons.public_rounded,
        progress: 0.15,
        completed: false,
      ),
      Challenge(
        id: 's2',
        type: ChallengeType.special,
        title: 'Guild Showdown',
        description: 'Team vs Team over 7 days. Earn jackpot rewards.',
        rewardSummary: 'Guild Badge • +Coins for all',
        icon: Icons.groups_2_rounded,
        progress: 0.5,
        completed: false,
      ),
    ];
  }

  /// Update challenge progress
  /// TODO: Replace with actual API call
  static Future<Challenge> updateProgress(Challenge challenge, double newProgress) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API call
    clearCache(); // Invalidate cache when data changes
    return challenge.copyWith(
      progress: newProgress,
      completed: newProgress >= 1.0,
    );
  }
}
