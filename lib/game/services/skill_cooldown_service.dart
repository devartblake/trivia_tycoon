import 'package:flutter_riverpod/flutter_riverpod.dart';

class SkillCooldownService {
  final Map<String, DateTime> _expiry = {};

  /// Check if a skill is still cooling down.
  bool isOnCooldown(String skillId) {
    final end = _expiry[skillId];
    return end != null && DateTime.now().isBefore(end);
  }

  /// Start/restart a cooldown for a skill.
  void startCooldown(String skillId, Duration cooldownDuration) {
    _expiry[skillId] = DateTime.now().add(cooldownDuration);
  }

  /// Optional helper: remaining time
  Duration? remaining(String skillId) {
    final end = _expiry[skillId];
    if (end == null) return null;
    final rem = end.difference(DateTime.now());
    return rem.isNegative ? Duration.zero : rem;
  }

  /// Shorten an active cooldown on a specific skill by [reduction].
  void reduceCooldown(String skillId, Duration reduction) {
    final end = _expiry[skillId];
    if (end != null) {
      final reduced = end.subtract(reduction);
      _expiry[skillId] = reduced.isBefore(DateTime.now()) ? DateTime.now() : reduced;
    }
  }

  /// Shorten ALL active cooldowns by [reduction] (used by lifelineCooldownReduction).
  void applyGlobalReduction(Duration reduction) {
    final now = DateTime.now();
    for (final key in _expiry.keys.toList()) {
      final reduced = _expiry[key]!.subtract(reduction);
      _expiry[key] = reduced.isBefore(now) ? now : reduced;
    }
  }

  void clear(String skillId) => _expiry.remove(skillId);
  void resetAll() => _expiry.clear();
}

final skillCooldownServiceProvider = Provider<SkillCooldownService>((ref) {
  return SkillCooldownService();
});
