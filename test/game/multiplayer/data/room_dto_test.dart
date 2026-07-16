import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/data/dto/presence_dto.dart';
import 'package:synaptix/game/multiplayer/data/dto/room_dto.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _presenceJson({
  String playerId = 'p1',
  String playerName = 'Alice',
  bool isHost = false,
}) =>
    {'playerId': playerId, 'playerName': playerName, 'isHost': isHost};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // fromJson
  // -------------------------------------------------------------------------

  group('RoomDto.fromJson', () {
    test('parses all fields', () {
      final dto = RoomDto.fromJson({
        'roomId': 'r42',
        'roomName': 'Lobby',
        'capacity': 4,
        'players': [_presenceJson(isHost: true)],
      });
      expect(dto.roomId, 'r42');
      expect(dto.roomName, 'Lobby');
      expect(dto.capacity, 4);
      expect(dto.players.length, 1);
      expect(dto.players.first.isHost, isTrue);
    });

    test('roomName is null when absent', () {
      final dto = RoomDto.fromJson({'roomId': 'r1', 'capacity': 2});
      expect(dto.roomName, isNull);
    });

    test('players defaults to empty list when absent', () {
      final dto = RoomDto.fromJson({'roomId': 'r1', 'capacity': 2});
      expect(dto.players, isEmpty);
    });

    test('capacity parses int directly', () {
      final dto = RoomDto.fromJson({'roomId': 'r1', 'capacity': 8});
      expect(dto.capacity, 8);
    });

    test('capacity parses string "4" via int.tryParse', () {
      final dto = RoomDto.fromJson({'roomId': 'r1', 'capacity': '4'});
      expect(dto.capacity, 4);
    });

    test('capacity defaults to 0 on invalid string', () {
      final dto = RoomDto.fromJson({'roomId': 'r1', 'capacity': 'bad'});
      expect(dto.capacity, 0);
    });

    test('roomId coerced from int via toString', () {
      final dto = RoomDto.fromJson({'roomId': 99, 'capacity': 2});
      expect(dto.roomId, '99');
    });

    test('multiple players parsed correctly', () {
      final dto = RoomDto.fromJson({
        'roomId': 'r1',
        'capacity': 4,
        'players': [
          _presenceJson(playerId: 'p1', playerName: 'Alice', isHost: true),
          _presenceJson(playerId: 'p2', playerName: 'Bob'),
        ],
      });
      expect(dto.players.length, 2);
      expect(dto.players[0].playerId, 'p1');
      expect(dto.players[1].playerName, 'Bob');
    });

    test('non-Map entries in players list are skipped', () {
      final dto = RoomDto.fromJson({
        'roomId': 'r1',
        'capacity': 4,
        'players': ['invalid', 42],
      });
      expect(dto.players, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // toJson
  // -------------------------------------------------------------------------

  group('RoomDto.toJson', () {
    test('round-trips all fields', () {
      const dto = RoomDto(
        roomId: 'r1',
        roomName: 'Lobby',
        capacity: 4,
        players: [
          PresenceDto(playerId: 'p1', playerName: 'Alice', isHost: true)
        ],
      );
      final json = dto.toJson();
      expect(json['roomId'], 'r1');
      expect(json['roomName'], 'Lobby');
      expect(json['capacity'], 4);
      expect((json['players'] as List).length, 1);
    });

    test('roomName key absent when null', () {
      const dto = RoomDto(roomId: 'r1', capacity: 2);
      final json = dto.toJson();
      expect(json.containsKey('roomName'), isFalse);
    });

    test('players is an empty list when none present', () {
      const dto = RoomDto(roomId: 'r1', capacity: 2);
      expect((dto.toJson()['players'] as List), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Round-trip fromJson → toJson → fromJson
  // -------------------------------------------------------------------------

  group('RoomDto round-trip', () {
    test('data is preserved after fromJson → toJson → fromJson', () {
      final original = RoomDto.fromJson({
        'roomId': 'r99',
        'roomName': 'Arena',
        'capacity': 6,
        'players': [
          _presenceJson(playerId: 'p1', playerName: 'X', isHost: true)
        ],
      });
      final restored = RoomDto.fromJson(original.toJson());
      expect(restored.roomId, original.roomId);
      expect(restored.roomName, original.roomName);
      expect(restored.capacity, original.capacity);
      expect(restored.players.length, original.players.length);
      expect(restored.players.first.playerId, original.players.first.playerId);
    });
  });
}
