import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/multiplayer/application/state/match_state.dart';
import 'package:trivia_tycoon/game/multiplayer/application/state/multiplayer_state.dart';
import 'package:trivia_tycoon/game/multiplayer/application/state/room_state.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/player_presence.dart';

void main() {
  // ---------------------------------------------------------------------------
  // MatchPhase
  // ---------------------------------------------------------------------------

  group('MatchPhase enum', () {
    test('has 8 values', () {
      expect(MatchPhase.values.length, 8);
    });

    test('contains all expected phases', () {
      expect(
        MatchPhase.values,
        containsAll([
          MatchPhase.idle,
          MatchPhase.queued,
          MatchPhase.starting,
          MatchPhase.question,
          MatchPhase.reveal,
          MatchPhase.results,
          MatchPhase.finished,
          MatchPhase.error,
        ]),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // MatchState
  // ---------------------------------------------------------------------------

  group('MatchState', () {
    test('default constructor has idle phase and all-null optional fields', () {
      const s = MatchState();
      expect(s.phase, MatchPhase.idle);
      expect(s.matchId, isNull);
      expect(s.questionId, isNull);
      expect(s.remainingMs, isNull);
      expect(s.message, isNull);
    });

    test('MatchState.idle() named constructor matches default', () {
      const s = MatchState.idle();
      expect(s.phase, MatchPhase.idle);
      expect(s.matchId, isNull);
    });

    test('copyWith updates specified fields, preserves others', () {
      const original = MatchState(matchId: 'm1', phase: MatchPhase.idle);
      final updated = original.copyWith(
        phase: MatchPhase.question,
        questionId: 'q1',
        remainingMs: 30000,
      );
      expect(updated.matchId, 'm1');
      expect(updated.phase, MatchPhase.question);
      expect(updated.questionId, 'q1');
      expect(updated.remainingMs, 30000);
    });

    test('copyWith clearRemaining sets remainingMs to null', () {
      const s = MatchState(remainingMs: 5000);
      expect(s.copyWith(clearRemaining: true).remainingMs, isNull);
    });

    test('copyWith clearMessage sets message to null', () {
      const s = MatchState(message: 'error msg');
      expect(s.copyWith(clearMessage: true).message, isNull);
    });

    test('equality: same fields are equal', () {
      const a = MatchState(matchId: 'm1', phase: MatchPhase.question);
      const b = MatchState(matchId: 'm1', phase: MatchPhase.question);
      expect(a, b);
    });

    test('equality: different phase is not equal', () {
      const a = MatchState(phase: MatchPhase.idle);
      const b = MatchState(phase: MatchPhase.results);
      expect(a, isNot(b));
    });

    test('hashCode is consistent for equal states', () {
      const a = MatchState(matchId: 'm1');
      const b = MatchState(matchId: 'm1');
      expect(a.hashCode, b.hashCode);
    });

    test('toString contains phase name', () {
      const s = MatchState(phase: MatchPhase.question, matchId: 'mx');
      expect(s.toString(), contains('question'));
    });
  });

  // ---------------------------------------------------------------------------
  // MultiplayerState
  // ---------------------------------------------------------------------------

  group('MultiplayerState', () {
    test('disconnected() factory: connected=false, latency=0, error=null', () {
      const s = MultiplayerState.disconnected();
      expect(s.connected, isFalse);
      expect(s.latencyMs, 0);
      expect(s.error, isNull);
    });

    test('connecting() factory: connected=false', () {
      const s = MultiplayerState.connecting();
      expect(s.connected, isFalse);
    });

    test('connected() factory: connected=true with optional latency', () {
      const s = MultiplayerState.connected(latencyMs: 42);
      expect(s.connected, isTrue);
      expect(s.latencyMs, 42);
      expect(s.error, isNull);
    });

    test('error() factory: connected=false with error message', () {
      const s = MultiplayerState.error('timeout');
      expect(s.connected, isFalse);
      expect(s.error, 'timeout');
    });

    test('copyWith updates connected and latencyMs', () {
      const original = MultiplayerState.disconnected();
      final updated = original.copyWith(connected: true, latencyMs: 25);
      expect(updated.connected, isTrue);
      expect(updated.latencyMs, 25);
    });

    test('copyWith clearError sets error to null', () {
      const s = MultiplayerState(connected: false, error: 'err');
      expect(s.copyWith(clearError: true).error, isNull);
    });

    test('equality: same fields are equal', () {
      const a = MultiplayerState(connected: true, latencyMs: 50);
      const b = MultiplayerState(connected: true, latencyMs: 50);
      expect(a, b);
    });

    test('equality: different connected status is not equal', () {
      const a = MultiplayerState.connected();
      const b = MultiplayerState.disconnected();
      expect(a, isNot(b));
    });

    test('hashCode consistent for equal states', () {
      const a = MultiplayerState(connected: false, latencyMs: 10);
      const b = MultiplayerState(connected: false, latencyMs: 10);
      expect(a.hashCode, b.hashCode);
    });
  });

  // ---------------------------------------------------------------------------
  // RoomState
  // ---------------------------------------------------------------------------

  group('RoomState', () {
    test('idle() factory: all null/empty defaults', () {
      const s = RoomState.idle();
      expect(s.roomId, isNull);
      expect(s.roomName, isNull);
      expect(s.players, isEmpty);
      expect(s.loading, isFalse);
      expect(s.error, isNull);
      expect(s.isHost, isFalse);
    });

    test('loading() factory: loading=true and no room info', () {
      const s = RoomState.loading();
      expect(s.loading, isTrue);
      expect(s.roomId, isNull);
    });

    test('copyWith updates roomId, roomName and isHost', () {
      const original = RoomState.idle();
      final updated = original.copyWith(
        roomId: 'r1',
        roomName: 'My Room',
        isHost: true,
      );
      expect(updated.roomId, 'r1');
      expect(updated.roomName, 'My Room');
      expect(updated.isHost, isTrue);
      expect(updated.loading, isFalse);
    });

    test('copyWith updates players list', () {
      const p = PlayerPresence(id: 'p1', name: 'Alice');
      final updated = const RoomState.idle().copyWith(players: [p]);
      expect(updated.players.length, 1);
      expect(updated.players[0].id, 'p1');
    });

    test('copyWith clearError sets error to null', () {
      const s = RoomState(error: 'some error');
      expect(s.copyWith(clearError: true).error, isNull);
    });

    test('equality uses list equality for players', () {
      const p = PlayerPresence(id: 'p1', name: 'Alice');
      final a = RoomState(roomId: 'r1', players: [p]);
      final b = RoomState(roomId: 'r1', players: [p]);
      expect(a, b);
    });

    test('different player lists are not equal', () {
      const p1 = PlayerPresence(id: 'p1', name: 'Alice');
      const p2 = PlayerPresence(id: 'p2', name: 'Bob');
      expect(RoomState(players: [p1]), isNot(RoomState(players: [p2])));
    });

    test('two idle() instances are equal', () {
      const a = RoomState.idle();
      const b = RoomState.idle();
      expect(a, b);
    });

    test('hashCode consistent for equal states', () {
      const a = RoomState(roomId: 'r1');
      const b = RoomState(roomId: 'r1');
      expect(a.hashCode, b.hashCode);
    });
  });
}
