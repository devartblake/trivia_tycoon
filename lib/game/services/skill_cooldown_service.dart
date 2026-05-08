class SkillCooldownService {
  final Map<String, DateTime> _expiry = {};

  /// Formats a duration as `mm:ss` with minutes not capped at 59.
  static String formatRemaining(Duration duration) {
    // Round up fractional seconds so active cooldowns don't display "00:00"
    // until the cooldown has actually expired.
    final totalSeconds = (duration.inMilliseconds + 999) ~/ 1000;
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

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

  /// Returns remaining cooldown in `mm:ss` format, or `00:00` when inactive.
  /// Minutes are not capped and may exceed 59 for long cooldowns.
  String remainingLabel(String skillId) {
    final rem = remaining(skillId);
    if (rem == null || rem == Duration.zero) return '00:00';
    return formatRemaining(rem);
  }

  /// Returns "Next available in mm:ss" while active; null when inactive.
  String? nextAvailableLabel(String skillId) {
    final rem = remaining(skillId);
    if (rem == null || rem == Duration.zero) return null;
    return 'Next available in ${formatRemaining(rem)}';
  }

  /// Returns "Next mm:ss" while active; null when inactive.
  String? nextAvailableChipLabel(String skillId) {
    final rem = remaining(skillId);
    if (rem == null || rem == Duration.zero) return null;
    return 'Next ${formatRemaining(rem)}';
  }

  /// Shorten an active cooldown on a specific skill by [reduction].
  void reduceCooldown(String skillId, Duration reduction) {
    final end = _expiry[skillId];
    if (end != null) {
      final reduced = end.subtract(reduction);
      _expiry[skillId] =
          reduced.isBefore(DateTime.now()) ? DateTime.now() : reduced;
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
