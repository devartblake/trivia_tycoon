import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/room.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/repositories/multiplayer_repository.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/match.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_event.dart';
import 'package:trivia_tycoon/game/multiplayer/data/sources/ws_client.dart';

class MultiplayerRepositoryImpl implements MultiplayerRepository {
  final WsClient wsClient;

  MultiplayerRepositoryImpl({WsClient? wsClient})
      : wsClient = wsClient ?? WsClient();

  @override
  Future<bool> quickMatch() async {
    await wsClient.send({
      'type': 'quick_match',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    return true;
  }

  @override
  Future<bool> createRoom(String name) async {
    await wsClient.send({
      'type': 'create_room',
      'name': name,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    return true;
  }

  @override
  Future<bool> joinRoom(String roomId) async {
    await wsClient.send({
      'type': 'join_room',
      'room_id': roomId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> listRooms() async {
    try {
      await wsClient.send({
        'type': 'list_rooms',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
// Room list arrives via the GameEvent stream (RoomListEvent).
      // Return empty synchronously; callers should watch events() for results.
      return [];
    } catch (e) {
      LogManager.error('Error listing rooms: $e',
          source: 'MultiplayerRepository');
      return [];
    }
  }

  @override
  Future<Match?> currentMatch() async {
    // Current match state is tracked via the GameEvent stream (MatchStarted / MatchUpdated).
    return null;
  }

  @override
  Stream<GameEvent> events() => wsClient.events;

  @override
  Future<Room?> currentRoom() async {
    // Current room state is tracked via GameEvent stream (JoinedRoom / PlayerJoined events).
    return null;
  }

  @override
  Future<void> leaveRoom() async {
    await wsClient.send({
      'type': 'leave_room',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> submitAnswer(
      String matchId, String questionId, String answerId) async {
    await wsClient.send({
      'type': 'submit_answer',
      'match_id': matchId,
      'question_id': questionId,
      'answer_id': answerId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
