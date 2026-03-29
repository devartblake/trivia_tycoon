/// Maps every skill effect key to a human-readable emoji + string.
///
/// Administrative keys (duration, speedDuration, etc.) are intentionally
/// omitted from the public [label] method — they return an empty string so
/// callers can filter them out with `isEmpty`.
class SkillEffectLabels {
  SkillEffectLabels._();

  /// Returns a human-readable label for the given effect [key] and [value].
  /// Returns an empty string for internal/administrative keys that should
  /// not be shown in the UI.
  static String label(String key, num value) {
    switch (key) {
    // ── Time ──────────────────────────────────────────────────────────
      case 'timeBonusSec':
        return '⏱ +${value.toInt()}s per question';
      case 'freezeTimer':
        return '❄️ Freeze timer this question';
      case 'speedBonus':
        return '⚡ ×$value speed score bonus';

    // ── XP / Score ────────────────────────────────────────────────────
      case 'xpBoost':
        return '⭐ +${(value * 100).toInt()}% XP gain';
      case 'bonusXP':
        return '⭐ +${value.toInt()} XP awarded';
      case 'scoreMultiplier':
        return '💯 ×$value score multiplier';
      case 'globalScoreBonus':
        return '💯 +${(value * 100).toInt()}% score (timed)';
      case 'allCategoryBonus':
        return '📚 +${(value * 100).toInt()}% all categories';
      case 'categoryBonus':
        return '📚 +${(value * 100).toInt()}% chosen category';
      case 'accuracyBonus':
        return '🎯 +${(value * 100).toInt()}% accuracy bonus';
      case 'sportsScoreBoost':
        return '🏆 +${(value * 100).toInt()}% sports score';

    // ── Streak ────────────────────────────────────────────────────────
      case 'streakMult':
        return '🔥 ×$value streak multiplier';
      case 'streakBoost':
        return '🔥 +${value.toInt()} streak count';
      case 'startingStreak':
        return '🔥 Begin with +${value.toInt()} streak';
      case 'streakProtection':
        return '🛡️ Streak shield ×${value.toInt()}';

    // ── Answer manipulation ───────────────────────────────────────────
      case 'eliminateOneWrong':
        return '✂️ Eliminate one wrong answer';
      case 'eliminateHalfWrong':
        return '✂️ Eliminate half wrong answers';
      case 'extraHints':
        return '💡 Auto-show hints';
      case 'retryWrongAnswer':
        return '🔄 Retry on wrong answer';
      case 'autoCorrectChance':
        return '🍀 ${(value * 100).toInt()}% auto-correct chance';
      case 'doubleOrNothing':
        return '🎰 Double score or lose it all';

    // ── Coins / economy ───────────────────────────────────────────────
      case 'giftPoints':
        return '🎁 Award ${value.toInt()} coins';
      case 'lifelineCooldownReduction':
        return '⏰ −${value.toInt()}s lifeline cooldown';

    // ── Access ────────────────────────────────────────────────────────
      case 'eliteAccess':
        return '⚡ Elite mode unlocked';
      case 'masterKnowledge':
        return '🎓 Master knowledge unlocked';
      case 'masterTactics':
        return '🧠 Master tactics unlocked';
      case 'selectableCategory':
        return '🗂️ Choose your category';
      case 'hardBonus':
        return '💎 Bonus on hard questions';

    // ── Stealth / opponents ──────────────────────────────────────────
      case 'glitchScreens':
        return '👾 Glitch opponents\' screens';
      case 'hideProgress':
        return '🫥 Hide progress from opponents';
      case 'fakeScore':
        return '🎭 Show fake score to opponents';

    // ── Chaos / wildcard ─────────────────────────────────────────────
      case 'periodicChaos':
        return '🌪️ Chaos every ${value.toInt()} questions';
      case 'randomBenefit':
        return '🎲 Random bonus at game start';

    // ── Administrative keys — intentionally invisible ─────────────────
      case 'duration':
      case 'speedDuration':
      case 'cooldownSec':
        return '';

      default:
        return '$key: $value';
    }
  }

  /// Returns true if [key] is an administrative/internal key that should
  /// not be shown in the effects list UI.
  static bool isHidden(String key) =>
      key == 'duration' || key == 'speedDuration' || key == 'cooldownSec';
}
