import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/multiplayer/services/multiplayer_service.dart';
import 'package:trivia_tycoon/game/multiplayer/application/controllers/multiplayer_controller.dart';
import 'package:trivia_tycoon/game/multiplayer/application/controllers/room_controller.dart';
import 'package:trivia_tycoon/game/multiplayer/application/controllers/match_controller.dart';
import 'package:trivia_tycoon/game/multiplayer/application/state/multiplayer_state.dart';
import 'package:trivia_tycoon/game/multiplayer/application/state/room_state.dart';
import 'package:trivia_tycoon/game/multiplayer/application/state/match_state.dart';
import '../../providers/riverpod_providers.dart';
import '../domain/entities/player_presence.dart';

// Service Provider
final multiplayerServiceProvider = Provider<MultiplayerService>((ref) {
  final sm = ref.watch(serviceManagerProvider);
  return sm.multiplayerService; // Make sure ServiceManager has this property
});

// Controller Providers (StateNotifiers)
final multiplayerControllerProvider =
StateNotifierProvider<MultiplayerController, MultiplayerState>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  return MultiplayerController(service);
});

final roomControllerProvider =
StateNotifierProvider<RoomController, RoomState>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  return RoomController(service);
});

final matchControllerProvider =
StateNotifierProvider<MatchController, MatchState>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  return MatchController(service);
});

// Convenience Providers for commonly accessed state
final isConnectedProvider = Provider<bool>((ref) {
  final multiplayerState = ref.watch(multiplayerControllerProvider);
  return multiplayerState.connected;
});

final connectionLatencyProvider = Provider<int>((ref) {
  final multiplayerState = ref.watch(multiplayerControllerProvider);
  return multiplayerState.latencyMs;
});

final multiplayerErrorProvider = Provider<String?>((ref) {
  final multiplayerState = ref.watch(multiplayerControllerProvider);
  return multiplayerState.error;
});

// Room State Convenience Providers
final currentRoomIdProvider = Provider<String?>((ref) {
  final roomState = ref.watch(roomControllerProvider);
  return roomState.roomId;
});

final currentRoomNameProvider = Provider<String?>((ref) {
  final roomState = ref.watch(roomControllerProvider);
  return roomState.roomName;
});

final roomPlayersProvider = Provider<List<PlayerPresence>>((ref) {
  final roomState = ref.watch(roomControllerProvider);
  return roomState.players;
});

final isRoomHostProvider = Provider<bool>((ref) {
  final roomState = ref.watch(roomControllerProvider);
  return roomState.isHost;
});

final isInRoomProvider = Provider<bool>((ref) {
  final roomState = ref.watch(roomControllerProvider);
  return roomState.roomId != null;
});

final roomLoadingProvider = Provider<bool>((ref) {
  final roomState = ref.watch(roomControllerProvider);
  return roomState.loading;
});

final roomErrorProvider = Provider<String?>((ref) {
  final roomState = ref.watch(roomControllerProvider);
  return roomState.error;
});

final roomsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(multiplayerServiceProvider);
  return await service.listRooms(); // or whatever the correct method is
});

// Match State Convenience Providers
final currentMatchIdProvider = Provider<String?>((ref) {
  final matchState = ref.watch(matchControllerProvider);
  return matchState.matchId;
});

final matchPhaseProvider = Provider<MatchPhase>((ref) {
  final matchState = ref.watch(matchControllerProvider);
  return matchState.phase;
});

final currentQuestionIdProvider = Provider<String?>((ref) {
  final matchState = ref.watch(matchControllerProvider);
  return matchState.questionId;
});

final matchRemainingTimeProvider = Provider<int?>((ref) {
  final matchState = ref.watch(matchControllerProvider);
  return matchState.remainingMs;
});

final matchMessageProvider = Provider<String?>((ref) {
  final matchState = ref.watch(matchControllerProvider);
  return matchState.message;
});

final isInMatchProvider = Provider<bool>((ref) {
  final matchPhase = ref.watch(matchPhaseProvider);
  return matchPhase != MatchPhase.idle &&
      matchPhase != MatchPhase.finished &&
      matchPhase != MatchPhase.error;
});

final isMatchActiveProvider = Provider<bool>((ref) {
  final matchPhase = ref.watch(matchPhaseProvider);
  return matchPhase == MatchPhase.question ||
      matchPhase == MatchPhase.reveal;
});

final canSubmitAnswerProvider = Provider<bool>((ref) {
  final matchPhase = ref.watch(matchPhaseProvider);
  return matchPhase == MatchPhase.question;
});

// Combined State Providers
final multiplayerStatusProvider = Provider<String>((ref) {
  final isConnected = ref.watch(isConnectedProvider);
  final isInRoom = ref.watch(isInRoomProvider);
  final isInMatch = ref.watch(isInMatchProvider);

  if (!isConnected) return 'Disconnected';
  if (isInMatch) return 'In Match';
  if (isInRoom) return 'In Room';
  return 'Connected';
});

final canStartMatchProvider = Provider<bool>((ref) {
  final isHost = ref.watch(isRoomHostProvider);
  final players = ref.watch(roomPlayersProvider);
  final isInRoom = ref.watch(isInRoomProvider);

  return isHost && isInRoom && players.length >= 2; // Minimum 2 players to start
});

// Error Aggregation Provider - combines all error sources
final anyMultiplayerErrorProvider = Provider<String?>((ref) {
  final multiplayerError = ref.watch(multiplayerErrorProvider);
  final roomError = ref.watch(roomErrorProvider);

  return multiplayerError ?? roomError;
});

// Action Providers - for triggering actions from UI
final multiplayerActionsProvider = Provider<MultiplayerActions>((ref) {
  return MultiplayerActions(ref);
});

// Helper class for actions
class MultiplayerActions {
  final Ref ref;

  MultiplayerActions(this.ref);

  Future<void> connect({required String token}) async {
    final controller = ref.read(multiplayerControllerProvider.notifier);
    await controller.connect(token: token);
  }

  Future<void> disconnect() async {
    final controller = ref.read(multiplayerControllerProvider.notifier);
    await controller.disconnect();
  }

  Future<void> createRoom(String name) async {
    final controller = ref.read(roomControllerProvider.notifier);
    await controller.createRoom(name);
  }

  Future<void> joinRoom(String roomId) async {
    final controller = ref.read(roomControllerProvider.notifier);
    await controller.joinRoom(roomId);
  }

  Future<void> leaveRoom() async {
    final controller = ref.read(roomControllerProvider.notifier);
    await controller.leaveRoom();
  }

  Future<void> submitAnswer(String matchId, String questionId, String answerId) async {
    final controller = ref.read(matchControllerProvider.notifier);
    await controller.submitAnswer(matchId, questionId, answerId);
  }

  void resetMatch() {
    final controller = ref.read(matchControllerProvider.notifier);
    controller.reset();
  }
}
