import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/services/profile_service.dart';
import 'package:trivia_tycoon/game/services/skill_cooldown_service.dart';

/// GameSession composes ProfileService and SkillCooldownService.
/// Add session-wide, match-specific, or run-specific data here.
class GameSession {
  final ProfileService _profile;
  final SkillCooldownService _cooldowns;

  GameSession({
    required ProfileService profile,
    required SkillCooldownService cooldowns,
  })  : _profile = profile,
        _cooldowns = cooldowns;

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
}

/// Provider that composes the services.
final gameSessionProvider = Provider<GameSession>((ref) {
  final profile = ref.read(profileServiceProvider);
  final cooldowns = ref.read(skillCooldownServiceProvider);
  return GameSession(profile: profile, cooldowns: cooldowns);
});
