import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_session.dart';
import '../services/xp_service.dart';
import '../services/profile_service.dart';
import '../services/skill_cooldown_service.dart';
import '../models/skill_tree_graph.dart';

class SkillEffectHandler {
  // Injected services
  final GameSession gameSession;
  final XPService xpService;
  final ProfileService profileService;
  final SkillCooldownService cooldownService;

  // Optional legacy dependencies (kept to avoid breaking call sites)
  final dynamic powerUpController;
  final dynamic achievementService;

  /// Primary constructor (preferred)
  SkillEffectHandler({
    required this.gameSession,
    required this.xpService,
    required this.profileService,
    required this.cooldownService,
    this.powerUpController,
    this.achievementService,
  });

  /// Legacy positional constructor to minimize breakage where this was used like:
  ///   SkillEffectHandler(ref.read(gameSessionProvider), ref.read(xpServiceProvider), ref.read(achievementServiceProvider), ref.read(powerUpControllerProvider))
  /// You may safely remove this when all call sites migrate to the named constructor or provider.
  SkillEffectHandler.legacy(
      this.gameSession,
      this.xpService,
      this.achievementService,
      this.powerUpController, {
        ProfileService? profileService,
        SkillCooldownService? cooldownService,
      })  : profileService = profileService ?? gameSession.getProfileService(),
        cooldownService = cooldownService ?? gameSession.getSkillCooldownService();

  // ---------------------------
  // Public API (compat friendly)
  // ---------------------------

  /// Old call sites used either `applySkillEffects(node)` or `applySkillEffects(node.effects)`.
  /// This dynamic wrapper supports both without forcing a rewrite.
  void applySkillEffects(dynamic arg) {
    if (arg is SkillNode) {
      _applyEffectMap(arg.effects);
    } else if (arg is Map<String, num>) {
      _applyEffectMap(arg);
    } else {
      debugPrint('[SkillEffectHandler] Unsupported argument to applySkillEffects: ${arg.runtimeType}');
    }
  }

  /// Newer, safer entry point. Performs gating (cooldown/use-cost) then applies effects.
  /// Returns true if the skill successfully triggered.
  bool triggerSkill(SkillNode node) {
    if (!node.unlocked) return false;

    // Cooldown handling via SkillCooldownService (duration read from effects if present)
    final cooldownSec = (node.effects['cooldownSec'] ?? 0).toInt();
    if (cooldownSec > 0 && cooldownService.isOnCooldown(node.id)) {
      return false;
    }

    // Optional use-cost (XP to activate skill AFTER unlock)
    final useXPCost = (node.effects['useXPCost'] ?? 0).toInt();
    if (useXPCost > 0 && !xpService.hasEnoughXP(useXPCost)) {
      return false;
    }

    // Deduct use cost (if any)
    if (useXPCost > 0) {
      xpService.deductXP(useXPCost);
    }

    // Apply all effects (administrative keys ignored inside)
    _applyEffectMap(node.effects);

    // Start cooldown (if any)
    if (cooldownSec > 0) {
      cooldownService.startCooldown(node.id, Duration(seconds: cooldownSec));
    }

    // Optional legacy hooks (analytics/achievements/etc.)
    try {
      achievementService?.logSkillUsed?.call(node.id);
    } catch (_) {/* ignore */}

    return true;
  }

  /// Convenience: inspect cooldown status for UI overlays.
  bool isOnCooldown(String nodeId) => cooldownService.isOnCooldown(nodeId);

  // ---------------------------
  // Internal helpers
  // ---------------------------

  void _applyEffectMap(Map<String, num> effects) {
    // Route each effect through a single, testable switch.
    for (final entry in effects.entries) {
      _applyEffect(entry.key, entry.value);
    }
  }

  /// The single source of truth for mapping effect keys to behavior.
  /// Keep this list additive; avoid spreading effect logic elsewhere.
  void _applyEffect(String key, num value) {
    switch (key) {
    // ---- Multipliers / XP economy ----
      case 'xpBoost':
      // Treat value as +% (0.10 => +10%). Convert to multiplier 1.1
        profileService.setXPBonusMultiplier(1.0 + value.toDouble());
        break;
      case 'bonusXP':
        profileService.addXP(value.toInt());
        break;

    // ---- Time / pacing ----
      case 'timeBonusSec':
        gameSession.increaseTimer(value.toInt());
        break;

    // ---- Category / access gating ----
      case 'unlockCategoryName':
      // If you later store category by string in effects2, prefer that over num.
        gameSession.unlockCategory(value.toString());
        break;

    // ---- Known gameplay knobs from your sample data ----
      case 'streakMult':
      // TODO route to a dedicated combo/streak system
        debugPrint('[SkillEffectHandler] streakMult=${value.toDouble()} (route to combo system)');
        break;

      case 'sportsScoreBoost':
      // TODO route to scoring model with category-specific multiplier
        debugPrint('[SkillEffectHandler] sportsScoreBoost=${value.toDouble()} (route to scoring)');
        break;

      case 'hardBonus':
      // TODO route to difficulty bonus logic
        debugPrint('[SkillEffectHandler] hardBonus=${value.toDouble()} (route to difficulty bonus)');
        break;

      case 'eliteAccess':
      // TODO route to feature flags / mode unlocks
        debugPrint('[SkillEffectHandler] eliteAccess=${value.toInt()} (route to mode unlocks)');
        break;

    // ---- Administrative keys: handled elsewhere, ignore here ----
      case 'cooldownSec':
      case 'useXPCost':
        break;

    // ---- Unknown / not yet implemented ----
      default:
      // Keep silent in release; verbose in debug for dev visibility.
        debugPrint('[SkillEffectHandler] Unknown effect: $key=$value');
        break;
    }
  }
}

// ---------------------------
// Provider (clean wiring)
// ---------------------------

final skillEffectHandlerProvider = Provider<SkillEffectHandler>((ref) {
  final session = ref.read(gameSessionProvider);
  return SkillEffectHandler(
    gameSession: session,
    profileService: session.getProfileService(),
    xpService: ref.read(xpServiceProvider),
    cooldownService: session.getSkillCooldownService(),
    // If you still have these in your project, they'll just be unused here:
    // achievementService: ref.read(achievementServiceProvider),
    // powerUpController: ref.read(powerUpControllerProvider),
  );
});
