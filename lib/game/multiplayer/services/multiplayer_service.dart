import 'dart:async';
import 'package:trivia_tycoon/game/multiplayer/core/multiplayer_config.dart';
import 'package:trivia_tycoon/game/multiplayer/data/repositories/multiplayer_repository_impl.dart';
import 'package:trivia_tycoon/game/multiplayer/data/sources/ws_client.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_event.dart';

class MultiplayerService {
  final MultiplayerRepositoryImpl _repo;
  final WsClient _ws;
  final MultiplayerConfig _config;

  MultiplayerService({
    MultiplayerRepositoryImpl? repo,
    WsClient? ws,
    MultiplayerConfig? config,
    Object? configStorage,
  })  : _repo = repo ?? MultiplayerRepositoryImpl(),
        _ws = ws ?? WsClient(),
        _config = config ?? MultiplayerConfig(
          httpBase: Uri.parse('https://api.example.com'),
          wsUri: Uri.parse('wss://api.example.com/ws'),
        );

  int get lastLatencyMs => _ws.lastRttMs;

  /// Typed events feed for controllers/UI.
  Stream<GameEvent> get events => _repo.events();

  Future<bool> connect({required String token}) async {
    // Optionally derive URI/token from configStorage here.
    return _ws.connect(uri: _config.wsUri, token: token);
  }

  Future<void> disconnect() => _ws.disconnect();

  // High-level façade methods
  Future<bool> quickMatch() => _repo.quickMatch();
  Future<bool> createRoom(String name) => _repo.createRoom(name);
  Future<bool> joinRoom(String roomId) => _repo.joinRoom(roomId);

  Future<void> submitAnswer(String matchId, String questionId, String answerId) async {
    // TODO: implement server call via wsClient.send
  }

  Future<List<Map<String, dynamic>>> listRooms() async {
    // TODO: implement server call via wsClient.send
    return [];
  }
}
