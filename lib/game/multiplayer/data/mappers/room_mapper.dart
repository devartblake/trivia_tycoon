import 'package:trivia_tycoon/game/multiplayer/domain/entities/room.dart';
import 'package:trivia_tycoon/game/multiplayer/data/dto/room_dto.dart';
import 'presence_mapper.dart';

class RoomMapper {
  final PresenceMapper _presence = const PresenceMapper();

  const RoomMapper();

  Room toDomain(RoomDto dto) => Room(
    id: dto.roomId,
    name: dto.roomName ?? 'Room',
    capacity: dto.capacity,
    players: dto.players.map(_presence.toDomain).toList(),
  );

  RoomDto toDto(Room e) => RoomDto(
    roomId: e.id,
    roomName: e.name,
    capacity: e.capacity,
    players: e.players.map(_presence.toDto).toList(),
  );
}
