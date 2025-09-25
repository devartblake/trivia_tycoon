import 'presence_dto.dart';
import 'turn_dto.dart';

class MatchDto {
  final String matchId;
  final String roomId;
  final List<PresenceDto> players;
  final TurnDto? currentTurn;

  const MatchDto({
    required this.matchId,
    required this.roomId,
    this.players = const [],
    this.currentTurn,
  });

  factory MatchDto.fromJson(Map<String, dynamic> j) => MatchDto(
    matchId: (j['matchId'] ?? '').toString(),
    roomId: (j['roomId'] ?? '').toString(),
    players: (j['players'] as List? ?? [])
        .whereType<Map>()
        .map((e) => PresenceDto.fromJson(e.cast<String, dynamic>()))
        .toList(),
    currentTurn: (j['currentTurn'] is Map)
        ? TurnDto.fromJson((j['currentTurn'] as Map).cast<String, dynamic>())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'matchId': matchId,
    'roomId': roomId,
    'players': players.map((e) => e.toJson()).toList(),
    if (currentTurn != null) 'currentTurn': currentTurn!.toJson(),
  };
}
