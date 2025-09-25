import 'package:trivia_tycoon/game/multiplayer/services/multiplayer_service.dart';

/// Submits an answer for the current question. The server will emit
/// [AnswerAccepted] or [AnswerRejected] events that your controller can observe.
class SubmitAnswerUsecase {
  final MultiplayerService _svc;
  const SubmitAnswerUsecase(this._svc);

  Future<void> call({
    required String matchId,
    required String questionId,
    required String answerId,
  }) {
    return _svc.submitAnswer(matchId, questionId, answerId);
  }
}
