import 'package:trivia_tycoon/game/multiplayer/domain/entities/match.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_turn.dart';
import 'package:trivia_tycoon/game/multiplayer/data/dto/match_dto.dart';
import 'package:trivia_tycoon/game/multiplayer/data/dto/turn_dto.dart';
import 'presence_mapper.dart';

class MatchMapper {
  final PresenceMapper _presence = const PresenceMapper();

  const MatchMapper();

  Match toDomain(MatchDto dto) => Match(
    id: dto.matchId,
    roomId: dto.roomId,
    players: dto.players.map(_presence.toDomain).toList(),
    currentTurn: dto.currentTurn != null ? _turnToDomain(dto.currentTurn!) : null,
  );

  MatchDto toDto(Match e) => MatchDto(
    matchId: e.id,
    roomId: e.roomId,
    players: e.players.map(_presence.toDto).toList(),
    currentTurn: e.currentTurn != null ? _turnToDto(e.currentTurn!) : null,
  );

  // --- helpers ---
  GameTurn _turnToDomain(TurnDto d) => GameTurn(
    questionId: d.questionId,
    startAt: DateTime.fromMillisecondsSinceEpoch(d.startAtMs, isUtc: true),
    endAt: DateTime.fromMillisecondsSinceEpoch(d.endAtMs, isUtc: true),
  );

  TurnDto _turnToDto(GameTurn t) => TurnDto(
    questionId: t.questionId,
    startAtMs: t.startAt.toUtc().millisecondsSinceEpoch,
    endAtMs: t.endAt.toUtc().millisecondsSinceEpoch,
  );
}
