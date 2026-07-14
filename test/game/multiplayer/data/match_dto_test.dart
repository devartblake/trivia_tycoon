import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/data/dto/match_dto.dart';
import 'package:synaptix/game/multiplayer/data/dto/presence_dto.dart';
import 'package:synaptix/game/multiplayer/data/dto/turn_dto.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _presenceJson({
  String playerId = 'p1',
  String playerName = 'Alice',
  bool isHost = false,
}) =>
    {'playerId': playerId, 'playerName': playerName, 'isHost': isHost};

Map<String, dynamic> _turnJson({
  String questionId = 'q1',
  int startAtMs = 1000,
  int endAtMs = 31000,
}) =>
    {'questionId': questionId, 'startAtMs': startAtMs, 'endAtMs': endAtMs};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // fromJson
  // -------------------------------------------------------------------------

  group('MatchDto.fromJson', () {
    test('parses all fields', () {
      final dto = MatchDto.fromJson({
        'matchId': 'm1',
        'roomId': 'r1',
        'players': [_presenceJson(isHost: true)],
        'currentTurn': _turnJson(),
      });
      expect(dto.matchId, 'm1');
      expect(dto.roomId, 'r1');
      expect(dto.players.length, 1);
      expect(dto.players.first.isHost, isTrue);
      expect(dto.currentTurn?.questionId, 'q1');
    });

    test('players defaults to empty list when absent', () {
      final dto = MatchDto.fromJson({'matchId': 'm1', 'roomId': 'r1'});
      expect(dto.players, isEmpty);
    });

    test('currentTurn is null when absent', () {
      final dto = MatchDto.fromJson({'matchId': 'm1', 'roomId': 'r1'});
      expect(dto.currentTurn, isNull);
    });

    test('currentTurn is null when not a Map', () {
      final dto = MatchDto.fromJson({
        'matchId': 'm1',
        'roomId': 'r1',
        'currentTurn': 'not-a-map',
      });
      expect(dto.currentTurn, isNull);
    });

    test('matchId coerced from int via toString', () {
      final dto = MatchDto.fromJson({'matchId': 42, 'roomId': 'r1'});
      expect(dto.matchId, '42');
    });

    test('multiple players parsed correctly', () {
      final dto = MatchDto.fromJson({
        'matchId': 'm1',
        'roomId': 'r1',
        'players': [
          _presenceJson(playerId: 'p1', isHost: true),
          _presenceJson(playerId: 'p2'),
        ],
      });
      expect(dto.players.length, 2);
      expect(dto.players[0].playerId, 'p1');
      expect(dto.players[1].playerId, 'p2');
    });

    test('non-Map entries in players list are skipped', () {
      final dto = MatchDto.fromJson({
        'matchId': 'm1',
        'roomId': 'r1',
        'players': ['invalid', 42, null],
      });
      expect(dto.players, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // toJson
  // -------------------------------------------------------------------------

  group('MatchDto.toJson', () {
    test('serialises all fields when currentTurn is present', () {
      final dto = MatchDto(
        matchId: 'm1',
        roomId: 'r1',
        players: [const PresenceDto(playerId: 'p1', playerName: 'Alice')],
        currentTurn:
            const TurnDto(questionId: 'q1', startAtMs: 0, endAtMs: 1000),
      );
      final json = dto.toJson();
      expect(json['matchId'], 'm1');
      expect(json['roomId'], 'r1');
      expect((json['players'] as List).length, 1);
      expect((json['currentTurn'] as Map)['questionId'], 'q1');
    });

    test('currentTurn key absent when null', () {
      const dto = MatchDto(matchId: 'm1', roomId: 'r1');
      final json = dto.toJson();
      expect(json.containsKey('currentTurn'), isFalse);
    });

    test('players is empty list when no players', () {
      const dto = MatchDto(matchId: 'm1', roomId: 'r1');
      expect((dto.toJson()['players'] as List), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Round-trip
  // -------------------------------------------------------------------------

  group('MatchDto round-trip', () {
    test('fromJson → toJson → fromJson preserves all values', () {
      final original = MatchDto.fromJson({
        'matchId': 'm-round',
        'roomId': 'r-round',
        'players': [_presenceJson(playerId: 'p99', isHost: true)],
        'currentTurn': _turnJson(questionId: 'q-round'),
      });
      final restored = MatchDto.fromJson(original.toJson());
      expect(restored.matchId, original.matchId);
      expect(restored.roomId, original.roomId);
      expect(restored.players.length, original.players.length);
      expect(restored.players.first.playerId, original.players.first.playerId);
      expect(
          restored.currentTurn?.questionId, original.currentTurn?.questionId);
    });
  });
}
