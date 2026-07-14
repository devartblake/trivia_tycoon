import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/domain/entities/player_presence.dart';
import 'package:synaptix/game/multiplayer/domain/entities/room.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _p1 = PlayerPresence(id: 'p1', name: 'Alice', isHost: true);
const _p2 = PlayerPresence(id: 'p2', name: 'Bob', isHost: false);

Room _room({
  String id = 'r1',
  String? name = 'Test Room',
  int capacity = 4,
  List<PlayerPresence> players = const [],
  bool isHost = false,
}) =>
    Room(
        id: id,
        name: name,
        capacity: capacity,
        players: players,
        isHost: isHost);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Computed getters
  // -------------------------------------------------------------------------

  group('Room.playerCount', () {
    test('returns 0 when empty', () {
      expect(_room().playerCount, 0);
    });

    test('returns correct count for multiple players', () {
      expect(_room(players: [_p1, _p2]).playerCount, 2);
    });
  });

  group('Room.isFull', () {
    test('false when below capacity', () {
      expect(_room(capacity: 4, players: [_p1]).isFull, isFalse);
    });

    test('true when exactly at capacity', () {
      expect(_room(capacity: 2, players: [_p1, _p2]).isFull, isTrue);
    });

    test('true when over capacity', () {
      expect(_room(capacity: 1, players: [_p1, _p2]).isFull, isTrue);
    });

    test('false when no players and capacity > 0', () {
      expect(_room(capacity: 2).isFull, isFalse);
    });
  });

  group('Room.host', () {
    test('returns the player whose isHost is true', () {
      final r = _room(players: [_p1, _p2]);
      expect(r.host?.id, 'p1');
    });

    test('returns null when no player is host', () {
      final r = _room(players: [_p2]);
      expect(r.host, isNull);
    });

    test('returns null when players list is empty', () {
      expect(_room().host, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  group('Room.copyWith', () {
    test('returns an identical room when no arguments given', () {
      final r = _room(players: [_p1]);
      final copy = r.copyWith();
      expect(copy.id, r.id);
      expect(copy.name, r.name);
      expect(copy.capacity, r.capacity);
      expect(copy.players, r.players);
      expect(copy.isHost, r.isHost);
    });

    test('replaces id', () {
      expect(_room().copyWith(id: 'r2').id, 'r2');
    });

    test('replaces capacity', () {
      expect(_room().copyWith(capacity: 10).capacity, 10);
    });

    test('replaces players', () {
      final copy = _room().copyWith(players: [_p1]);
      expect(copy.players, [_p1]);
    });

    test('replaces isHost flag', () {
      expect(_room(isHost: false).copyWith(isHost: true).isHost, isTrue);
    });

    test('clearName sets name to null', () {
      expect(_room(name: 'Room').copyWith(clearName: true).name, isNull);
    });

    test('name argument is ignored when clearName is true', () {
      final copy = _room(name: 'Room').copyWith(name: 'New', clearName: true);
      expect(copy.name, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Equality and hashCode
  // -------------------------------------------------------------------------

  group('Room equality', () {
    test('equal rooms compare as equal', () {
      final a = _room(players: [_p1]);
      final b = _room(players: [_p1]);
      expect(a, b);
    });

    test('rooms with different ids are not equal', () {
      expect(_room(id: 'r1'), isNot(_room(id: 'r2')));
    });

    test('rooms with different players are not equal', () {
      expect(_room(players: [_p1]), isNot(_room(players: [_p2])));
    });

    test('equal rooms have the same hashCode', () {
      expect(_room().hashCode, _room().hashCode);
    });

    test('rooms with different capacities have different hashCodes', () {
      expect(_room(capacity: 2).hashCode, isNot(_room(capacity: 8).hashCode));
    });
  });

  // -------------------------------------------------------------------------
  // toString
  // -------------------------------------------------------------------------

  group('Room.toString', () {
    test('contains id', () {
      expect(_room(id: 'room-42').toString(), contains('room-42'));
    });

    test('contains isHost value', () {
      expect(_room(isHost: true).toString(), contains('true'));
    });

    test('contains capacity', () {
      expect(_room(capacity: 8).toString(), contains('8'));
    });
  });
}
