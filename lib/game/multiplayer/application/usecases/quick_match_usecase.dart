import 'package:trivia_tycoon/game/multiplayer/services/multiplayer_service.dart';

/// Enqueues the player for a quick match (or creates/joins a suitable room).
class QuickMatchUsecase {
  final MultiplayerService _svc;
  const QuickMatchUsecase(this._svc);

  Future<bool> call() => _svc.quickMatch();
}
