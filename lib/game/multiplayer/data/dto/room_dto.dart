import 'presence_dto.dart';

class RoomDto {
  final String roomId;
  final String? roomName;
  final int capacity;
  final List<PresenceDto> players;

  const RoomDto({
    required this.roomId,
    this.roomName,
    required this.capacity,
    this.players = const [],
  });

  factory RoomDto.fromJson(Map<String, dynamic> j) => RoomDto(
    roomId: (j['roomId'] ?? '').toString(),
    roomName: j['roomName']?.toString(),
    capacity: (j['capacity'] is int)
        ? j['capacity'] as int
        : int.tryParse('${j['capacity'] ?? 0}') ?? 0,
    players: (j['players'] as List? ?? [])
        .whereType<Map>()
        .map((e) => PresenceDto.fromJson(e.cast<String, dynamic>()))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    if (roomName != null) 'roomName': roomName,
    'capacity': capacity,
    'players': players.map((e) => e.toJson()).toList(),
  };
}
