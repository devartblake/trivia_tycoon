import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/multiplayer/data/dto/match_dto.dart';
import 'package:trivia_tycoon/game/multiplayer/data/dto/presence_dto.dart';
import 'package:trivia_tycoon/game/multiplayer/data/dto/turn_dto.dart';
import 'package:trivia_tycoon/game/multiplayer/data/mappers/match_mapper.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_turn.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/match.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/player_presence.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _mapper = MatchMapper();

// Epoch ms for a known UTC instant: 2026-01-01T12:00:00Z
const int _startMs = 1767254400000; // 2026-01-01 12:00:00 UTC
const int _endMs = 1767254430000; // 2026-01-01 12:00:30 UTC

final DateTime _startDt = DateTime.fromMillisecondsSinceEpoch(_startMs, isUtc: true);
final DateTime _endDt = DateTime.fromMillisecondsSinceEpoch(_endMs, isUtc: true);

const _hostDto = PresenceDto(playerId: 'p1', playerName: 'Alice', isHost: true);
const _guestDto = PresenceDto(playerId: 'p2', playerName: 'Bob');

const _hostPresence = PlayerPresence(id: 'p1', name: 'Alice', isHost: true);
const _guestPresence = PlayerPresence(id: 'p2', name: 'Bob');

TurnDto get _turnDto => TurnDto(
      questionId: 'q1',
      startAtMs: _startMs,
      endAtMs: _endMs,
    );

GameTurn get _turn => GameTurn(
      questionId: 'q1',
      startAt: _startDt,
      endAt: _endDt,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // toDomain
  // -------------------------------------------------------------------------

  group('MatchMapper.toDomain', () {
    test('maps matchId → id and roomId', () {
      final dto = MatchDto(matchId: 'm42', roomId: 'r1');
      final match = _mapper.toDomain(dto);
      expect(match.id, 'm42');
      expect(match.roomId, 'r1');
    });

    test('maps players via PresenceMapper', () {
      final dto = MatchDto(
        matchId: 'm1',
        roomId: 'r1',
        players: [_hostDto, _guestDto],
      );
      final match = _mapper.toDomain(dto);
      expect(match.players.length, 2);
      expect(match.players[0].id, 'p1');
      expect(match.players[0].isHost, isTrue);
      expect(match.players[1].id, 'p2');
    });

    test('currentTurn is null when dto has no turn', () {
      final dto = MatchDto(matchId: 'm1', roomId: 'r1');
      expect(_mapper.toDomain(dto).currentTurn, isNull);
    });

    test('maps TurnDto → GameTurn correctly', () {
      final dto = MatchDto(matchId: 'm1', roomId: 'r1', currentTurn: _turnDto);
      final turn = _mapper.toDomain(dto).currentTurn!;
      expect(turn.questionId, 'q1');
      expect(turn.startAt, _startDt);
      expect(turn.endAt, _endDt);
    });

    test('empty players list is preserved', () {
      final dto = MatchDto(matchId: 'm1', roomId: 'r1');
      expect(_mapper.toDomain(dto).players, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // toDto
  // -------------------------------------------------------------------------

  group('MatchMapper.toDto', () {
    test('maps id → matchId and roomId', () {
      final match = Match(id: 'm77', roomId: 'r99');
      final dto = _mapper.toDto(match);
      expect(dto.matchId, 'm77');
      expect(dto.roomId, 'r99');
    });

    test('maps players via PresenceMapper', () {
      final match = Match(
        id: 'm1',
        roomId: 'r1',
        players: [_hostPresence, _guestPresence],
      );
      final dto = _mapper.toDto(match);
      expect(dto.players.length, 2);
      expect(dto.players[0].playerId, 'p1');
      expect(dto.players[0].isHost, isTrue);
    });

    test('currentTurn is null when match has no turn', () {
      final match = Match(id: 'm1', roomId: 'r1');
      expect(_mapper.toDto(match).currentTurn, isNull);
    });

    test('maps GameTurn → TurnDto with epoch ms', () {
      final match = Match(id: 'm1', roomId: 'r1', currentTurn: _turn);
      final dto = _mapper.toDto(match).currentTurn!;
      expect(dto.questionId, 'q1');
      expect(dto.startAtMs, _startMs);
      expect(dto.endAtMs, _endMs);
    });
  });

  // -------------------------------------------------------------------------
  // Round-trip
  // -------------------------------------------------------------------------

  group('MatchMapper round-trip', () {
    test('toDomain(toDto(match)) preserves id, roomId, players, and turn', () {
      final original = Match(
        id: 'm1',
        roomId: 'r1',
        players: [_hostPresence, _guestPresence],
        currentTurn: _turn,
      );
      final restored = _mapper.toDomain(_mapper.toDto(original));
      expect(restored.id, original.id);
      expect(restored.roomId, original.roomId);
      expect(restored.players.length, original.players.length);
      expect(restored.players[0].id, original.players[0].id);
      expect(restored.currentTurn?.questionId, original.currentTurn?.questionId);
      expect(restored.currentTurn?.startAt, original.currentTurn?.startAt);
    });

    test('toDto(toDomain(dto)) preserves matchId, roomId, players, and turn', () {
      final original = MatchDto(
        matchId: 'm2',
        roomId: 'r2',
        players: [_hostDto, _guestDto],
        currentTurn: _turnDto,
      );
      final restored = _mapper.toDto(_mapper.toDomain(original));
      expect(restored.matchId, original.matchId);
      expect(restored.roomId, original.roomId);
      expect(restored.players.length, original.players.length);
      expect(restored.currentTurn?.questionId, original.currentTurn?.questionId);
      expect(restored.currentTurn?.startAtMs, original.currentTurn?.startAtMs);
    });
  });
}
