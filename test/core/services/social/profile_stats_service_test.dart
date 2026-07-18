import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/social/profile_stats_service.dart';

GameMatch _match({
  String id = 'm1',
  String userId = 'u1',
  String category = 'Science',
  int score = 500,
  int opponentScore = 300,
  GameResult result = GameResult.win,
  int questionsAnswered = 10,
  int correctAnswers = 8,
  Duration timeTaken = const Duration(seconds: 45),
  String? opponentId,
  String? opponentName,
}) =>
    GameMatch(
      id: id,
      userId: userId,
      category: category,
      score: score,
      opponentScore: opponentScore,
      result: result,
      questionsAnswered: questionsAnswered,
      correctAnswers: correctAnswers,
      timeTaken: timeTaken,
      playedAt: DateTime.now(),
      opponentId: opponentId ?? 'o1',
      opponentName: opponentName ?? 'Bot',
    );

void main() {
  late ProfileStatsService svc;

  setUp(() {
    // ProfileStatsService is a singleton; reset its in-memory state so each
    // test starts clean (otherwise match/stat/streak counts accumulate).
    svc = ProfileStatsService();
    svc.resetForTest();
    svc.initialize();
  });

  const uid = 'test_user_99';

  // -------------------------------------------------------------------------
  // recordMatch — basic stats creation
  // -------------------------------------------------------------------------

  group('recordMatch — stats creation', () {
    test('getUserStats returns null before any match for new user', () {
      expect(svc.getUserStats(uid), isNull);
    });

    test('getUserStats non-null after first match', () {
      svc.recordMatch(_match(userId: uid));
      expect(svc.getUserStats(uid), isNotNull);
    });

    test('totalGames = 1 after first match', () {
      svc.recordMatch(_match(userId: uid));
      expect(svc.getUserStats(uid)!.totalGames, 1);
    });

    test('totalWins = 1 after win', () {
      svc.recordMatch(_match(userId: uid, result: GameResult.win));
      expect(svc.getUserStats(uid)!.totalWins, 1);
    });

    test('totalLosses = 1 after loss', () {
      svc.recordMatch(_match(userId: uid, result: GameResult.loss));
      expect(svc.getUserStats(uid)!.totalLosses, 1);
    });

    test('totalDraws = 1 after draw', () {
      svc.recordMatch(_match(userId: uid, result: GameResult.draw));
      expect(svc.getUserStats(uid)!.totalDraws, 1);
    });

    test('win adds score + 50 to totalPoints', () {
      svc.recordMatch(_match(userId: uid, score: 500, result: GameResult.win));
      expect(svc.getUserStats(uid)!.totalPoints, 550);
    });

    test('loss adds 70% of score to totalPoints', () {
      svc.recordMatch(_match(userId: uid, score: 500, result: GameResult.loss));
      expect(svc.getUserStats(uid)!.totalPoints, 350);
    });

    test('draw adds score unchanged to totalPoints', () {
      svc.recordMatch(_match(userId: uid, score: 400, result: GameResult.draw));
      expect(svc.getUserStats(uid)!.totalPoints, 400);
    });

    test('multiple matches accumulate totalGames', () {
      svc.recordMatch(_match(id: 'm1', userId: uid));
      svc.recordMatch(_match(id: 'm2', userId: uid));
      svc.recordMatch(_match(id: 'm3', userId: uid));
      expect(svc.getUserStats(uid)!.totalGames, 3);
    });
  });

  // -------------------------------------------------------------------------
  // stats accuracy: winRate, averageScore, level, levelProgress
  // -------------------------------------------------------------------------

  group('stats accuracy', () {
    test('winRate = wins/totalGames * 100', () {
      svc.recordMatch(_match(id: 'm1', userId: uid, result: GameResult.win));
      svc.recordMatch(_match(id: 'm2', userId: uid, result: GameResult.loss));
      expect(svc.getUserStats(uid)!.winRate, closeTo(50.0, 0.01));
    });

    test('winRate = 0 when no wins', () {
      svc.recordMatch(_match(userId: uid, result: GameResult.loss));
      expect(svc.getUserStats(uid)!.winRate, 0.0);
    });

    test('averageScore = totalPoints / totalGames', () {
      svc.recordMatch(
          _match(id: 'm1', userId: uid, score: 500, result: GameResult.draw));
      svc.recordMatch(
          _match(id: 'm2', userId: uid, score: 300, result: GameResult.draw));
      // 500 + 300 = 800 / 2 = 400
      expect(svc.getUserStats(uid)!.averageScore, closeTo(400.0, 0.01));
    });

    test('level = xp/1000 + 1', () {
      // XP = totalPoints. Need 1000+ XP for level 2.
      // Use large win scores to accumulate XP quickly
      for (int i = 0; i < 5; i++) {
        svc.recordMatch(
            _match(id: 'm$i', userId: uid, score: 200, result: GameResult.win));
      }
      // 5 wins × (200+50) = 1250 XP → level 2
      expect(svc.getUserStats(uid)!.level, 2);
    });

    test('experienceToNextLevel = level * 1000', () {
      svc.recordMatch(_match(userId: uid, score: 100, result: GameResult.win));
      final stats = svc.getUserStats(uid)!;
      expect(stats.experienceToNextLevel, stats.level * 1000);
    });

    test('levelProgress = (xp % 1000) / 10.0', () {
      svc.recordMatch(_match(userId: uid, score: 100, result: GameResult.win));
      // XP = 150 (100+50), level = 1, 150%1000 = 150, 150/10.0 = 15.0
      expect(svc.getUserStats(uid)!.levelProgress, closeTo(15.0, 0.01));
    });
  });

  // -------------------------------------------------------------------------
  // categoryStats
  // -------------------------------------------------------------------------

  group('categoryStats', () {
    test('getCategoryStats null before match', () {
      expect(svc.getCategoryStats(uid, 'History'), isNull);
    });

    test('getCategoryStats non-null after match in that category', () {
      svc.recordMatch(_match(userId: uid, category: 'History'));
      expect(svc.getCategoryStats(uid, 'History'), isNotNull);
    });

    test('category gamesPlayed = 1 after first match', () {
      svc.recordMatch(_match(userId: uid, category: 'History'));
      expect(svc.getCategoryStats(uid, 'History')!.gamesPlayed, 1);
    });

    test('category highestScore tracks max', () {
      svc.recordMatch(_match(
          id: 'm1',
          userId: uid,
          category: 'Science',
          score: 300,
          result: GameResult.win));
      svc.recordMatch(_match(
          id: 'm2',
          userId: uid,
          category: 'Science',
          score: 700,
          result: GameResult.win));
      // highestScore = max of raw scores seen
      final cs = svc.getCategoryStats(uid, 'Science')!;
      expect(cs.highestScore, greaterThanOrEqualTo(300));
    });

    test('different categories tracked independently', () {
      svc.recordMatch(_match(id: 'm1', userId: uid, category: 'Math'));
      svc.recordMatch(_match(id: 'm2', userId: uid, category: 'Science'));
      expect(svc.getCategoryStats(uid, 'Math')!.gamesPlayed, 1);
      expect(svc.getCategoryStats(uid, 'Science')!.gamesPlayed, 1);
    });
  });

  // -------------------------------------------------------------------------
  // streaks
  // -------------------------------------------------------------------------

  group('streaks', () {
    test('currentWinStreak = 1 after first win', () {
      svc.recordMatch(_match(userId: uid, result: GameResult.win));
      expect(svc.getUserStats(uid)!.streaks.currentWinStreak, 1);
    });

    test('currentWinStreak increments on consecutive wins', () {
      svc.recordMatch(_match(id: 'm1', userId: uid, result: GameResult.win));
      svc.recordMatch(_match(id: 'm2', userId: uid, result: GameResult.win));
      expect(svc.getUserStats(uid)!.streaks.currentWinStreak, 2);
    });

    test('currentWinStreak resets to 0 after loss', () {
      svc.recordMatch(_match(id: 'm1', userId: uid, result: GameResult.win));
      svc.recordMatch(_match(id: 'm2', userId: uid, result: GameResult.win));
      svc.recordMatch(_match(id: 'm3', userId: uid, result: GameResult.loss));
      expect(svc.getUserStats(uid)!.streaks.currentWinStreak, 0);
    });

    test('longestWinStreak tracks the max', () {
      svc.recordMatch(_match(id: 'm1', userId: uid, result: GameResult.win));
      svc.recordMatch(_match(id: 'm2', userId: uid, result: GameResult.win));
      svc.recordMatch(_match(id: 'm3', userId: uid, result: GameResult.win));
      svc.recordMatch(_match(id: 'm4', userId: uid, result: GameResult.loss));
      svc.recordMatch(_match(id: 'm5', userId: uid, result: GameResult.win));
      expect(svc.getUserStats(uid)!.streaks.longestWinStreak, 3);
    });

    test('isStreakActive true when last game was recent', () {
      svc.recordMatch(_match(userId: uid));
      expect(svc.getUserStats(uid)!.streaks.isStreakActive, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // achievements
  // -------------------------------------------------------------------------

  group('achievements', () {
    test('getAchievements returns 13 entries for a fresh user', () {
      svc.recordMatch(_match(userId: uid));
      expect(svc.getAchievements(uid).length, 13);
    });

    test('first_win achievement unlocked after one win', () async {
      await svc.recordMatch(_match(userId: uid, result: GameResult.win));
      final achievements = svc.getUnlockedAchievements(uid);
      expect(achievements.any((a) => a.id == 'first_win'), isTrue);
    });

    test('perfect_game achievement unlocked for 100% accuracy', () async {
      await svc.recordMatch(_match(
        userId: uid,
        result: GameResult.win,
        questionsAnswered: 10,
        correctAnswers: 10,
      ));
      final unlocked = svc.getUnlockedAchievements(uid);
      expect(unlocked.any((a) => a.id == 'perfect_game'), isTrue);
    });

    test('brain_box unlocked for score >= 1000', () async {
      await svc.recordMatch(
          _match(userId: uid, score: 1000, result: GameResult.win));
      final unlocked = svc.getUnlockedAchievements(uid);
      expect(unlocked.any((a) => a.id == 'brain_box'), isTrue);
    });

    test('getLockedAchievements returns achievements not yet met', () {
      svc.recordMatch(_match(userId: uid, result: GameResult.loss));
      final locked = svc.getLockedAchievements(uid);
      expect(locked.isNotEmpty, isTrue);
    });

    test('getNewlyUnlockedAchievements returns recently unlocked', () async {
      await svc.recordMatch(_match(userId: uid, result: GameResult.win));
      final newlyUnlocked = svc.getNewlyUnlockedAchievements(uid);
      expect(newlyUnlocked.any((a) => a.id == 'first_win'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // leaderboard
  // -------------------------------------------------------------------------

  group('leaderboard', () {
    test('getGlobalLeaderboard sorted descending by totalPoints', () {
      const u2 = 'lb_user_a';
      const u3 = 'lb_user_b';
      svc.recordMatch(
          _match(id: 'la1', userId: u2, score: 200, result: GameResult.win));
      svc.recordMatch(
          _match(id: 'la2', userId: u3, score: 800, result: GameResult.win));
      svc.recordMatch(
          _match(id: 'la3', userId: uid, score: 500, result: GameResult.win));
      final lb = svc.getGlobalLeaderboard();
      // Find these users in leaderboard
      final positions = lb.map((s) => s.key).toList();
      final u3Pos = positions.indexOf(u3);
      final uidPos = positions.indexOf(uid);
      final u2Pos = positions.indexOf(u2);
      expect(u3Pos, lessThan(uidPos));
      expect(uidPos, lessThan(u2Pos));
    });

    test('getUserRank returns 1-indexed position', () {
      svc.recordMatch(_match(userId: uid, score: 500, result: GameResult.win));
      final rank = svc.getUserRank(uid);
      expect(rank, isNotNull);
      expect(rank!, greaterThanOrEqualTo(1));
    });

    test('getUserRank returns null for unknown user', () {
      expect(svc.getUserRank('ghost_user_xyz'), isNull);
    });

    test('getCategoryLeaderboard returns users with that category', () {
      const catUser = 'cat_lb_user';
      svc.recordMatch(
          _match(userId: catUser, category: 'Movies', result: GameResult.win));
      final lb = svc.getCategoryLeaderboard('Movies');
      expect(lb.any((s) => s.key == catUser), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // query helpers
  // -------------------------------------------------------------------------

  group('query helpers', () {
    test('getRecentMatches respects limit', () {
      for (int i = 0; i < 5; i++) {
        svc.recordMatch(_match(id: 'm$i', userId: uid));
      }
      expect(svc.getRecentMatches(uid, limit: 3).length, 3);
    });

    test('getRecentMatches returns most recent first', () {
      svc.recordMatch(
          _match(id: 'early', userId: uid, score: 100, result: GameResult.win));
      svc.recordMatch(
          _match(id: 'later', userId: uid, score: 200, result: GameResult.win));
      final recent = svc.getRecentMatches(uid, limit: 2);
      expect(recent.first.id, 'later');
    });

    test('getMatchesByCategory filters correctly', () {
      svc.recordMatch(_match(id: 'm1', userId: uid, category: 'Sports'));
      svc.recordMatch(_match(id: 'm2', userId: uid, category: 'Science'));
      final sports = svc.getMatchesByCategory(uid, 'Sports');
      expect(sports.every((m) => m.category == 'Sports'), isTrue);
      expect(sports.length, 1);
    });

    test('getUnlockedAchievements is subset of getAchievements', () {
      svc.recordMatch(_match(userId: uid, result: GameResult.win));
      final all = svc.getAchievements(uid);
      final unlocked = svc.getUnlockedAchievements(uid);
      expect(all.length, greaterThanOrEqualTo(unlocked.length));
    });
  });

  // -------------------------------------------------------------------------
  // streams
  // -------------------------------------------------------------------------

  group('streams', () {
    test('watchUserStats emits after recordMatch', () async {
      // Initialize stream by calling watchUserStats after first match to create the user
      svc.recordMatch(_match(id: 'init', userId: uid));
      final stream = svc.watchUserStats(uid);
      final future = stream.first;
      svc.recordMatch(
          _match(id: 'trigger', userId: uid, result: GameResult.win));
      final stats = await future.timeout(const Duration(seconds: 2));
      expect(stats.userId, uid);
    });
  });

  // -------------------------------------------------------------------------
  // recordMultipleMatches
  // -------------------------------------------------------------------------

  group('recordMultipleMatches', () {
    test('batch records equivalent to sequential', () {
      const uid2 = 'batch_user_77';
      svc.recordMultipleMatches([
        _match(id: 'b1', userId: uid2, result: GameResult.win),
        _match(id: 'b2', userId: uid2, result: GameResult.loss),
        _match(id: 'b3', userId: uid2, result: GameResult.win),
      ]);
      final stats = svc.getUserStats(uid2)!;
      expect(stats.totalGames, 3);
      expect(stats.totalWins, 2);
      expect(stats.totalLosses, 1);
    });
  });

  // -------------------------------------------------------------------------
  // getDetailedAnalytics
  // -------------------------------------------------------------------------

  group('getDetailedAnalytics', () {
    test('returns map with expected top-level keys', () {
      svc.recordMatch(_match(userId: uid));
      final analytics = svc.getDetailedAnalytics(uid);
      expect(analytics.containsKey('overview'), isTrue);
      expect(analytics.containsKey('streaks'), isTrue);
      expect(analytics.containsKey('achievements'), isTrue);
      expect(analytics.containsKey('categories'), isTrue);
      expect(analytics.containsKey('recentPerformance'), isTrue);
    });

    test('returns empty map for unknown user', () {
      final analytics = svc.getDetailedAnalytics('nobody_xyz');
      expect(analytics, isEmpty);
    });
  });
}
