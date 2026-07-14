import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/data/dto/ws_envelope_dto.dart';
import 'package:synaptix/game/multiplayer/data/mappers/event_mapper.dart';
import 'package:synaptix/game/multiplayer/data/sources/ws_protocol.dart';
import 'package:synaptix/game/multiplayer/domain/entities/game_event.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WsEnvelopeDto _env(String op, [Map<String, dynamic>? data]) =>
    WsEnvelopeDto(op: op, ts: 1700000000000, data: data);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const mapper = EventMapper();

  // -------------------------------------------------------------------------
  // Room / Lobby events
  // -------------------------------------------------------------------------

  group('EventMapper — room events', () {
    test('room.joined → JoinedRoom with roomId and roomName', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opJoinedRoom,
        {'roomId': 'r1', 'roomName': 'Arena'},
      ));
      expect(event, isA<JoinedRoom>());
      final e = event as JoinedRoom;
      expect(e.roomId, 'r1');
      expect(e.roomName, 'Arena');
    });

    test('room.player_joined → PlayerJoined with all fields', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opPlayerJoined,
        {
          'roomId': 'r1',
          'playerId': 'p1',
          'playerName': 'Alice',
          'isHost': true,
        },
      ));
      expect(event, isA<PlayerJoined>());
      final e = event as PlayerJoined;
      expect(e.roomId, 'r1');
      expect(e.playerId, 'p1');
      expect(e.playerName, 'Alice');
      expect(e.isHost, isTrue);
    });

    test('room.player_left → PlayerLeft', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opPlayerLeft,
        {'roomId': 'r1', 'playerId': 'p2'},
      ));
      expect(event, isA<PlayerLeft>());
      final e = event as PlayerLeft;
      expect(e.roomId, 'r1');
      expect(e.playerId, 'p2');
    });

    test('room.host_changed → HostChanged', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opHostChanged,
        {'roomId': 'r1', 'newHostPlayerId': 'p3'},
      ));
      expect(event, isA<HostChanged>());
      final e = event as HostChanged;
      expect(e.roomId, 'r1');
      expect(e.newHostPlayerId, 'p3');
    });
  });

  // -------------------------------------------------------------------------
  // Match lifecycle events
  // -------------------------------------------------------------------------

  group('EventMapper — match lifecycle', () {
    test('match.started → MatchStarted', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opMatchStarted,
        {'matchId': 'm1', 'roomId': 'r1'},
      ));
      expect(event, isA<MatchStarted>());
      final e = event as MatchStarted;
      expect(e.matchId, 'm1');
      expect(e.roomId, 'r1');
    });

    test('match.turn_started → TurnStarted with durationMs', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opTurnStarted,
        {'matchId': 'm1', 'questionId': 'q1', 'durationMs': 30000},
      ));
      expect(event, isA<TurnStarted>());
      final e = event as TurnStarted;
      expect(e.questionId, 'q1');
      expect(e.durationMs, 30000);
    });

    test('match.turn_revealed → TurnRevealed with playerCorrectMap', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opTurnRevealed,
        {
          'matchId': 'm1',
          'questionId': 'q1',
          'correctAnswerId': 'a3',
          'playerCorrectMap': {'p1': true, 'p2': false},
        },
      ));
      expect(event, isA<TurnRevealed>());
      final e = event as TurnRevealed;
      expect(e.correctAnswerId, 'a3');
      expect(e.playerCorrectMap['p1'], isTrue);
      expect(e.playerCorrectMap['p2'], isFalse);
    });

    test('match.answer_accepted → AnswerAccepted', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opAnswerAccepted,
        {
          'matchId': 'm1',
          'questionId': 'q1',
          'playerId': 'p1',
          'answerId': 'a1',
        },
      ));
      expect(event, isA<AnswerAccepted>());
      expect((event as AnswerAccepted).answerId, 'a1');
    });

    test('match.answer_rejected → AnswerRejected with reason', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opAnswerRejected,
        {
          'matchId': 'm1',
          'questionId': 'q1',
          'playerId': 'p1',
          'reason': 'too_late',
        },
      ));
      expect(event, isA<AnswerRejected>());
      expect((event as AnswerRejected).reason, 'too_late');
    });

    test('match.ended → MatchEnded', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opMatchEnded,
        {'matchId': 'm1', 'roomId': 'r1'},
      ));
      expect(event, isA<MatchEnded>());
      expect((event as MatchEnded).matchId, 'm1');
    });
  });

  // -------------------------------------------------------------------------
  // Server-level events
  // -------------------------------------------------------------------------

  group('EventMapper — server/system events', () {
    test('server.notice → ServerNotice', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opServerNotice,
        {'code': 'maintenance', 'message': 'Down for maintenance'},
      ));
      expect(event, isA<ServerNotice>());
      final e = event as ServerNotice;
      expect(e.code, 'maintenance');
      expect(e.message, 'Down for maintenance');
    });

    test('server.kicked → Kicked with reason', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opKicked,
        {'reason': 'duplicate_login'},
      ));
      expect(event, isA<Kicked>());
      expect((event as Kicked).reason, 'duplicate_login');
    });

    test('server.protocol_error → ProtocolError', () {
      final event = mapper.fromEnvelope(_env(
        WsProtocol.opProtocolError,
        {'message': 'bad op'},
      ));
      expect(event, isA<ProtocolError>());
      expect((event as ProtocolError).message, 'bad op');
    });
  });

  // -------------------------------------------------------------------------
  // Handshake / infra ops (return null)
  // -------------------------------------------------------------------------

  group('EventMapper — handshake ops return null', () {
    test('hello → null', () {
      expect(mapper.fromEnvelope(_env(WsProtocol.opHello)), isNull);
    });

    test('ack → null', () {
      expect(mapper.fromEnvelope(_env(WsProtocol.opAck)), isNull);
    });

    test('pong → null', () {
      expect(mapper.fromEnvelope(_env(WsProtocol.opPong)), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Unknown / fallback
  // -------------------------------------------------------------------------

  group('EventMapper — unknown op', () {
    test('unrecognized op → ProtocolError containing "Unknown op:"', () {
      final event = mapper.fromEnvelope(_env('unknown.op.xyz'));
      expect(event, isA<ProtocolError>());
      expect((event as ProtocolError).message, contains('Unknown op:'));
    });
  });

  // -------------------------------------------------------------------------
  // fromMap convenience method
  // -------------------------------------------------------------------------

  group('EventMapper.fromMap', () {
    test('delegates to fromEnvelope via WsEnvelopeDto.fromJson', () {
      final event = mapper.fromMap({
        'op': WsProtocol.opMatchStarted,
        'ts': 1700000000000,
        'data': {'matchId': 'm2', 'roomId': 'r2'},
      });
      expect(event, isA<MatchStarted>());
      expect((event as MatchStarted).matchId, 'm2');
    });

    test('returns null for handshake ops via fromMap', () {
      final event = mapper.fromMap({'op': WsProtocol.opHello, 'ts': 1});
      expect(event, isNull);
    });
  });
}
