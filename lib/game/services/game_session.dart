import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/services/profile_service.dart';
import 'package:trivia_tycoon/game/services/skill_cooldown_service.dart';
import '../../core/manager/tier_manager.dart';
import '../providers/multi_profile_providers.dart';
import '../providers/riverpod_providers.dart';
import '../state/tier_update_result.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// GameSession composes ProfileService and SkillCooldownService.
/// Add session-wide, match-specific, or run-specific data here.
class GameSession {
  final ProfileService _profile;
  final SkillCooldownService _cooldowns;
  final TierManager _tierManager;

  GameSession({
    required ProfileService profile,
    required SkillCooldownService cooldowns,
    required TierManager tierManager,
  })  : _profile = profile,
        _cooldowns = cooldowns,
        _tierManager = tierManager;

  // Requested accessors:
  ProfileService getProfileService() => _profile;
  SkillCooldownService getSkillCooldownService() => _cooldowns;

  // Optional helpers used by effect handlers / controllers later:
  void addCoins(int amount) {
    LogManager.debug('GameSession: addCoins($amount)');

    try {
      // Get the coin balance notifier from Riverpod providers
      final coinNotifier = _profile.ref.read(coinBalanceProvider.notifier);
      coinNotifier.add(amount);

      // Also update the active profile's game stats to persist coins
      final profileManager = _profile.ref.read(profileManagerProvider.notifier);
      profileManager.updateActiveProfileGameStats({
        'coins': coinNotifier.state, // Update with new total
        'lastCoinUpdate': DateTime.now().toIso8601String(),
      });

      LogManager.debug('GameSession: Successfully added $amount coins. New total: ${coinNotifier.state}');
    } catch (e) {
      LogManager.debug('GameSession: Error adding coins: $e');
    }
  }

  void deductCoins(int amount) {
    LogManager.debug('GameSession: deductCoins($amount)');

    try {
      final coinNotifier = _profile.ref.read(coinBalanceProvider.notifier);
      if (coinNotifier.state >= amount) {
        coinNotifier.deduct(amount);

        // Update profile stats
        final profileManager = _profile.ref.read(profileManagerProvider.notifier);
        profileManager.updateActiveProfileGameStats({
          'coins': coinNotifier.state,
          'lastCoinUpdate': DateTime.now().toIso8601String(),
        });

        LogManager.debug('GameSession: Successfully deducted $amount coins. New total: ${coinNotifier.state}');
      } else {
        LogManager.debug('GameSession: Insufficient coins. Required: $amount, Available: ${coinNotifier.state}');
      }
    } catch (e) {
      LogManager.debug('GameSession: Error deducting coins: $e');
    }
  }

  void addGems(int amount) {
    LogManager.debug('GameSession: addGems($amount)');

    try {
      final gemNotifier = _profile.ref.read(diamondNotifierProvider);
      gemNotifier.addValue(amount);

      // Update profile stats
      final profileManager = _profile.ref.read(profileManagerProvider.notifier);
      profileManager.updateActiveProfileGameStats({
        'gems': gemNotifier.state, // Use 'state' instead of 'currentValue'
        'lastGemUpdate': DateTime.now().toIso8601String(),
      });

      LogManager.debug('GameSession: Successfully added $amount gems. New total: ${gemNotifier.state}');
    } catch (e) {
      LogManager.debug('GameSession: Error adding gems: $e');
    }
  }

  int getCurrentCoins() {
    return _profile.ref.read(coinBalanceProvider);
  }

  int getCurrentGems() {
    return _profile.ref.read(diamondBalanceProvider);
  }

  void unlockCategory(String name) {
    _profile.unlockCategory(name);
  }

  void increaseTimer(int seconds) {
    _profile.increaseTimer(seconds);
  }

  // New tier progression helper
  Future<TierUpdateResult> checkTierProgression() async {
    return await _tierManager.updateTierProgress();
  }
}

/// Provider that composes the services.
final gameSessionProvider = Provider<GameSession>((ref) {
  final profile = ref.read(profileServiceProvider);
  final cooldowns = ref.read(skillCooldownServiceProvider);
  final tierManager = ref.read(tierManagerProvider);
  return GameSession(
    profile: profile,
    cooldowns: cooldowns,
    tierManager: tierManager
  );
});
