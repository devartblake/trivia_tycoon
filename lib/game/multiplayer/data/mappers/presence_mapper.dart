import 'package:trivia_tycoon/game/multiplayer/domain/entities/player_presence.dart';
import 'package:trivia_tycoon/game/multiplayer/data/dto/presence_dto.dart';

class PresenceMapper {
  const PresenceMapper();

  PlayerPresence toDomain(PresenceDto dto) => PlayerPresence(
    id: dto.playerId,
    name: dto.playerName,
    isHost: dto.isHost,
  );

  PresenceDto toDto(PlayerPresence e) => PresenceDto(
    playerId: e.id,
    playerName: e.name,
    isHost: e.isHost,
  );
}
