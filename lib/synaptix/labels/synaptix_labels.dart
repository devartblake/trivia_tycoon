import '../mode/synaptix_mode.dart';

/// Centralized display-label mapper for the Synaptix rebrand.
///
/// Internal names (route keys, provider names, persistence keys) are NEVER
/// changed. Only user-facing display strings go through this class.
///
/// Usage:
/// ```dart
/// final label = SynaptixLabels.surface('leaderboard', mode);
/// ```
///
/// Fallback chain: mode-specific -> teen default -> raw internal name.
class SynaptixLabels {
  SynaptixLabels._();

  // ---- Surface / section labels ----

  /// Returns the Synaptix-facing display label for a product surface.
  static String surface(String internalName, SynaptixMode mode) {
    return _surfaceLabels[internalName]?[mode] ??
        _surfaceLabels[internalName]?[SynaptixMode.teen] ??
        internalName;
  }

  static const _surfaceLabels = <String, Map<SynaptixMode, String>>{
    'leaderboard': {
      SynaptixMode.kids: 'Top Players',
      SynaptixMode.teen: 'Arena',
      SynaptixMode.adult: 'Arena',
    },
    'arcade': {
      SynaptixMode.kids: 'Labs',
      SynaptixMode.teen: 'Labs',
      SynaptixMode.adult: 'Labs',
    },
    'skill_tree': {
      SynaptixMode.kids: 'Pathways',
      SynaptixMode.teen: 'Neural Pathways',
      SynaptixMode.adult: 'Pathways',
    },
    'profile': {
      SynaptixMode.kids: 'My Journey',
      SynaptixMode.teen: 'Journey',
      SynaptixMode.adult: 'Journey',
    },
    'messages': {
      SynaptixMode.kids: 'Circles',
      SynaptixMode.teen: 'Circles',
      SynaptixMode.adult: 'Circles',
    },
    'admin': {
      SynaptixMode.kids: 'Command',
      SynaptixMode.teen: 'Command',
      SynaptixMode.adult: 'Synaptix Command',
    },
  };

  // ---- Skill tree / Pathway track labels ----

  /// Returns the Synaptix-facing display label for a skill tree branch.
  static String pathwayTrack(String internalBranch) {
    return _branchLabels[internalBranch] ?? internalBranch;
  }

  static const _branchLabels = <String, String>{
    'logic': 'Cognition',
    'strategy': 'Strategy',
    'speed': 'Momentum',
    'memory': 'Recall',
    'accuracy': 'Precision',
    'knowledge': 'Insight',
    'support': 'Support',
    'upgrades': 'Enhancements',
  };

  // ---- Economy labels ----

  /// Returns the Synaptix-facing display label for an economy term.
  static String economy(String internalTerm, SynaptixMode mode) {
    return _economyLabels[internalTerm]?[mode] ??
        _economyLabels[internalTerm]?[SynaptixMode.teen] ??
        internalTerm;
  }

  static const _economyLabels = <String, Map<SynaptixMode, String>>{
    'coins': {
      SynaptixMode.kids: 'Credits',
      SynaptixMode.teen: 'Credits',
      SynaptixMode.adult: 'Credits',
    },
    'gems': {
      SynaptixMode.kids: 'Shards',
      SynaptixMode.teen: 'Synapse Shards',
      SynaptixMode.adult: 'Synapse Shards',
    },
    'energy': {
      SynaptixMode.kids: 'Focus',
      SynaptixMode.teen: 'Cognitive Energy',
      SynaptixMode.adult: 'Focus',
    },
    'lives': {
      SynaptixMode.kids: 'Lives',
      SynaptixMode.teen: 'Attempts',
      SynaptixMode.adult: 'Attempts',
    },
    'xp': {
      SynaptixMode.kids: 'XP',
      SynaptixMode.teen: 'Neural XP',
      SynaptixMode.adult: 'XP',
    },
    'power_ups': {
      SynaptixMode.kids: 'Enhancements',
      SynaptixMode.teen: 'Enhancements',
      SynaptixMode.adult: 'Enhancements',
    },
    'daily_bonus': {
      SynaptixMode.kids: 'Daily Reward',
      SynaptixMode.teen: 'Daily Signal',
      SynaptixMode.adult: 'Daily Reward',
    },
  };
}
