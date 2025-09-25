import 'package:trivia_tycoon/game/multiplayer/domain/entities/match.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/room.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_event.dart';

/// Domain-facing contract for multiplayer data operations.
/// Implemented by your data layer (WebSocket/HTTP), consumed by controllers/services.
///
/// Keep this **transport-agnostic** (no WS specifics leak in here).
abstract class MultiplayerRepository {
  /// Stream of **domain events** mapped from the transport (WebSocket).
  Stream<GameEvent> events();

  // ----- Room / Lobby -----

  /// Creates a room with the given [name]. Returns `true` on accepted request.
  /// Expect a subsequent [JoinedRoom] / [PlayerJoined] event to confirm state.
  Future<bool> createRoom(String name);

  /// Attempts to join an existing room by id. Returns `true` if the request
  /// was accepted. Expect a [JoinedRoom] event to confirm.
  Future<bool> joinRoom(String roomId);

  /// Lists available rooms that can be joined.
  /// Returns list of room metadata for display in lobby.
  Future<List<Map<String, dynamic>>> listRooms();

  /// Leaves the current room/match context if supported by the backend.
  /// Optional in early versions—no-op if not implemented.
  Future<void> leaveRoom() async {}

  /// Optionally fetch the current room snapshot (if your server exposes it).
  Future<Room?> currentRoom() async => null;

  // ----- Match -----

  /// Quick play entrypoint (queue + join/create behind the scenes).
  Future<bool> quickMatch();

  /// Optionally fetch the current match snapshot (if exposed by the backend).
  Future<Match?> currentMatch();

  /// Submits the player's answer for the current question.
  /// Expect [AnswerAccepted]/[AnswerRejected] events to follow.
  Future<void> submitAnswer(String matchId, String questionId, String answerId) async {}
}
