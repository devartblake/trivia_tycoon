import 'package:trivia_tycoon/game/multiplayer/services/multiplayer_service.dart';

/// Connects the user to the multiplayer backend with a token.
/// Keep this thin so you can add validation / telemetry later without touching UI.
class ConnectUsecase {
  final MultiplayerService _svc;
  const ConnectUsecase(this._svc);

  Future<bool> call({required String token}) async {
    if (token.isEmpty) return false;
    return _svc.connect(token: token);
  }
}
