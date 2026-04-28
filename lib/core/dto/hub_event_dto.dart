/// DTOs for server-push events received from SignalR hubs.

class PlayerNotificationDto {
  final String type;
  final String message;
  final Map<String, dynamic>? payload;

  const PlayerNotificationDto({
    required this.type,
    required this.message,
    this.payload,
  });

  factory PlayerNotificationDto.fromJson(Map<String, dynamic> j) =>
      PlayerNotificationDto(
        type: j['type'] as String? ?? '',
        message: j['message'] as String? ?? '',
        payload: j['payload'] as Map<String, dynamic>?,
      );
}

class MatchUpdateDto {
  final String matchId;
  final String status;
  final Map<String, dynamic>? data;

  const MatchUpdateDto({
    required this.matchId,
    required this.status,
    this.data,
  });

  factory MatchUpdateDto.fromJson(Map<String, dynamic> j) => MatchUpdateDto(
        matchId: j['matchId'] as String,
        status: j['status'] as String? ?? '',
        data: j['data'] as Map<String, dynamic>?,
      );
}

class GameEventEliminationDto {
  final String gameEventId;
  final String eliminatedPlayerId;
  final int aliveCount;
  final DateTime timestamp;

  const GameEventEliminationDto({
    required this.gameEventId,
    required this.eliminatedPlayerId,
    required this.aliveCount,
    required this.timestamp,
  });

  factory GameEventEliminationDto.fromJson(Map<String, dynamic> j) =>
      GameEventEliminationDto(
        gameEventId: j['gameEventId'] as String,
        eliminatedPlayerId: j['eliminatedPlayerId'] as String,
        aliveCount: j['aliveCount'] as int? ?? 0,
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}

class GameEventClosedDto {
  final String gameEventId;
  final String winnerId;
  final DateTime closedAt;

  const GameEventClosedDto({
    required this.gameEventId,
    required this.winnerId,
    required this.closedAt,
  });

  factory GameEventClosedDto.fromJson(Map<String, dynamic> j) =>
      GameEventClosedDto(
        gameEventId: j['gameEventId'] as String,
        winnerId: j['winnerId'] as String,
        closedAt:
            DateTime.tryParse(j['closedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class GuardianChangedDto {
  final String seasonId;
  final int tierNumber;
  final String newGuardianPlayerId;
  final String newGuardianUsername;
  final String previousGuardianPlayerId;

  const GuardianChangedDto({
    required this.seasonId,
    required this.tierNumber,
    required this.newGuardianPlayerId,
    required this.newGuardianUsername,
    required this.previousGuardianPlayerId,
  });

  factory GuardianChangedDto.fromJson(Map<String, dynamic> j) =>
      GuardianChangedDto(
        seasonId: j['seasonId'] as String,
        tierNumber: j['tierNumber'] as int? ?? 1,
        newGuardianPlayerId: j['newGuardianPlayerId'] as String,
        newGuardianUsername: j['newGuardianUsername'] as String,
        previousGuardianPlayerId: j['previousGuardianPlayerId'] as String,
      );
}

class TerritoryCaptureDto {
  final String seasonId;
  final int tierNumber;
  final String tileId;
  final String newOwnerId;
  final String newOwnerUsername;
  final String? previousOwnerId;

  const TerritoryCaptureDto({
    required this.seasonId,
    required this.tierNumber,
    required this.tileId,
    required this.newOwnerId,
    required this.newOwnerUsername,
    this.previousOwnerId,
  });

  factory TerritoryCaptureDto.fromJson(Map<String, dynamic> j) =>
      TerritoryCaptureDto(
        seasonId: j['seasonId'] as String,
        tierNumber: j['tierNumber'] as int? ?? 1,
        tileId: j['tileId'] as String,
        newOwnerId: j['newOwnerId'] as String,
        newOwnerUsername: j['newOwnerUsername'] as String,
        previousOwnerId: j['previousOwnerId'] as String?,
      );
}

class VoteTallyUpdatedDto {
  final String topic;
  final Map<String, int> tally;
  final int totalVotes;

  const VoteTallyUpdatedDto({
    required this.topic,
    required this.tally,
    required this.totalVotes,
  });

  factory VoteTallyUpdatedDto.fromJson(Map<String, dynamic> j) =>
      VoteTallyUpdatedDto(
        topic: j['topic'] as String,
        tally: (j['tally'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            ) ??
            {},
        totalVotes: j['totalVotes'] as int? ?? 0,
      );
}

class DirectMessagesUpdatedDto {
  final String playerId;
  final String conversationId;
  final int unreadCount;
  final String reason;
  final DateTime occurredAtUtc;

  const DirectMessagesUpdatedDto({
    required this.playerId,
    required this.conversationId,
    required this.unreadCount,
    required this.reason,
    required this.occurredAtUtc,
  });

  factory DirectMessagesUpdatedDto.fromJson(Map<String, dynamic> j) =>
      DirectMessagesUpdatedDto(
        playerId: j['playerId'] as String? ?? '',
        conversationId: j['conversationId'] as String? ?? '',
        unreadCount: j['unreadCount'] as int? ?? 0,
        reason: j['reason'] as String? ?? '',
        occurredAtUtc:
            DateTime.tryParse(j['occurredAtUtc'] as String? ?? '') ??
                DateTime.now(),
      );
}
