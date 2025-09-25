import 'package:trivia_tycoon/game/multiplayer/services/multiplayer_service.dart';

/// Leaves the current match or room. If you later add a dedicated server op,
/// wire it in here; for now we keep it graceful (disconnect or room reset).
class LeaveMatchUsecase {
  final MultiplayerService _svc;
  const LeaveMatchUsecase(this._svc);

  /// If you add a dedicated API like `_svc.leaveRoom()`, call it here.
  Future<void> call() async {
    // Placeholder: either no-op, or send a leave signal if you expose one.
    // await _svc.leaveRoom();
  }
}
