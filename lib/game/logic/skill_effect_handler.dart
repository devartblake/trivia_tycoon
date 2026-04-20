import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_bonus_providers.dart';
import '../providers/xp_provider.dart';
import '../services/game_session.dart';
import '../services/xp_service.dart';
import '../services/profile_service.dart';
import '../services/skill_cooldown_service.dart';
import '../models/skill_tree_graph.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class SkillEffectHandler {
  // Injected services
  final GameSession gameSession;
  final XPService xpService;
  final ProfileService profileService;
  final SkillCooldownService cooldownService;

  // Optional legacy dependencies (kept to avoid breaking call sites)
  final dynamic powerUpController;
  final dynamic achievementService;

  // Riverpod ref used to write to game-bonus providers
  final Ref? _ref;

  // Scratch-pad: populated for the duration of _applyEffectMap so sibling
  // effect values (e.g. speedDuration, duration) are accessible without
  // threading extra parameters through _applyEffect.
  Map<String, num> _currentEffects = {};

  /// Primary constructor (preferred)
  SkillEffectHandler({
    required this.gameSession,
    required this.xpService,
    required this.profileService,
    required this.cooldownService,
    this.powerUpController,
    this.achievementService,
    Ref? ref,
  }) : _ref = ref;

  /// Legacy positional constructor — kept so existing call-sites compile.
  SkillEffectHandler.legacy(
    this.gameSession,
    this.xpService,
    this.achievementService,
    this.powerUpController, {
    ProfileService? profileService,
    SkillCooldownService? cooldownService,
  })  : profileService = profileService ?? gameSession.getProfileService(),
        cooldownService =
            cooldownService ?? gameSession.getSkillCooldownService(),
        _ref = null;

  // ---------------------------
  // Public API (compat friendly)
  // ---------------------------

  void applySkillEffects(dynamic arg) {
    if (arg is SkillNode) {
      _applyEffectMap(arg.effects);
    } else if (arg is Map<String, num>) {
      _applyEffectMap(arg);
    } else {
      LogManager.debug(
          '[SkillEffectHandler] Unsupported argument: ${arg.runtimeType}');
    }
  }

  bool triggerSkill(SkillNode node) {
    if (!node.unlocked) return false;

    final cooldownSec = (node.effects['cooldownSec'] ?? 0).toInt();
    if (cooldownSec > 0 && cooldownService.isOnCooldown(node.id)) return false;

    final useXPCost = (node.effects['useXPCost'] ?? 0).toInt();
    if (useXPCost > 0 && !xpService.hasEnoughXP(useXPCost)) return false;

    if (useXPCost > 0) xpService.deductXP(useXPCost);

    _applyEffectMap(node.effects);

    if (cooldownSec > 0) {
      cooldownService.startCooldown(node.id, Duration(seconds: cooldownSec));
    }

    try {
      achievementService?.logSkillUsed?.call(node.id);
    } catch (_) {}

    return true;
  }

  bool isOnCooldown(String nodeId) => cooldownService.isOnCooldown(nodeId);

  // ---------------------------
  // Internal helpers
  // ---------------------------

  void _applyEffectMap(Map<String, num> effects) {
    _currentEffects = effects;
    for (final entry in effects.entries) {
      _applyEffect(entry.key, entry.value);
    }
    _currentEffects = {};
  }

  // ignore: long-method — this is intentionally a single routing switch
  void _applyEffect(String key, num value) {
    final r = _ref;
    switch (key) {
      // ================================================================
      // XP / economy
      // ================================================================

      case 'xpBoost':
        profileService.setXPBonusMultiplier(1.0 + value.toDouble());
        break;

      case 'bonusXP':
        profileService.addXP(value.toInt());
        break;

      case 'giftPoints':
        // Multiplayer: gift to opponent. Single-player: award to self as coins.
        gameSession.addCoins(value.toInt());
        LogManager.debug(
            '[SkillEffectHandler] giftPoints: +${value.toInt()} coins');
        break;

      // ================================================================
      // Score multipliers
      // ================================================================

      case 'scoreMultiplier':
        if (r != null) {
          final cur = r.read(scoreBonusMultiplierProvider);
          r.read(scoreBonusMultiplierProvider.notifier).state =
              cur * value.toDouble();
          LogManager.debug(
              '[SkillEffectHandler] scoreMultiplier ×${value.toDouble()}');
        }
        break;

      case 'globalScoreBonus':
        if (r != null) {
          final cur = r.read(scoreBonusMultiplierProvider);
          final bonus = 1.0 + value.toDouble();
          r.read(scoreBonusMultiplierProvider.notifier).state = cur * bonus;
          final durSec = (_currentEffects['duration'] ?? 20).toInt();
          Future.delayed(Duration(seconds: durSec), () {
            if (r.exists(scoreBonusMultiplierProvider)) {
              r.read(scoreBonusMultiplierProvider.notifier).state /= bonus;
            }
          });
          LogManager.debug(
              '[SkillEffectHandler] globalScoreBonus +${value.toDouble() * 100}% for ${durSec}s');
        }
        break;

      case 'allCategoryBonus':
        if (r != null) {
          final cur = r.read(scoreBonusMultiplierProvider);
          r.read(scoreBonusMultiplierProvider.notifier).state =
              cur * (1.0 + value.toDouble());
          LogManager.debug(
              '[SkillEffectHandler] allCategoryBonus +${value.toDouble() * 100}%');
        }
        break;

      case 'sportsScoreBoost':
        if (r != null) {
          final cur = r.read(scoreBonusMultiplierProvider);
          r.read(scoreBonusMultiplierProvider.notifier).state =
              cur * (1.0 + value.toDouble());
        }
        break;

      case 'hardBonus':
        if (r != null) {
          final cur = r.read(scoreBonusMultiplierProvider);
          r.read(scoreBonusMultiplierProvider.notifier).state =
              cur * (1.0 + value.toDouble());
        }
        break;

      case 'speedBonus':
        if (r != null) {
          final bonus = value.toDouble();
          final durSec = (_currentEffects['speedDuration'] ?? 20).toInt();
          final cur = r.read(speedBonusMultiplierProvider);
          r.read(speedBonusMultiplierProvider.notifier).state = cur * bonus;
          Future.delayed(Duration(seconds: durSec), () {
            if (r.exists(speedBonusMultiplierProvider)) {
              r.read(speedBonusMultiplierProvider.notifier).state /= bonus;
            }
          });
          LogManager.debug(
              '[SkillEffectHandler] speedBonus ×$bonus for ${durSec}s');
        }
        break;

      case 'accuracyBonus':
        if (r != null) {
          r.read(accuracyBonusProvider.notifier).state += value.toDouble();
          LogManager.debug(
              '[SkillEffectHandler] accuracyBonus +${value.toDouble() * 100}%');
        }
        break;

      // ================================================================
      // Streak
      // ================================================================

      case 'streakMult':
        if (r != null) {
          final cur = r.read(streakMultiplierProvider);
          r.read(streakMultiplierProvider.notifier).state =
              cur * value.toDouble();
        }
        break;

      case 'streakBoost':
        // Immediately increment the live streak counter by N.
        if (r != null) {
          r.read(streakCountProvider.notifier).state += value.toInt();
          LogManager.debug(
              '[SkillEffectHandler] streakBoost +${value.toInt()}');
        }
        break;

      case 'startingStreak':
        if (r != null) {
          r.read(streakCountProvider.notifier).state += value.toInt();
          LogManager.debug(
              '[SkillEffectHandler] startingStreak +${value.toInt()}');
        }
        break;

      case 'streakProtection':
        if (r != null) {
          r.read(streakShieldProvider.notifier).state += value.toInt();
          LogManager.debug(
              '[SkillEffectHandler] streakProtection shields: ${value.toInt()}');
        }
        break;

      // ================================================================
      // Timer
      // ================================================================

      case 'timeBonusSec':
        gameSession.increaseTimer(value.toInt());
        break;

      case 'freezeTimer':
        if (r != null && value.toInt() > 0) {
          r.read(timerFrozenProvider.notifier).state = true;
          LogManager.debug('[SkillEffectHandler] freezeTimer activated');
        }
        break;

      // ================================================================
      // Question manipulation
      // ================================================================

      case 'eliminateOneWrong':
        if (r != null && value.toInt() > 0) {
          r.read(pendingEliminateOneProvider.notifier).state = true;
          LogManager.debug('[SkillEffectHandler] eliminateOneWrong queued');
        }
        break;

      case 'eliminateHalfWrong':
        if (r != null && value.toInt() > 0) {
          r.read(pendingEliminateHalfProvider.notifier).state = true;
          LogManager.debug('[SkillEffectHandler] eliminateHalfWrong queued');
        }
        break;

      case 'extraHints':
        if (r != null) {
          r.read(pendingShowHintProvider.notifier).state = true;
          LogManager.debug(
              '[SkillEffectHandler] extraHints: hints enabled for all questions');
        }
        break;

      case 'retryWrongAnswer':
        if (r != null && value.toInt() > 0) {
          r.read(pendingRetryProvider.notifier).state = true;
          LogManager.debug('[SkillEffectHandler] retryWrongAnswer armed');
        }
        break;

      case 'autoCorrectChance':
        if (r != null) {
          final cur = r.read(autoCorrectChanceProvider);
          r.read(autoCorrectChanceProvider.notifier).state =
              (cur + value.toDouble()).clamp(0.0, 0.95);
          LogManager.debug(
              '[SkillEffectHandler] autoCorrectChance: ${(cur + value.toDouble()) * 100}%');
        }
        break;

      case 'hideAnswers':
        // Opponent visibility — handled by UI reading answersHiddenProvider.
        // Routing through hideProgressActiveProvider (same stealth bucket).
        if (r != null && value.toInt() > 0) {
          r.read(hideProgressActiveProvider.notifier).state = true;
        }
        break;

      case 'hintSpeedBonus':
        if (r != null) {
          r.read(hintSpeedBonusProvider.notifier).state += value.toInt();
          LogManager.debug(
              '[SkillEffectHandler] hintSpeedBonus +${value.toInt()}s');
        }
        break;

      case 'doubleOrNothing':
        if (r != null && value.toInt() > 0) {
          r.read(doubleOrNothingProvider.notifier).state = true;
          LogManager.debug('[SkillEffectHandler] doubleOrNothing activated');
        }
        break;

      // ================================================================
      // Category
      // ================================================================

      case 'categoryBonus':
        // Stored alongside selectableCategory; the player picks the category
        // via UI after selectableCategoryProvider becomes true.
        if (r != null) {
          final existing = r.read(categoryBonusProvider) ?? {};
          r.read(categoryBonusProvider.notifier).state = {
            ...existing,
            'bonus': (existing['bonus'] as double? ?? 0.0) + value.toDouble(),
          };
          LogManager.debug(
              '[SkillEffectHandler] categoryBonus +${value.toDouble() * 100}%');
        }
        break;

      case 'selectableCategory':
        if (r != null && value.toInt() > 0) {
          r.read(selectableCategoryProvider.notifier).state = true;
        }
        break;
      case 'unlockCategoryName':
        gameSession.unlockCategory(value.toString());
        break;

      // ================================================================
      // Access / elite flags
      // ================================================================

      case 'eliteAccess':
        if (r != null && value.toInt() > 0) {
          r.read(eliteAccessUnlockedProvider.notifier).state = true;
        }
        break;

      case 'masterKnowledge':
        if (r != null && value.toInt() > 0) {
          r.read(masterKnowledgeUnlockedProvider.notifier).state = true;
          LogManager.debug('[SkillEffectHandler] masterKnowledge unlocked');
        }
        break;

      case 'masterTactics':
        if (r != null && value.toInt() > 0) {
          r.read(masterTacticsUnlockedProvider.notifier).state = true;
          LogManager.debug('[SkillEffectHandler] masterTactics unlocked');
        }
        break;

      // ================================================================
      // Cooldown management
      // ================================================================

      case 'lifelineCooldownReduction':
        cooldownService.applyGlobalReduction(Duration(seconds: value.toInt()));
        LogManager.debug(
            '[SkillEffectHandler] lifelineCooldownReduction -${value.toInt()}s on all cooldowns');
        break;

      // ================================================================
      // UI / Stealth (multiplayer)
      // ================================================================

      case 'fakeScore':
        if (r != null && value.toInt() > 0) {
          r.read(fakeScoreActiveProvider.notifier).state = true;
        }
        break;

      case 'hideProgress':
        if (r != null && value.toInt() > 0) {
          r.read(hideProgressActiveProvider.notifier).state = true;
        }
        break;

      case 'glitchScreens':
        if (r != null && value.toInt() > 0) {
          r.read(glitchScreensActiveProvider.notifier).state = true;
          final durSec = (_currentEffects['duration'] ?? 10).toInt();
          Future.delayed(Duration(seconds: durSec), () {
            if (r.exists(glitchScreensActiveProvider)) {
              r.read(glitchScreensActiveProvider.notifier).state = false;
            }
          });
          LogManager.debug('[SkillEffectHandler] glitchScreens for ${durSec}s');
        }
        break;

      // ================================================================
      // Wildcard / chaos
      // ================================================================

      case 'periodicChaos':
        if (r != null) {
          r.read(periodicChaosIntervalProvider.notifier).state = value.toInt();
          LogManager.debug(
              '[SkillEffectHandler] periodicChaos every ${value.toInt()} questions');
        }
        break;

      case 'randomBenefit':
        if (r != null && value.toInt() > 0) {
          r.read(randomBenefitActiveProvider.notifier).state = true;
          LogManager.debug(
              '[SkillEffectHandler] randomBenefit will fire at game start');
        }
        break;

      // ================================================================
      // Administrative (consumed at call-sites, ignored in effect loop)
      // ================================================================

      case 'cooldownSec':
      case 'useXPCost':
      case 'speedDuration': // consumed by speedBonus via _currentEffects
      case 'duration': // consumed by globalScoreBonus/glitchScreens via _currentEffects
        break;

      // ================================================================
      // Unknown
      // ================================================================

      default:
        LogManager.debug('[SkillEffectHandler] Unhandled effect: $key=$value');
        break;
    }
  }
}

// ---------------------------
// Provider
// ---------------------------

final skillEffectHandlerProvider = Provider<SkillEffectHandler>((ref) {
  final session = ref.read(gameSessionProvider);
  return SkillEffectHandler(
    gameSession: session,
    profileService: session.getProfileService(),
    xpService: ref.read(xpServiceProvider),
    cooldownService: session.getSkillCooldownService(),
    ref: ref,
  );
});
