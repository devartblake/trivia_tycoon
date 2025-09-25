/// Base multiplayer event model.
///
/// Keep events small and serializable; the repository or service layer should
/// convert from DTOs to these domain events. Controllers subscribe to a
/// `Stream<GameEvent>` and update app state accordingly.
abstract class GameEvent {
  const GameEvent();
}

/// Emitted after the client successfully joins a room.
class JoinedRoom extends GameEvent {
  final String roomId;
  final String? roomName;
  const JoinedRoom(this.roomId, {this.roomName});

  @override
  String toString() => 'JoinedRoom(roomId: $roomId, roomName: $roomName)';
}

/// A player entered the room.
class PlayerJoined extends GameEvent {
  final String roomId;
  final String playerId;
  final String playerName;
  final bool isHost;
  const PlayerJoined({
    required this.roomId,
    required this.playerId,
    required this.playerName,
    this.isHost = false,
  });

  @override
  String toString() =>
      'PlayerJoined(roomId: $roomId, playerId: $playerId, playerName: $playerName, isHost: $isHost)';
}

/// A player left the room.
class PlayerLeft extends GameEvent {
  final String roomId;
  final String playerId;
  const PlayerLeft({required this.roomId, required this.playerId});

  @override
  String toString() => 'PlayerLeft(roomId: $roomId, playerId: $playerId)';
}

/// Host role transferred to another player.
class HostChanged extends GameEvent {
  final String roomId;
  final String newHostPlayerId;
  const HostChanged({required this.roomId, required this.newHostPlayerId});

  @override
  String toString() =>
      'HostChanged(roomId: $roomId, newHostPlayerId: $newHostPlayerId)';
}

/// Match formally started inside a room.
class MatchStarted extends GameEvent {
  final String matchId;
  final String roomId;
  const MatchStarted({required this.matchId, required this.roomId});

  @override
  String toString() => 'MatchStarted(matchId: $matchId, roomId: $roomId)';
}

/// New question/turn is live.
class TurnStarted extends GameEvent {
  final String matchId;
  final String questionId;
  final int? durationMs; // optional server-provided duration
  const TurnStarted({
    required this.matchId,
    required this.questionId,
    this.durationMs,
  });

  @override
  String toString() =>
      'TurnStarted(matchId: $matchId, questionId: $questionId, durationMs: $durationMs)';
}

/// The server reveals the correct answer and any metadata (streaks, multipliers).
class TurnRevealed extends GameEvent {
  final String matchId;
  final String questionId;
  final String correctAnswerId;
  final Map<String, bool> playerCorrectMap; // playerId -> wasCorrect
  const TurnRevealed({
    required this.matchId,
    required this.questionId,
    required this.correctAnswerId,
    this.playerCorrectMap = const {},
  });

  @override
  String toString() =>
      'TurnRevealed(matchId: $matchId, questionId: $questionId, correct: $correctAnswerId, results: ${playerCorrectMap.length})';
}

/// The player's answer has been accepted by the server.
class AnswerAccepted extends GameEvent {
  final String matchId;
  final String questionId;
  final String playerId;
  final String answerId;
  const AnswerAccepted({
    required this.matchId,
    required this.questionId,
    required this.playerId,
    required this.answerId,
  });

  @override
  String toString() =>
      'AnswerAccepted(matchId: $matchId, q: $questionId, player: $playerId, answer: $answerId)';
}

/// The player's answer was rejected (late, invalid, duplicate, etc.).
class AnswerRejected extends GameEvent {
  final String matchId;
  final String questionId;
  final String playerId;
  final String reason;
  const AnswerRejected({
    required this.matchId,
    required this.questionId,
    required this.playerId,
    required this.reason,
  });

  @override
  String toString() =>
      'AnswerRejected(matchId: $matchId, q: $questionId, player: $playerId, reason: $reason)';
}

/// Final match summary; use a DTO->mapper to attach detailed results if needed.
class MatchEnded extends GameEvent {
  final String matchId;
  final String roomId;
  const MatchEnded({required this.matchId, required this.roomId});

  @override
  String toString() => 'MatchEnded(matchId: $matchId, roomId: $roomId)';
}

/// Informational server notice (maintenance, countdown, etc.).
class ServerNotice extends GameEvent {
  final String code;    // e.g., "maintenance", "server_restart"
  final String message; // user-facing string
  const ServerNotice({required this.code, required this.message});

  @override
  String toString() => 'ServerNotice(code: $code, message: $message)';
}

/// Indicates the server kicked the client (duplicate login, moderation, etc.).
class Kicked extends GameEvent {
  final String reason;
  const Kicked({required this.reason});

  @override
  String toString() => 'Kicked(reason: $reason)';
}

/// Generic error surfaced as an event (protocol violation, deserialization error, etc.).
class ProtocolError extends GameEvent {
  final String message;
  const ProtocolError(this.message);

  @override
  String toString() => 'ProtocolError(message: $message)';
}
