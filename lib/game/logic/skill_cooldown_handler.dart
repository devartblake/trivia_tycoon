class SkillCooldownHandler {
  final Map<String, DateTime> _cooldowns = {};

  bool isOnCooldown(String skillId) {
    final expiry = _cooldowns[skillId];
    return expiry != null && DateTime.now().isBefore(expiry);
  }

  Duration? remaining(String skillId) {
    final expiry = _cooldowns[skillId];
    if (expiry == null || DateTime.now().isAfter(expiry)) return null;
    return expiry.difference(DateTime.now());
  }

  void setCooldown(String skillId, Duration duration) {
    _cooldowns[skillId] = DateTime.now().add(duration);
  }

  void clearCooldown(String skillId) {
    _cooldowns.remove(skillId);
  }

  void resetAll() {
    _cooldowns.clear();
  }
}
