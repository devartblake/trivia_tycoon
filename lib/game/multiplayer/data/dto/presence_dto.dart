class PresenceDto {
  final String playerId;
  final String playerName;
  final bool isHost;

  const PresenceDto({
    required this.playerId,
    required this.playerName,
    this.isHost = false,
  });

  factory PresenceDto.fromJson(Map<String, dynamic> j) => PresenceDto(
    playerId: (j['playerId'] ?? '').toString(),
    playerName: (j['playerName'] ?? '').toString(),
    isHost: j['isHost'] == true || j['isHost'] == 1 || j['isHost'] == 'true',
  );

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    'isHost': isHost,
  };
}
