import 'package:trivia_tycoon/game/multiplayer/services/multiplayer_service.dart';

/// Create a room or join an existing one based on params.
/// This keeps the controller free from branching logic.
class CreateJoinRoomUsecase {
  final MultiplayerService _svc;
  const CreateJoinRoomUsecase(this._svc);

  /// If [roomId] is provided, try to join; otherwise create with [roomName].
  Future<bool> call({String? roomId, String? roomName}) async {
    if (roomId != null && roomId.isNotEmpty) {
      return _svc.joinRoom(roomId);
    }
    final name = (roomName ?? '').trim();
    if (name.isEmpty) return false;
    return _svc.createRoom(name);
  }
}
