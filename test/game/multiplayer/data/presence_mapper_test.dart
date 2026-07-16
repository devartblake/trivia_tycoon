import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/data/dto/presence_dto.dart';
import 'package:synaptix/game/multiplayer/data/mappers/presence_mapper.dart';
import 'package:synaptix/game/multiplayer/domain/entities/player_presence.dart';

void main() {
  const mapper = PresenceMapper();

  group('PresenceMapper.toDomain', () {
    test('maps dto fields to domain entity', () {
      const dto =
          PresenceDto(playerId: 'p1', playerName: 'Alice', isHost: true);
      final domain = mapper.toDomain(dto);
      expect(domain.id, 'p1');
      expect(domain.name, 'Alice');
      expect(domain.isHost, isTrue);
    });

    test('isHost=false maps correctly', () {
      const dto = PresenceDto(playerId: 'p2', playerName: 'Bob', isHost: false);
      expect(mapper.toDomain(dto).isHost, isFalse);
    });

    test('avatarUrl is null (not in PresenceDto)', () {
      const dto = PresenceDto(playerId: 'p', playerName: 'X');
      expect(mapper.toDomain(dto).avatarUrl, isNull);
    });
  });

  group('PresenceMapper.toDto', () {
    test('maps domain entity fields to dto', () {
      const entity = PlayerPresence(id: 'p1', name: 'Alice', isHost: true);
      final dto = mapper.toDto(entity);
      expect(dto.playerId, 'p1');
      expect(dto.playerName, 'Alice');
      expect(dto.isHost, isTrue);
    });

    test('isHost=false maps correctly', () {
      const entity = PlayerPresence(id: 'p2', name: 'Bob');
      expect(mapper.toDto(entity).isHost, isFalse);
    });
  });

  group('PresenceMapper round-trip', () {
    test('dto → domain → dto preserves all fields', () {
      const original =
          PresenceDto(playerId: 'p3', playerName: 'Charlie', isHost: false);
      final restored = mapper.toDto(mapper.toDomain(original));
      expect(restored.playerId, original.playerId);
      expect(restored.playerName, original.playerName);
      expect(restored.isHost, original.isHost);
    });

    test('entity → dto → entity preserves all fields', () {
      const entity = PlayerPresence(id: 'p4', name: 'Dana', isHost: true);
      final restored = mapper.toDomain(mapper.toDto(entity));
      expect(restored.id, entity.id);
      expect(restored.name, entity.name);
      expect(restored.isHost, entity.isHost);
    });
  });
}
