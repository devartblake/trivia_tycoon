import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/data/dto/presence_dto.dart';

void main() {
  group('PresenceDto.fromJson', () {
    test('parses all fields', () {
      final dto = PresenceDto.fromJson({
        'playerId': 'p1',
        'playerName': 'Alice',
        'isHost': true,
      });
      expect(dto.playerId, 'p1');
      expect(dto.playerName, 'Alice');
      expect(dto.isHost, isTrue);
    });

    test('isHost defaults to false when absent', () {
      final dto = PresenceDto.fromJson({'playerId': 'p2', 'playerName': 'Bob'});
      expect(dto.isHost, isFalse);
    });

    test('isHost accepts integer 1', () {
      final dto = PresenceDto.fromJson(
          {'playerId': 'p', 'playerName': 'N', 'isHost': 1});
      expect(dto.isHost, isTrue);
    });

    test('isHost accepts string "true"', () {
      final dto = PresenceDto.fromJson(
          {'playerId': 'p', 'playerName': 'N', 'isHost': 'true'});
      expect(dto.isHost, isTrue);
    });

    test('isHost rejects integer 0', () {
      final dto = PresenceDto.fromJson(
          {'playerId': 'p', 'playerName': 'N', 'isHost': 0});
      expect(dto.isHost, isFalse);
    });

    test('playerId defaults to empty string when absent', () {
      final dto = PresenceDto.fromJson({'playerName': 'N'});
      expect(dto.playerId, '');
    });

    test('playerName defaults to empty string when absent', () {
      final dto = PresenceDto.fromJson({'playerId': 'p'});
      expect(dto.playerName, '');
    });
  });

  group('PresenceDto.toJson', () {
    test('round-trip preserves all fields', () {
      const original =
          PresenceDto(playerId: 'p1', playerName: 'Alice', isHost: true);
      final restored = PresenceDto.fromJson(original.toJson());
      expect(restored.playerId, original.playerId);
      expect(restored.playerName, original.playerName);
      expect(restored.isHost, original.isHost);
    });

    test('toJson contains exactly three keys', () {
      const dto = PresenceDto(playerId: 'x', playerName: 'Y');
      expect(dto.toJson().keys.toSet(), {'playerId', 'playerName', 'isHost'});
    });

    test('isHost=false round-trips correctly', () {
      const dto = PresenceDto(playerId: 'p', playerName: 'N', isHost: false);
      final restored = PresenceDto.fromJson(dto.toJson());
      expect(restored.isHost, isFalse);
    });
  });
}
