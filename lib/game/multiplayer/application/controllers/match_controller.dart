import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trivia_tycoon/game/multiplayer/application/state/match_state.dart';
import 'package:trivia_tycoon/game/multiplayer/services/multiplayer_service.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_event.dart';

/// Drives the in-match flow: reacts to turn start/reveal/results and
/// forwards answer submissions to the service/repository.
class MatchController extends StateNotifier<MatchState> {
  final MultiplayerService _svc;

  StreamSubscription<GameEvent>? _eventSub;

  MatchController(this._svc) : super(const MatchState()) {
    _eventSub = _svc.events.listen(_onEvent, onError: (err, st) {
      // Keep a simple error policy; the screen can react and show a toast/snackbar.
      state = MatchState(matchId: state.matchId, phase: MatchPhase.error);
    });
  }

  /// Submit an answer for the current question/turn.
  Future<void> submitAnswer(String matchId, String questionId, String answerId) async {
    await _svc.submitAnswer(matchId, questionId, answerId);
    // Depending on server protocol you might optimistically set a sub-phase:
    // state = MatchState(matchId: matchId, phase: MatchPhase.question);
  }

  void _onEvent(GameEvent e) {
    if (e is MatchStarted) {
      state = MatchState(matchId: e.matchId, phase: MatchPhase.starting);
      return;
    }
    if (e is TurnStarted) {
      state = MatchState(matchId: state.matchId, phase: MatchPhase.question); // you can store questionId in state if needed
      return;
    }
    // You could add a TurnRevealed event and set phase 'reveal'
    // if (e is TurnRevealed) {
    //   state = MatchState(matchId: state.matchId, phase: MatchPhase.reveal);
    //   return;
    // }

    if (e is MatchEnded) {
      state = MatchState(matchId: e.matchId, phase: MatchPhase.finished);
      return;
    }
  }

  void reset() {
    state = const MatchState();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _eventSub = null;
    super.dispose();
  }
}