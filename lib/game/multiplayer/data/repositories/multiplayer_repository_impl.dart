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
    // TODO: implement server call via wsClient.send or HTTP
    return true;
  }

  @override
  Future<bool> createRoom(String name) async {
    // TODO: implement server call
    return true;
  }

  @override
  Future<bool> joinRoom(String roomId) async {
    // TODO: implement server call
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> listRooms() async {
    try {
      // TODO: Replace with actual server call
      // For now, return mock data for development/testing
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

      return [
        {
          'roomId': 'room_001',
          'name': 'Quiz Masters',
          'playerCount': 3,
          'maxPlayers': 8,
          'isPublic': true,
          'gameMode': 'classic',
          'status': 'waiting',
          'created': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        },
        {
          'roomId': 'room_002',
          'name': 'Brain Busters',
          'playerCount': 2,
          'maxPlayers': 6,
          'isPublic': true,
          'gameMode': 'speed',
          'status': 'waiting',
          'created': DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
        },
        {
          'roomId': 'room_003',
          'name': 'Trivia Champions',
          'playerCount': 5,
          'maxPlayers': 8,
          'isPublic': true,
          'gameMode': 'classic',
          'status': 'in_game',
          'created': DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
        },
      ];

      // Real implementation would look like:
      /*
      final response = await wsClient.send({
        'type': 'list_rooms',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['rooms']);
      } else {
        throw Exception('Failed to list rooms: ${response['error']}');
      }
      */
    } catch (e) {
      // Log error and return empty list for graceful degradation
      print('Error listing rooms: $e');
      return [];
    }
  }

  @override
  Future<Match?> currentMatch() async {
    // TODO: query server or local cache
    return null;
  }

  @override
  Stream<GameEvent> events() => wsClient.events;

  @override
  Future<Room?> currentRoom() {
    // TODO: implement currentRoom
    throw UnimplementedError();
  }

  @override
  Future<void> leaveRoom() {
    // TODO: implement leaveRoom
    throw UnimplementedError();
  }

  @override
  Future<void> submitAnswer(String matchId, String questionId, String answerId) {
    // TODO: implement submitAnswer
    throw UnimplementedError();
  }
}
