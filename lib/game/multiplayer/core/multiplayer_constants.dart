/// Constants that don’t belong to protocol enums/op-codes (those live in WsProtocol).
class MultiplayerConstants {
  // Paths (HTTP)
  static const String roomsPath = '/v1/multiplayer/rooms';
  static const String matchesPath = '/v1/multiplayer/matches';
  static const String answersPath = '/v1/multiplayer/answers';

  // Header keys
  static const String hdrAuthorization = 'Authorization';
  static const String hdrContentType = 'Content-Type';
  static const String contentTypeJson = 'application/json';

  // Defaults
  static const int defaultRoomCapacity = 4;
  static const int defaultTurnMs = 12000;
}
