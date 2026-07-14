import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/data/dto/presence_dto.dart';
import 'package:synaptix/game/multiplayer/data/dto/room_dto.dart';
import 'package:synaptix/game/multiplayer/data/mappers/presence_mapper.dart';
import 'package:synaptix/game/multiplayer/data/mappers/room_mapper.dart';
import 'package:synaptix/game/multiplayer/domain/entities/player_presence.dart';
import 'package:synaptix/game/multiplayer/domain/entities/room.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _mapper = RoomMapper();

const _hostDto = PresenceDto(playerId: 'p1', playerName: 'Alice', isHost: true);
const _guestDto = PresenceDto(playerId: 'p2', playerName: 'Bob');

const _hostPresence = PlayerPresence(id: 'p1', name: 'Alice', isHost: true);
const _guestPresence = PlayerPresence(id: 'p2', name: 'Bob');

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // toDomain
  // -------------------------------------------------------------------------

  group('RoomMapper.toDomain', () {
    test('maps roomId → id', () {
      final dto = RoomDto(roomId: 'r42', capacity: 4);
      final room = _mapper.toDomain(dto);
      expect(room.id, 'r42');
    });

    test('maps capacity', () {
      final dto = RoomDto(roomId: 'r1', capacity: 8);
      expect(_mapper.toDomain(dto).capacity, 8);
    });

    test('maps roomName → name', () {
      final dto = RoomDto(roomId: 'r1', roomName: 'Lobby', capacity: 4);
      expect(_mapper.toDomain(dto).name, 'Lobby');
    });

    test('uses "Room" as default name when roomName is null', () {
      final dto = RoomDto(roomId: 'r1', capacity: 4);
      expect(_mapper.toDomain(dto).name, 'Room');
    });

    test('maps players via PresenceMapper', () {
      final dto = RoomDto(
        roomId: 'r1',
        capacity: 4,
        players: [_hostDto, _guestDto],
      );
      final room = _mapper.toDomain(dto);
      expect(room.players.length, 2);
      expect(room.players[0].id, 'p1');
      expect(room.players[0].isHost, isTrue);
      expect(room.players[1].id, 'p2');
      expect(room.players[1].isHost, isFalse);
    });

    test('empty players list is preserved', () {
      final dto = RoomDto(roomId: 'r1', capacity: 4);
      expect(_mapper.toDomain(dto).players, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // toDto
  // -------------------------------------------------------------------------

  group('RoomMapper.toDto', () {
    test('maps id → roomId', () {
      final room = Room(id: 'r77', capacity: 4);
      expect(_mapper.toDto(room).roomId, 'r77');
    });

    test('maps capacity', () {
      final room = Room(id: 'r1', capacity: 6);
      expect(_mapper.toDto(room).capacity, 6);
    });

    test('maps name → roomName', () {
      final room = Room(id: 'r1', name: 'Arena', capacity: 4);
      expect(_mapper.toDto(room).roomName, 'Arena');
    });

    test('roomName is null when Room.name is null', () {
      final room = Room(id: 'r1', capacity: 4);
      expect(_mapper.toDto(room).roomName, isNull);
    });

    test('maps players via PresenceMapper', () {
      final room = Room(
        id: 'r1',
        capacity: 4,
        players: [_hostPresence, _guestPresence],
      );
      final dto = _mapper.toDto(room);
      expect(dto.players.length, 2);
      expect(dto.players[0].playerId, 'p1');
      expect(dto.players[0].isHost, isTrue);
      expect(dto.players[1].playerId, 'p2');
    });
  });

  // -------------------------------------------------------------------------
  // Round-trip: toDomain(toDto(room))
  // -------------------------------------------------------------------------

  group('RoomMapper round-trip', () {
    test('toDomain(toDto(room)) preserves all fields', () {
      final original = Room(
        id: 'r1',
        name: 'Lobby',
        capacity: 4,
        players: [_hostPresence, _guestPresence],
        isHost: true,
      );
      final restored = _mapper.toDomain(_mapper.toDto(original));
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.capacity, original.capacity);
      expect(restored.players.length, original.players.length);
      expect(restored.players[0].id, original.players[0].id);
      expect(restored.players[0].isHost, original.players[0].isHost);
    });

    test('toDto(toDomain(dto)) preserves all fields', () {
      final original = RoomDto(
        roomId: 'r2',
        roomName: 'Arena',
        capacity: 8,
        players: [_hostDto, _guestDto],
      );
      final restored = _mapper.toDto(_mapper.toDomain(original));
      expect(restored.roomId, original.roomId);
      expect(restored.roomName, original.roomName);
      expect(restored.capacity, original.capacity);
      expect(restored.players.length, original.players.length);
    });
  });

  // -------------------------------------------------------------------------
  // PresenceMapper (used internally, tested via RoomMapper)
  // -------------------------------------------------------------------------

  group('PresenceMapper (standalone)', () {
    const pm = PresenceMapper();

    test('toDomain maps playerId → id and playerName → name', () {
      final p = pm.toDomain(_hostDto);
      expect(p.id, 'p1');
      expect(p.name, 'Alice');
      expect(p.isHost, isTrue);
    });

    test('toDto maps id → playerId and name → playerName', () {
      final dto = pm.toDto(_hostPresence);
      expect(dto.playerId, 'p1');
      expect(dto.playerName, 'Alice');
      expect(dto.isHost, isTrue);
    });
  });
}
