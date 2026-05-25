import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_event.dart';

void main() {
  // -------------------------------------------------------------------------
  // JoinedRoom
  // -------------------------------------------------------------------------

  group('JoinedRoom', () {
    test('stores roomId and optional roomName', () {
      const e = JoinedRoom('r1', roomName: 'Lobby');
      expect(e.roomId, 'r1');
      expect(e.roomName, 'Lobby');
    });

    test('roomName is null by default', () {
      expect(const JoinedRoom('r1').roomName, isNull);
    });

    test('toString contains roomId', () {
      expect(const JoinedRoom('r-99').toString(), contains('r-99'));
    });

    test('is a GameEvent', () {
      expect(const JoinedRoom('r1'), isA<GameEvent>());
    });
  });

  // -------------------------------------------------------------------------
  // PlayerJoined
  // -------------------------------------------------------------------------

  group('PlayerJoined', () {
    const e = PlayerJoined(
      roomId: 'r1',
      playerId: 'p1',
      playerName: 'Alice',
      isHost: true,
    );

    test('stores all fields', () {
      expect(e.roomId, 'r1');
      expect(e.playerId, 'p1');
      expect(e.playerName, 'Alice');
      expect(e.isHost, isTrue);
    });

    test('isHost defaults to false', () {
      expect(
        const PlayerJoined(roomId: 'r1', playerId: 'p1', playerName: 'Bob').isHost,
        isFalse,
      );
    });

    test('toString contains playerId', () {
      expect(e.toString(), contains('p1'));
    });
  });

  // -------------------------------------------------------------------------
  // PlayerLeft
  // -------------------------------------------------------------------------

  group('PlayerLeft', () {
    test('stores roomId and playerId', () {
      const e = PlayerLeft(roomId: 'r1', playerId: 'p2');
      expect(e.roomId, 'r1');
      expect(e.playerId, 'p2');
    });

    test('toString contains both ids', () {
      const e = PlayerLeft(roomId: 'r1', playerId: 'p2');
      expect(e.toString(), contains('r1'));
      expect(e.toString(), contains('p2'));
    });
  });

  // -------------------------------------------------------------------------
  // HostChanged
  // -------------------------------------------------------------------------

  group('HostChanged', () {
    test('stores roomId and newHostPlayerId', () {
      const e = HostChanged(roomId: 'r1', newHostPlayerId: 'p3');
      expect(e.roomId, 'r1');
      expect(e.newHostPlayerId, 'p3');
    });
  });

  // -------------------------------------------------------------------------
  // MatchStarted
  // -------------------------------------------------------------------------

  group('MatchStarted', () {
    test('stores matchId and roomId', () {
      const e = MatchStarted(matchId: 'm1', roomId: 'r1');
      expect(e.matchId, 'm1');
      expect(e.roomId, 'r1');
    });

    test('toString contains matchId', () {
      expect(const MatchStarted(matchId: 'm-42', roomId: 'r1').toString(), contains('m-42'));
    });
  });

  // -------------------------------------------------------------------------
  // TurnStarted
  // -------------------------------------------------------------------------

  group('TurnStarted', () {
    test('stores matchId, questionId and optional durationMs', () {
      const e = TurnStarted(matchId: 'm1', questionId: 'q1', durationMs: 30000);
      expect(e.matchId, 'm1');
      expect(e.questionId, 'q1');
      expect(e.durationMs, 30000);
    });

    test('durationMs is null by default', () {
      expect(const TurnStarted(matchId: 'm1', questionId: 'q1').durationMs, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // TurnRevealed
  // -------------------------------------------------------------------------

  group('TurnRevealed', () {
    test('stores correct fields including playerCorrectMap', () {
      const e = TurnRevealed(
        matchId: 'm1',
        questionId: 'q1',
        correctAnswerId: 'a2',
        playerCorrectMap: {'p1': true, 'p2': false},
      );
      expect(e.correctAnswerId, 'a2');
      expect(e.playerCorrectMap['p1'], isTrue);
      expect(e.playerCorrectMap['p2'], isFalse);
    });

    test('playerCorrectMap defaults to empty map', () {
      const e = TurnRevealed(
        matchId: 'm1',
        questionId: 'q1',
        correctAnswerId: 'a1',
      );
      expect(e.playerCorrectMap, isEmpty);
    });

    test('toString contains result count', () {
      const e = TurnRevealed(
        matchId: 'm1',
        questionId: 'q1',
        correctAnswerId: 'a1',
        playerCorrectMap: {'p1': true},
      );
      expect(e.toString(), contains('1'));
    });
  });

  // -------------------------------------------------------------------------
  // AnswerAccepted
  // -------------------------------------------------------------------------

  group('AnswerAccepted', () {
    test('stores all fields', () {
      const e = AnswerAccepted(
        matchId: 'm1',
        questionId: 'q1',
        playerId: 'p1',
        answerId: 'a3',
      );
      expect(e.matchId, 'm1');
      expect(e.questionId, 'q1');
      expect(e.playerId, 'p1');
      expect(e.answerId, 'a3');
    });
  });

  // -------------------------------------------------------------------------
  // AnswerRejected
  // -------------------------------------------------------------------------

  group('AnswerRejected', () {
    test('stores reason field', () {
      const e = AnswerRejected(
        matchId: 'm1',
        questionId: 'q1',
        playerId: 'p1',
        reason: 'too_late',
      );
      expect(e.reason, 'too_late');
    });

    test('toString contains reason', () {
      const e = AnswerRejected(
        matchId: 'm1',
        questionId: 'q1',
        playerId: 'p1',
        reason: 'duplicate',
      );
      expect(e.toString(), contains('duplicate'));
    });
  });

  // -------------------------------------------------------------------------
  // MatchEnded
  // -------------------------------------------------------------------------

  group('MatchEnded', () {
    test('stores matchId and roomId', () {
      const e = MatchEnded(matchId: 'm1', roomId: 'r1');
      expect(e.matchId, 'm1');
      expect(e.roomId, 'r1');
    });
  });

  // -------------------------------------------------------------------------
  // ServerNotice
  // -------------------------------------------------------------------------

  group('ServerNotice', () {
    test('stores code and message', () {
      const e = ServerNotice(code: 'maintenance', message: 'Back in 5 min');
      expect(e.code, 'maintenance');
      expect(e.message, 'Back in 5 min');
    });

    test('toString contains code', () {
      expect(const ServerNotice(code: 'restart', message: '').toString(), contains('restart'));
    });
  });

  // -------------------------------------------------------------------------
  // Kicked
  // -------------------------------------------------------------------------

  group('Kicked', () {
    test('stores reason', () {
      expect(const Kicked(reason: 'duplicate_login').reason, 'duplicate_login');
    });
  });

  // -------------------------------------------------------------------------
  // ProtocolError
  // -------------------------------------------------------------------------

  group('ProtocolError', () {
    test('stores message', () {
      expect(const ProtocolError('bad_frame').message, 'bad_frame');
    });

    test('toString contains message', () {
      expect(const ProtocolError('bad_frame').toString(), contains('bad_frame'));
    });
  });

  // -------------------------------------------------------------------------
  // Type hierarchy
  // -------------------------------------------------------------------------

  group('GameEvent type hierarchy', () {
    test('all concrete events are GameEvent', () {
      final events = [
        const JoinedRoom('r1'),
        const PlayerJoined(roomId: 'r1', playerId: 'p1', playerName: 'X'),
        const PlayerLeft(roomId: 'r1', playerId: 'p1'),
        const HostChanged(roomId: 'r1', newHostPlayerId: 'p2'),
        const MatchStarted(matchId: 'm1', roomId: 'r1'),
        const TurnStarted(matchId: 'm1', questionId: 'q1'),
        const TurnRevealed(matchId: 'm1', questionId: 'q1', correctAnswerId: 'a1'),
        const AnswerAccepted(matchId: 'm1', questionId: 'q1', playerId: 'p1', answerId: 'a1'),
        const AnswerRejected(matchId: 'm1', questionId: 'q1', playerId: 'p1', reason: 'x'),
        const MatchEnded(matchId: 'm1', roomId: 'r1'),
        const ServerNotice(code: 'c', message: 'm'),
        const Kicked(reason: 'x'),
        const ProtocolError('msg'),
      ];
      for (final e in events) {
        expect(e, isA<GameEvent>(), reason: '${e.runtimeType} should extend GameEvent');
      }
    });
  });
}
