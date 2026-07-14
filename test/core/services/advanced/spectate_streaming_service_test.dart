import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/advanced/spectate_streaming_service.dart';

void main() {
  // SpectateStreamingService is a singleton — use unique game IDs per test.
  final SpectateStreamingService svc = SpectateStreamingService();

  setUpAll(() {
    svc.initialize();
  });

  // ---------------------------------------------------------------------------
  // PlayerState data class
  // ---------------------------------------------------------------------------

  group('PlayerState', () {
    const p = PlayerState(id: 'p1', name: 'Alice', score: 500);

    test('holds required fields', () {
      expect(p.id, 'p1');
      expect(p.name, 'Alice');
      expect(p.score, 500);
    });

    test('optional fields default correctly', () {
      expect(p.avatar, isNull);
      expect(p.correctAnswers, 0);
      expect(p.streak, 0);
      expect(p.isAnswering, isFalse);
    });

    test('avatar field when provided', () {
      const withAvatar =
          PlayerState(id: 'p2', name: 'Bob', score: 100, avatar: 'avatar_url');
      expect(withAvatar.avatar, 'avatar_url');
    });

    test('copyWith score updated, others preserved', () {
      final updated = p.copyWith(score: 750);
      expect(updated.score, 750);
      expect(updated.id, 'p1');
      expect(updated.name, 'Alice');
    });

    test('copyWith correctAnswers updated', () {
      final updated = p.copyWith(correctAnswers: 8);
      expect(updated.correctAnswers, 8);
      expect(updated.score, 500); // preserved
    });

    test('copyWith streak updated', () {
      final updated = p.copyWith(streak: 3);
      expect(updated.streak, 3);
    });

    test('copyWith isAnswering updated', () {
      final updated = p.copyWith(isAnswering: true);
      expect(updated.isAnswering, isTrue);
    });

    test('copyWith id and name updated', () {
      final updated = p.copyWith(id: 'p99', name: 'Charlie');
      expect(updated.id, 'p99');
      expect(updated.name, 'Charlie');
    });
  });

  // ---------------------------------------------------------------------------
  // QuestionState data class
  // ---------------------------------------------------------------------------

  group('QuestionState', () {
    test('timeRemaining is positive for future startTime', () {
      final q = QuestionState(
        index: 0,
        question: 'What is H2O?',
        options: ['Water', 'Fire', 'Air', 'Earth'],
        startTime: DateTime.now(),
        timeLimit: const Duration(seconds: 15),
      );
      expect(q.timeRemaining.inSeconds, greaterThan(0));
      expect(q.isTimeUp, isFalse);
    });

    test('timeRemaining is zero when time has passed', () {
      final q = QuestionState(
        index: 0,
        question: 'Old question',
        options: ['A', 'B', 'C', 'D'],
        startTime: DateTime.now().subtract(const Duration(minutes: 1)),
        timeLimit: const Duration(seconds: 15),
      );
      expect(q.timeRemaining, Duration.zero);
      expect(q.isTimeUp, isTrue);
    });

    test('holds all fields', () {
      final start = DateTime(2026, 1, 1, 10);
      final q = QuestionState(
        index: 3,
        question: 'Who wrote Hamlet?',
        options: ['Shakespeare', 'Milton', 'Keats', 'Donne'],
        correctAnswer: 'Shakespeare',
        isRevealed: true,
        startTime: start,
        timeLimit: const Duration(seconds: 20),
      );
      expect(q.index, 3);
      expect(q.question, 'Who wrote Hamlet?');
      expect(q.options.length, 4);
      expect(q.correctAnswer, 'Shakespeare');
      expect(q.isRevealed, isTrue);
    });

    test('playerAnswers defaults empty', () {
      final q = QuestionState(
        index: 0,
        question: 'Q',
        options: ['A', 'B'],
        startTime: DateTime.now(),
        timeLimit: const Duration(seconds: 10),
      );
      expect(q.playerAnswers, isEmpty);
    });

    test('timeRemaining does not go negative', () {
      final q = QuestionState(
        index: 0,
        question: 'Expired',
        options: ['A'],
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        timeLimit: const Duration(seconds: 15),
      );
      expect(q.timeRemaining.isNegative, isFalse);
      expect(q.timeRemaining, Duration.zero);
    });
  });

  // ---------------------------------------------------------------------------
  // GameSpectateState data class
  // ---------------------------------------------------------------------------

  group('GameSpectateState', () {
    final start = DateTime(2026, 1, 1, 10);

    test('holds all required fields', () {
      // Using a valid construction
      final s = GameSpectateState(
        gameId: 'game1',
        gameTitle: 'Science Quiz',
        category: 'Science',
        players: const [],
        totalQuestions: 10,
        startTime: start,
      );
      expect(s.gameId, 'game1');
      expect(s.gameTitle, 'Science Quiz');
      expect(s.category, 'Science');
      expect(s.totalQuestions, 10);
    });

    test('defaults: hasStarted false, hasEnded false', () {
      final s = GameSpectateState(
        gameId: 'g2',
        gameTitle: 'T',
        category: 'C',
        players: const [],
        totalQuestions: 5,
        startTime: start,
      );
      expect(s.hasStarted, isFalse);
      expect(s.hasEnded, isFalse);
    });

    test('defaults: spectatorCount 0, currentQuestionIndex 0', () {
      final s = GameSpectateState(
        gameId: 'g3',
        gameTitle: 'T',
        category: 'C',
        players: const [],
        totalQuestions: 5,
        startTime: start,
      );
      expect(s.spectatorCount, 0);
      expect(s.currentQuestionIndex, 0);
    });

    test('progress: 0.0 when totalQuestions is 0', () {
      final s = GameSpectateState(
        gameId: 'g4',
        gameTitle: 'T',
        category: 'C',
        players: const [],
        totalQuestions: 0,
        startTime: start,
      );
      expect(s.progress, 0.0);
    });

    test('progress: 0.5 when half way through', () {
      final s = GameSpectateState(
        gameId: 'g5',
        gameTitle: 'T',
        category: 'C',
        players: const [],
        totalQuestions: 10,
        currentQuestionIndex: 5,
        startTime: start,
      );
      expect(s.progress, closeTo(0.5, 0.001));
    });

    test('progress: 1.0 when all questions done', () {
      final s = GameSpectateState(
        gameId: 'g6',
        gameTitle: 'T',
        category: 'C',
        players: const [],
        totalQuestions: 10,
        currentQuestionIndex: 10,
        startTime: start,
      );
      expect(s.progress, closeTo(1.0, 0.001));
    });

    test('winner field', () {
      final s = GameSpectateState(
        gameId: 'g7',
        gameTitle: 'T',
        category: 'C',
        players: const [],
        totalQuestions: 5,
        hasEnded: true,
        winner: 'Alice',
        startTime: start,
      );
      expect(s.winner, 'Alice');
      expect(s.hasEnded, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // SpectateStreamingService — watchGame
  // ---------------------------------------------------------------------------

  group('watchGame', () {
    test('creates a mock game when game does not exist', () async {
      final stream =
          svc.watchGame('new_game_${DateTime.now().microsecondsSinceEpoch}');
      expect(stream, isA<Stream<GameSpectateState>>());
    });

    test('mock game is Science Showdown with 2 players', () async {
      final gameId = 'watch_game_${DateTime.now().microsecondsSinceEpoch}';
      final stream = svc.watchGame(gameId);
      final state = await stream.first.timeout(const Duration(seconds: 2));
      expect(state.gameId, gameId);
      expect(state.gameTitle, 'Science Showdown');
      expect(state.category, 'Science');
      expect(state.players.length, 2);
    });

    test('mock game has started and not ended', () async {
      final gameId = 'watch_started_${DateTime.now().microsecondsSinceEpoch}';
      final stream = svc.watchGame(gameId);
      final state = await stream.first.timeout(const Duration(seconds: 2));
      expect(state.hasStarted, isTrue);
      expect(state.hasEnded, isFalse);
    });

    test('mock game has 10 total questions', () async {
      final gameId = 'watch_questions_${DateTime.now().microsecondsSinceEpoch}';
      final stream = svc.watchGame(gameId);
      final state = await stream.first.timeout(const Duration(seconds: 2));
      expect(state.totalQuestions, 10);
    });

    test('mock game has a currentQuestion', () async {
      final gameId = 'watch_q_${DateTime.now().microsecondsSinceEpoch}';
      final stream = svc.watchGame(gameId);
      final state = await stream.first.timeout(const Duration(seconds: 2));
      expect(state.currentQuestion, isNotNull);
    });

    test('returns same stream for same gameId', () {
      const gameId = 'same_stream_game';
      final s1 = svc.watchGame(gameId);
      final s2 = svc.watchGame(gameId);
      expect(identical(s1, s2), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // SpectateStreamingService — joinSpectate / leaveSpectate
  // ---------------------------------------------------------------------------

  group('joinSpectate', () {
    test('increments spectatorCount on tracked game', () async {
      final gameId = 'join_game_${DateTime.now().microsecondsSinceEpoch}';
      // First call watchGame to create the mock game
      final stream = svc.watchGame(gameId);
      await stream.first.timeout(const Duration(seconds: 2));

      final received = <GameSpectateState>[];
      final sub = stream.listen(received.add);

      svc.joinSpectate(
          gameId: gameId, spectatorId: 'spec1', spectatorName: 'Spectator One');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(received.any((s) => s.spectatorCount >= 1), isTrue);
      await sub.cancel();
    });

    test('joining multiple spectators accumulates count', () async {
      final gameId = 'join_multi_${DateTime.now().microsecondsSinceEpoch}';
      svc.watchGame(gameId);
      await Future.delayed(const Duration(milliseconds: 100));

      svc.joinSpectate(gameId: gameId, spectatorId: 'sa1', spectatorName: 'A');
      svc.joinSpectate(gameId: gameId, spectatorId: 'sa2', spectatorName: 'B');
      svc.joinSpectate(gameId: gameId, spectatorId: 'sa3', spectatorName: 'C');

      final stream = svc.watchGame(gameId);
      final state = await stream.first.timeout(const Duration(seconds: 2));
      expect(state.spectatorCount, greaterThanOrEqualTo(3));
    });

    test('joining an unknown game is no-op (no error)', () {
      expect(
        () => svc.joinSpectate(
            gameId: 'unknown_game_xyz',
            spectatorId: 'spec',
            spectatorName: 'Name'),
        returnsNormally,
      );
    });
  });

  group('leaveSpectate', () {
    test('decrements spectatorCount after leave', () async {
      final gameId = 'leave_game_${DateTime.now().microsecondsSinceEpoch}';
      svc.watchGame(gameId);
      await Future.delayed(const Duration(milliseconds: 100));

      svc.joinSpectate(
          gameId: gameId, spectatorId: 'ls1', spectatorName: 'LS1');
      svc.joinSpectate(
          gameId: gameId, spectatorId: 'ls2', spectatorName: 'LS2');
      await Future.delayed(const Duration(milliseconds: 50));

      svc.leaveSpectate(gameId: gameId, spectatorId: 'ls1');
      await Future.delayed(const Duration(milliseconds: 50));

      final stream = svc.watchGame(gameId);
      final state = await stream.first.timeout(const Duration(seconds: 2));
      expect(state.spectatorCount, lessThan(2));
    });

    test('leaving an unknown game is no-op', () {
      expect(
        () => svc.leaveSpectate(
            gameId: 'nonexistent_game_leave', spectatorId: 'spec'),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // SpectateStreamingService — getAvailableGames
  // ---------------------------------------------------------------------------

  group('getAvailableGames', () {
    test('returns list of games', () {
      expect(svc.getAvailableGames(), isA<List<GameSpectateState>>());
    });

    test('mock games created via watchGame are included', () async {
      final gameId = 'avail_game_${DateTime.now().microsecondsSinceEpoch}';
      svc.watchGame(gameId);
      await Future.delayed(const Duration(milliseconds: 100));
      final games = svc.getAvailableGames();
      expect(games.any((g) => g.gameId == gameId), isTrue);
    });

    test('only returns games that have started and not ended', () {
      final games = svc.getAvailableGames();
      for (final game in games) {
        expect(game.hasStarted, isTrue);
        expect(game.hasEnded, isFalse);
      }
    });

    test('sorted by spectatorCount descending', () async {
      // Create two games with different spectator counts
      final gameA = 'sorted_a_${DateTime.now().microsecondsSinceEpoch}';
      final gameB = 'sorted_b_${DateTime.now().microsecondsSinceEpoch}';
      svc.watchGame(gameA);
      svc.watchGame(gameB);
      await Future.delayed(const Duration(milliseconds: 100));

      // Give gameA more spectators than gameB
      for (int i = 0; i < 5; i++) {
        svc.joinSpectate(
            gameId: gameA, spectatorId: 'sa$i', spectatorName: 'S$i');
      }
      svc.joinSpectate(gameId: gameB, spectatorId: 'sb0', spectatorName: 'S0');
      await Future.delayed(const Duration(milliseconds: 50));

      final games = svc.getAvailableGames();
      if (games.length >= 2) {
        // Verify sorted descending by spectatorCount
        for (int i = 0; i < games.length - 1; i++) {
          expect(games[i].spectatorCount,
              greaterThanOrEqualTo(games[i + 1].spectatorCount));
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // SpectateStreamingService — sendReaction
  // ---------------------------------------------------------------------------

  group('sendReaction', () {
    test('completes without error', () {
      expect(
        () => svc.sendReaction(
            gameId: 'any_game', spectatorId: 'spec1', reaction: '🎉'),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Mock question content
  // ---------------------------------------------------------------------------

  group('mock question content', () {
    test('watchGame question has non-empty question text', () async {
      final gameId = 'q_content_${DateTime.now().microsecondsSinceEpoch}';
      final stream = svc.watchGame(gameId);
      final state = await stream.first.timeout(const Duration(seconds: 2));
      expect(state.currentQuestion!.question.isNotEmpty, isTrue);
    });

    test('watchGame question has 4 options', () async {
      final gameId = 'q_opts_${DateTime.now().microsecondsSinceEpoch}';
      final stream = svc.watchGame(gameId);
      final state = await stream.first.timeout(const Duration(seconds: 2));
      expect(state.currentQuestion!.options.length, 4);
    });

    test('mock players have names Alex and Jordan', () async {
      final gameId = 'q_players_${DateTime.now().microsecondsSinceEpoch}';
      final stream = svc.watchGame(gameId);
      final state = await stream.first.timeout(const Duration(seconds: 2));
      final names = state.players.map((p) => p.name).toSet();
      expect(names, containsAll(['Alex', 'Jordan']));
    });

    test('mock players start with positive scores', () async {
      final gameId = 'q_scores_${DateTime.now().microsecondsSinceEpoch}';
      final stream = svc.watchGame(gameId);
      final state = await stream.first.timeout(const Duration(seconds: 2));
      for (final player in state.players) {
        expect(player.score, greaterThan(0));
      }
    });
  });
}
