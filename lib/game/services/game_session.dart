import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/services/profile_service.dart';
import 'package:trivia_tycoon/game/services/skill_cooldown_service.dart';

import '../../core/manager/tier_manager.dart';
import '../providers/riverpod_providers.dart';
import '../state/tier_update_result.dart';

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
    debugPrint('GameSession: addCoins($amount)'); // TODO: persist/add to profile currency
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
