import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/synaptix/labels/synaptix_labels.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode.dart';

void main() {
  // -------------------------------------------------------------------------
  // surface()
  // -------------------------------------------------------------------------

  group('SynaptixLabels.surface', () {
    test('leaderboard: kids→Top Players, teen→Arena, adult→Arena', () {
      expect(SynaptixLabels.surface('leaderboard', SynaptixMode.kids),
          'Top Players');
      expect(SynaptixLabels.surface('leaderboard', SynaptixMode.teen), 'Arena');
      expect(
          SynaptixLabels.surface('leaderboard', SynaptixMode.adult), 'Arena');
    });

    test('arcade: all modes → Labs', () {
      for (final mode in SynaptixMode.values) {
        expect(SynaptixLabels.surface('arcade', mode), 'Labs');
      }
    });

    test('skill_tree: kids→Pathways, teen→Neural Pathways, adult→Pathways', () {
      expect(
          SynaptixLabels.surface('skill_tree', SynaptixMode.kids), 'Pathways');
      expect(SynaptixLabels.surface('skill_tree', SynaptixMode.teen),
          'Neural Pathways');
      expect(
          SynaptixLabels.surface('skill_tree', SynaptixMode.adult), 'Pathways');
    });

    test('profile: kids→My Journey, teen→Journey, adult→Journey', () {
      expect(
          SynaptixLabels.surface('profile', SynaptixMode.kids), 'My Journey');
      expect(SynaptixLabels.surface('profile', SynaptixMode.teen), 'Journey');
      expect(SynaptixLabels.surface('profile', SynaptixMode.adult), 'Journey');
    });

    test('messages: all modes → Circles', () {
      for (final mode in SynaptixMode.values) {
        expect(SynaptixLabels.surface('messages', mode), 'Circles');
      }
    });

    test('admin: kids→Command, teen→Command, adult→Synaptix Command', () {
      expect(SynaptixLabels.surface('admin', SynaptixMode.kids), 'Command');
      expect(SynaptixLabels.surface('admin', SynaptixMode.teen), 'Command');
      expect(SynaptixLabels.surface('admin', SynaptixMode.adult),
          'Synaptix Command');
    });

    test('unknown key returns raw internalName', () {
      // For a known key, teen fallback is the teen value itself (covered above)
      // For an unknown key, returns raw internalName
      expect(SynaptixLabels.surface('unknown_surface', SynaptixMode.kids),
          'unknown_surface');
    });

    test('unknown key with any mode returns the raw internal name', () {
      for (final mode in SynaptixMode.values) {
        expect(SynaptixLabels.surface('no_such_key', mode), 'no_such_key');
      }
    });
  });

  // -------------------------------------------------------------------------
  // pathwayTrack()
  // -------------------------------------------------------------------------

  group('SynaptixLabels.pathwayTrack', () {
    test('logic → Cognition', () {
      expect(SynaptixLabels.pathwayTrack('logic'), 'Cognition');
    });

    test('strategy → Strategy', () {
      expect(SynaptixLabels.pathwayTrack('strategy'), 'Strategy');
    });

    test('speed → Momentum', () {
      expect(SynaptixLabels.pathwayTrack('speed'), 'Momentum');
    });

    test('memory → Recall', () {
      expect(SynaptixLabels.pathwayTrack('memory'), 'Recall');
    });

    test('accuracy → Precision', () {
      expect(SynaptixLabels.pathwayTrack('accuracy'), 'Precision');
    });

    test('knowledge → Insight', () {
      expect(SynaptixLabels.pathwayTrack('knowledge'), 'Insight');
    });

    test('support → Support', () {
      expect(SynaptixLabels.pathwayTrack('support'), 'Support');
    });

    test('upgrades → Enhancements', () {
      expect(SynaptixLabels.pathwayTrack('upgrades'), 'Enhancements');
    });

    test('unknown branch returns raw internal name', () {
      expect(SynaptixLabels.pathwayTrack('unknown_branch'), 'unknown_branch');
    });
  });

  // -------------------------------------------------------------------------
  // economy()
  // -------------------------------------------------------------------------

  group('SynaptixLabels.economy', () {
    test('coins: all modes → Credits', () {
      for (final mode in SynaptixMode.values) {
        expect(SynaptixLabels.economy('coins', mode), 'Credits');
      }
    });

    test('gems: kids→Shards, teen→Synapse Shards, adult→Synapse Shards', () {
      expect(SynaptixLabels.economy('gems', SynaptixMode.kids), 'Shards');
      expect(
          SynaptixLabels.economy('gems', SynaptixMode.teen), 'Synapse Shards');
      expect(
          SynaptixLabels.economy('gems', SynaptixMode.adult), 'Synapse Shards');
    });

    test('energy: kids→Focus, teen→Cognitive Energy, adult→Focus', () {
      expect(SynaptixLabels.economy('energy', SynaptixMode.kids), 'Focus');
      expect(SynaptixLabels.economy('energy', SynaptixMode.teen),
          'Cognitive Energy');
      expect(SynaptixLabels.economy('energy', SynaptixMode.adult), 'Focus');
    });

    test('lives: kids→Lives, teen→Attempts, adult→Attempts', () {
      expect(SynaptixLabels.economy('lives', SynaptixMode.kids), 'Lives');
      expect(SynaptixLabels.economy('lives', SynaptixMode.teen), 'Attempts');
      expect(SynaptixLabels.economy('lives', SynaptixMode.adult), 'Attempts');
    });

    test('xp: kids→XP, teen→Neural XP, adult→XP', () {
      expect(SynaptixLabels.economy('xp', SynaptixMode.kids), 'XP');
      expect(SynaptixLabels.economy('xp', SynaptixMode.teen), 'Neural XP');
      expect(SynaptixLabels.economy('xp', SynaptixMode.adult), 'XP');
    });

    test('power_ups: all modes → Enhancements', () {
      for (final mode in SynaptixMode.values) {
        expect(SynaptixLabels.economy('power_ups', mode), 'Enhancements');
      }
    });

    test(
        'daily_bonus: kids→Daily Reward, teen→Daily Signal, adult→Daily Reward',
        () {
      expect(SynaptixLabels.economy('daily_bonus', SynaptixMode.kids),
          'Daily Reward');
      expect(SynaptixLabels.economy('daily_bonus', SynaptixMode.teen),
          'Daily Signal');
      expect(SynaptixLabels.economy('daily_bonus', SynaptixMode.adult),
          'Daily Reward');
    });

    test('unknown economy term returns raw internal name', () {
      expect(SynaptixLabels.economy('unknown_term', SynaptixMode.teen),
          'unknown_term');
    });
  });
}
