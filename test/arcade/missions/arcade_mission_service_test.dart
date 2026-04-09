import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_difficulty.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_game_id.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_result.dart';
import 'package:trivia_tycoon/arcade/missions/arcade_mission_catalog.dart';
import 'package:trivia_tycoon/arcade/missions/arcade_mission_models.dart';
import 'package:trivia_tycoon/arcade/missions/arcade_mission_service.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ArcadeResult _run({
  ArcadeGameId gameId = ArcadeGameId.quickMathRush,
  ArcadeDifficulty difficulty = ArcadeDifficulty.normal,
  int score = 100,
  bool isNewPb = false,
}) =>
    ArcadeResult(
      gameId: gameId,
      difficulty: difficulty,
      score: score,
      duration: const Duration(seconds: 60),
      metadata: {'isNewPb': isNewPb},
    );

ArcadeMissionService _buildService(AppCacheService cache, {String seasonId = 'season_test'}) {
  return ArcadeMissionService(cache, seasonId: seasonId);
}

void main() {
  late Directory tempDir;
  late AppCacheService cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mission_service_test');
    Hive.init(tempDir.path);
    cache = await AppCacheService.initialize();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('cache');
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Initial load
  // ---------------------------------------------------------------------------

  group('ArcadeMissionService initial load', () {
    test('loads missions from local catalog on fresh start', () {
      final svc = _buildService(cache);
      expect(svc.missions, isNotEmpty);
    });

    test('isReady is true after construction', () {
      final svc = _buildService(cache);
      expect(svc.isReady, isTrue);
    });

    test('missions include daily, weekly, and season tiers', () {
      final svc = _buildService(cache);
      final tiers = svc.missions.map((m) => m.tier).toSet();
      expect(tiers, containsAll([
        ArcadeMissionTier.daily,
        ArcadeMissionTier.weekly,
        ArcadeMissionTier.season,
      ]));
    });

    test('progressFor returns zero progress for all missions initially', () {
      final svc = _buildService(cache);
      for (final m in svc.missions) {
        final p = svc.progressFor(m.id);
        expect(p.current, 0);
        expect(p.claimed, isFalse);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // progressFor — default
  // ---------------------------------------------------------------------------

  group('ArcadeMissionService.progressFor', () {
    test('returns zero progress for unknown mission id', () {
      final svc = _buildService(cache);
      final p = svc.progressFor('does_not_exist');
      expect(p.current, 0);
      expect(p.claimed, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // onArcadeRunCompleted — playRuns
  // ---------------------------------------------------------------------------

  group('ArcadeMissionService.onArcadeRunCompleted (playRuns)', () {
    test('increments playRuns progress by 1 per run', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.playRuns && m.gameId == null,
      );

      svc.onArcadeRunCompleted(_run());
      expect(svc.progressFor(mission.id).current, 1);

      svc.onArcadeRunCompleted(_run());
      expect(svc.progressFor(mission.id).current, 2);
    });

    test('increments game-specific playRuns only for matching gameId', () {
      final svc = _buildService(cache);

      // Find a playRuns mission restricted to a specific game (if any)
      final gameMissions = svc.missions.where(
        (m) => m.type == ArcadeMissionType.playRuns && m.gameId != null,
      ).toList();

      if (gameMissions.isNotEmpty) {
        final mission = gameMissions.first;
        final wrongGame = ArcadeGameId.values.firstWhere(
          (g) => g != mission.gameId,
        );

        svc.onArcadeRunCompleted(_run(gameId: wrongGame));
        expect(svc.progressFor(mission.id).current, 0);

        svc.onArcadeRunCompleted(_run(gameId: mission.gameId!));
        expect(svc.progressFor(mission.id).current, 1);
      }
    });

    test('progress does not exceed mission target', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.playRuns && m.gameId == null,
      );

      // Run far more times than the target
      for (int i = 0; i < mission.target + 5; i++) {
        svc.onArcadeRunCompleted(_run());
      }

      expect(svc.progressFor(mission.id).current, mission.target);
    });
  });

  // ---------------------------------------------------------------------------
  // onArcadeRunCompleted — scoreAtLeast
  // ---------------------------------------------------------------------------

  group('ArcadeMissionService.onArcadeRunCompleted (scoreAtLeast)', () {
    test('sets progress to target when score meets threshold', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.scoreAtLeast,
      );

      svc.onArcadeRunCompleted(_run(
        gameId: mission.gameId ?? ArcadeGameId.quickMathRush,
        score: mission.target,
      ));

      expect(svc.progressFor(mission.id).current, mission.target);
    });

    test('does not advance progress when score is below threshold', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.scoreAtLeast,
      );

      svc.onArcadeRunCompleted(_run(
        gameId: mission.gameId ?? ArcadeGameId.quickMathRush,
        score: mission.target - 1,
      ));

      expect(svc.progressFor(mission.id).current, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // onArcadeRunCompleted — setNewPb
  // ---------------------------------------------------------------------------

  group('ArcadeMissionService.onArcadeRunCompleted (setNewPb)', () {
    test('increments setNewPb progress when isNewPb=true', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.setNewPb,
      );

      svc.onArcadeRunCompleted(_run(isNewPb: true));
      expect(svc.progressFor(mission.id).current, greaterThan(0));
    });

    test('does not advance setNewPb progress when isNewPb=false', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.setNewPb,
      );

      svc.onArcadeRunCompleted(_run(isNewPb: false));
      expect(svc.progressFor(mission.id).current, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // canClaim / tryClaim
  // ---------------------------------------------------------------------------

  group('ArcadeMissionService.canClaim', () {
    test('returns false when progress is below target', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.playRuns && m.gameId == null,
      );
      expect(svc.canClaim(mission.id), isFalse);
    });

    test('returns true when progress reaches target', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.playRuns && m.gameId == null,
      );

      for (int i = 0; i < mission.target; i++) {
        svc.onArcadeRunCompleted(_run());
      }

      expect(svc.canClaim(mission.id), isTrue);
    });
  });

  group('ArcadeMissionService.tryClaim', () {
    late ArcadeMissionService svc;
    late ArcadeMission mission;

    setUp(() {
      svc = _buildService(cache);
      mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.playRuns && m.gameId == null,
      );
      // Complete the mission
      for (int i = 0; i < mission.target; i++) {
        svc.onArcadeRunCompleted(_run());
      }
    });

    test('returns true on first successful claim', () {
      expect(svc.tryClaim(mission.id), isTrue);
    });

    test('marks mission as claimed', () {
      svc.tryClaim(mission.id);
      expect(svc.progressFor(mission.id).claimed, isTrue);
    });

    test('returns false on second claim (anti-double-claim)', () {
      svc.tryClaim(mission.id);
      expect(svc.tryClaim(mission.id), isFalse);
    });

    test('claimed mission no longer allows progress updates', () {
      svc.tryClaim(mission.id);
      final progressBefore = svc.progressFor(mission.id).current;

      svc.onArcadeRunCompleted(_run());

      expect(svc.progressFor(mission.id).current, progressBefore);
    });

    test('returns false when mission is not yet complete', () {
      final incompleteMission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.scoreAtLeast,
      );
      // Do NOT complete it
      expect(svc.tryClaim(incompleteMission.id), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // markClaimed (UI compatibility method)
  // ---------------------------------------------------------------------------

  group('ArcadeMissionService.markClaimed', () {
    test('is safe to call when mission is already claimed', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.playRuns && m.gameId == null,
      );
      for (int i = 0; i < mission.target; i++) {
        svc.onArcadeRunCompleted(_run());
      }
      svc.tryClaim(mission.id);
      // Second call should not throw
      svc.markClaimed(mission.id);
      expect(svc.progressFor(mission.id).claimed, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // progressRatio
  // ---------------------------------------------------------------------------

  group('ArcadeMissionService.progressRatio', () {
    test('returns 0.0 before any progress', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.playRuns && m.gameId == null,
      );
      expect(svc.progressRatio(mission.id), 0.0);
    });

    test('returns 1.0 when mission is complete', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.playRuns && m.gameId == null,
      );
      for (int i = 0; i < mission.target; i++) {
        svc.onArcadeRunCompleted(_run());
      }
      expect(svc.progressRatio(mission.id), 1.0);
    });

    test('clamps above 1.0 even if progress somehow exceeds target', () {
      final svc = _buildService(cache);
      final mission = svc.missions.firstWhere(
        (m) => m.type == ArcadeMissionType.playRuns && m.gameId == null,
      );
      for (int i = 0; i < mission.target + 10; i++) {
        svc.onArcadeRunCompleted(_run());
      }
      expect(svc.progressRatio(mission.id), lessThanOrEqualTo(1.0));
    });
  });

  // ---------------------------------------------------------------------------
  // missionsForTier
  // ---------------------------------------------------------------------------

  group('ArcadeMissionService.missionsForTier', () {
    test('returns only daily missions', () {
      final svc = _buildService(cache);
      final daily = svc.missionsForTier(ArcadeMissionTier.daily);
      expect(daily.every((m) => m.tier == ArcadeMissionTier.daily), isTrue);
    });

    test('returns only weekly missions', () {
      final svc = _buildService(cache);
      final weekly = svc.missionsForTier(ArcadeMissionTier.weekly);
      expect(weekly.every((m) => m.tier == ArcadeMissionTier.weekly), isTrue);
    });

    test('returns only season missions', () {
      final svc = _buildService(cache);
      final season = svc.missionsForTier(ArcadeMissionTier.season);
      expect(season.every((m) => m.tier == ArcadeMissionTier.season), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // mergeById policy
  // ---------------------------------------------------------------------------

  group('ArcadeMissionService mergeById policy', () {
    test('remote missions override local by id', () async {
      final remote = _FakeRemote([
        ArcadeMission(
          id: 'daily_play_runs_3', // same id as local catalog
          tier: ArcadeMissionTier.daily,
          type: ArcadeMissionType.playRuns,
          title: 'Remote Override',
          subtitle: 'Custom subtitle',
          target: 10, // different target
          reward: const ArcadeMissionReward(coins: 999, gems: 9),
        ),
      ]);

      final svc = ArcadeMissionService(
        cache,
        remote: remote,
        remotePolicy: ArcadeMissionRemotePolicy.mergeById,
        seasonId: 'season_test',
      );

      // Cache remote missions first
      await svc.refreshFromBackend();

      final overridden = svc.missions.firstWhere(
        (m) => m.id == 'daily_play_runs_3',
      );
      expect(overridden.title, 'Remote Override');
      expect(overridden.target, 10);
    });

    test('preferLocal policy ignores remote missions', () async {
      final remote = _FakeRemote([
        ArcadeMission(
          id: 'daily_play_runs_3',
          tier: ArcadeMissionTier.daily,
          type: ArcadeMissionType.playRuns,
          title: 'Remote Should Be Ignored',
          subtitle: '',
          target: 99,
          reward: const ArcadeMissionReward(coins: 1, gems: 0),
        ),
      ]);

      final svc = ArcadeMissionService(
        cache,
        remote: remote,
        remotePolicy: ArcadeMissionRemotePolicy.preferLocal,
        seasonId: 'season_test',
      );

      await svc.refreshFromBackend();

      final localMission = svc.missions.firstWhere(
        (m) => m.id == 'daily_play_runs_3',
      );
      // Local catalog has target=3 for this mission
      expect(localMission.target, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // ArcadeMission serialisation
  // ---------------------------------------------------------------------------

  group('ArcadeMission serialisation', () {
    test('round-trips through toJson / fromJson', () {
      const original = ArcadeMission(
        id: 'test_mission',
        tier: ArcadeMissionTier.weekly,
        type: ArcadeMissionType.setNewPb,
        title: 'Test',
        subtitle: 'Sub',
        target: 5,
        reward: ArcadeMissionReward(coins: 100, gems: 2, xp: 50),
        gameId: ArcadeGameId.memoryFlip,
        seasonId: 'season_1',
      );

      final rt = ArcadeMission.fromJson(original.toJson());

      expect(rt.id, original.id);
      expect(rt.tier, original.tier);
      expect(rt.type, original.type);
      expect(rt.target, original.target);
      expect(rt.reward.coins, original.reward.coins);
      expect(rt.reward.gems, original.reward.gems);
      expect(rt.reward.xp, original.reward.xp);
      expect(rt.gameId, original.gameId);
      expect(rt.seasonId, original.seasonId);
    });

    test('fromJson handles backend-friendly tier/type aliases', () {
      final m = ArcadeMission.fromJson({
        'id': 'alias_test',
        'tier': 'seasonal', // alias for 'season'
        'type': 'score_at_least', // alias for 'scoreAtLeast'
        'title': 'Alias',
        'subtitle': 'Sub',
        'target': 1000,
        'reward': {'coins': 50, 'gems': 0},
      });
      expect(m.tier, ArcadeMissionTier.season);
      expect(m.type, ArcadeMissionType.scoreAtLeast);
    });

    test('fromJson handles unknown tier/type gracefully (defaults)', () {
      final m = ArcadeMission.fromJson({
        'id': 'fallback_test',
        'tier': 'unknown_tier',
        'type': 'unknown_type',
        'title': 'T',
        'subtitle': 'S',
        'target': 1,
        'reward': {},
      });
      expect(m.tier, ArcadeMissionTier.daily);      // default
      expect(m.type, ArcadeMissionType.playRuns);   // default
    });
  });

  // ---------------------------------------------------------------------------
  // ArcadeMissionProgress serialisation
  // ---------------------------------------------------------------------------

  group('ArcadeMissionProgress serialisation', () {
    test('round-trips through toJson / fromJson', () {
      const original = ArcadeMissionProgress(
        missionId: 'm1',
        current: 3,
        claimed: true,
        claimedAtUtcIso: '2026-04-09T10:00:00Z',
      );

      final rt = ArcadeMissionProgress.fromJson(original.toJson());
      expect(rt.missionId, original.missionId);
      expect(rt.current, original.current);
      expect(rt.claimed, original.claimed);
      expect(rt.claimedAtUtcIso, original.claimedAtUtcIso);
    });

    test('copyWith produces correct update', () {
      const p = ArcadeMissionProgress(missionId: 'x', current: 1, claimed: false);
      final updated = p.copyWith(current: 5, claimed: true);
      expect(updated.missionId, 'x');
      expect(updated.current, 5);
      expect(updated.claimed, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ArcadeMissionCatalog
  // ---------------------------------------------------------------------------

  group('ArcadeMissionCatalog', () {
    test('allMissions contains daily + weekly + season entries', () {
      final all = ArcadeMissionCatalog.allMissions(seasonId: 'sv1');
      final tiers = all.map((m) => m.tier).toSet();
      expect(tiers, containsAll([
        ArcadeMissionTier.daily,
        ArcadeMissionTier.weekly,
        ArcadeMissionTier.season,
      ]));
    });

    test('all mission ids are unique', () {
      final all = ArcadeMissionCatalog.allMissions(seasonId: 'sv1');
      final ids = all.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('season missions include the seasonId in their id', () {
      final season = ArcadeMissionCatalog.seasonMissions(seasonId: 'sv1');
      for (final m in season) {
        expect(m.id, contains('sv1'));
      }
    });

    test('all missions have positive targets', () {
      final all = ArcadeMissionCatalog.allMissions(seasonId: 'sv1');
      for (final m in all) {
        expect(m.target, greaterThan(0));
      }
    });

    test('all missions have non-empty title and subtitle', () {
      final all = ArcadeMissionCatalog.allMissions(seasonId: 'sv1');
      for (final m in all) {
        expect(m.title, isNotEmpty);
        expect(m.subtitle, isNotEmpty);
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Fake remote source for policy tests
// ---------------------------------------------------------------------------

class _FakeRemote implements ArcadeMissionRemoteSource {
  final List<ArcadeMission> _missions;
  _FakeRemote(this._missions);

  @override
  Future<List<ArcadeMission>> fetchMissions({required String seasonId}) async {
    return _missions;
  }
}
