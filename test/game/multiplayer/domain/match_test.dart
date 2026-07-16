import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/domain/entities/game_turn.dart';
import 'package:synaptix/game/multiplayer/domain/entities/match.dart';
import 'package:synaptix/game/multiplayer/domain/entities/player_presence.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _p1 = PlayerPresence(id: 'p1', name: 'Alice');
const _p2 = PlayerPresence(id: 'p2', name: 'Bob');

final _t0 = DateTime.utc(2026, 1, 1, 12);
final _t1 = DateTime.utc(2026, 1, 1, 12, 0, 30);

final _turn = GameTurn(questionId: 'q1', startAt: _t0, endAt: _t1);

Match _match({
  String id = 'm1',
  String roomId = 'r1',
  List<PlayerPresence> players = const [],
  GameTurn? currentTurn,
}) =>
    Match(id: id, roomId: roomId, players: players, currentTurn: currentTurn);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  group('Match.copyWith', () {
    test('returns identical match when no arguments given', () {
      final m = _match(players: [_p1], currentTurn: _turn);
      final copy = m.copyWith();
      expect(copy.id, m.id);
      expect(copy.roomId, m.roomId);
      expect(copy.players, m.players);
      expect(copy.currentTurn, m.currentTurn);
    });

    test('replaces id', () {
      expect(_match().copyWith(id: 'm2').id, 'm2');
    });

    test('replaces roomId', () {
      expect(_match().copyWith(roomId: 'r99').roomId, 'r99');
    });

    test('replaces players', () {
      final copy = _match().copyWith(players: [_p1, _p2]);
      expect(copy.players, [_p1, _p2]);
    });

    test('replaces currentTurn', () {
      final newTurn = GameTurn(questionId: 'q2', startAt: _t0, endAt: _t1);
      expect(_match().copyWith(currentTurn: newTurn).currentTurn?.questionId,
          'q2');
    });

    test('clearTurn sets currentTurn to null', () {
      final m = _match(currentTurn: _turn);
      expect(m.copyWith(clearTurn: true).currentTurn, isNull);
    });

    test('currentTurn argument is ignored when clearTurn is true', () {
      final m = _match(currentTurn: _turn);
      final newTurn = GameTurn(questionId: 'q2', startAt: _t0, endAt: _t1);
      final copy = m.copyWith(currentTurn: newTurn, clearTurn: true);
      expect(copy.currentTurn, isNull);
    });

    test('match with no turn stays null after copyWith', () {
      expect(_match().copyWith().currentTurn, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Equality and hashCode
  // -------------------------------------------------------------------------

  group('Match equality', () {
    test('equal matches compare as equal', () {
      final a = _match(players: [_p1]);
      final b = _match(players: [_p1]);
      expect(a, b);
    });

    test('matches with different ids are not equal', () {
      expect(_match(id: 'm1'), isNot(_match(id: 'm2')));
    });

    test('matches with different roomIds are not equal', () {
      expect(_match(roomId: 'r1'), isNot(_match(roomId: 'r2')));
    });

    test('matches with different players are not equal', () {
      expect(_match(players: [_p1]), isNot(_match(players: [_p2])));
    });

    test('matches with different turns are not equal', () {
      final t2 = GameTurn(questionId: 'q2', startAt: _t0, endAt: _t1);
      expect(_match(currentTurn: _turn), isNot(_match(currentTurn: t2)));
    });

    test('equal matches have the same hashCode', () {
      expect(_match().hashCode, _match().hashCode);
    });
  });

  // -------------------------------------------------------------------------
  // toString
  // -------------------------------------------------------------------------

  group('Match.toString', () {
    test('contains id', () {
      expect(_match(id: 'match-7').toString(), contains('match-7'));
    });

    test('contains roomId', () {
      expect(_match(roomId: 'room-3').toString(), contains('room-3'));
    });
  });
}
