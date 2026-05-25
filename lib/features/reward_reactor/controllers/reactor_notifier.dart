import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reactor_claim_response.dart';
import '../models/reactor_spin_response.dart';
import '../services/reward_reactor_service.dart';

enum ReactorPhase {
  idle,
  spinning,
  pendingClaim,
  claiming,
  chaining,
  applied,
  cooldown,
  error,
}

class ReactorState {
  final ReactorPhase phase;
  final ReactorSpinResponse? pendingReward;
  final ReactorSpinResponse? chainedSpin;
  final ReactorClaimResponse? lastClaim;
  final DateTime? cooldownUntil;
  final bool isClaimInFlight;
  final String? errorMessage;

  const ReactorState({
    this.phase = ReactorPhase.idle,
    this.pendingReward,
    this.chainedSpin,
    this.lastClaim,
    this.cooldownUntil,
    this.isClaimInFlight = false,
    this.errorMessage,
  });

  ReactorState copyWith({
    ReactorPhase? phase,
    ReactorSpinResponse? pendingReward,
    ReactorSpinResponse? chainedSpin,
    ReactorClaimResponse? lastClaim,
    DateTime? cooldownUntil,
    bool? isClaimInFlight,
    String? errorMessage,
  }) {
    return ReactorState(
      phase: phase ?? this.phase,
      pendingReward: pendingReward ?? this.pendingReward,
      chainedSpin: chainedSpin ?? this.chainedSpin,
      lastClaim: lastClaim ?? this.lastClaim,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
      isClaimInFlight: isClaimInFlight ?? this.isClaimInFlight,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ReactorNotifier extends StateNotifier<ReactorState> {
  final RewardReactorService _service;

  ReactorNotifier(this._service) : super(const ReactorState());

  Future<void> spin() async {
    if (state.phase != ReactorPhase.idle) return;

    state = state.copyWith(phase: ReactorPhase.spinning);
    try {
      final response = await _service.startSpin();
      if (response.status == 'cooldown') {
        state = ReactorState(
          phase: ReactorPhase.cooldown,
          cooldownUntil: response.cooldownUntilUtc,
        );
      } else {
        state = ReactorState(
          phase: ReactorPhase.pendingClaim,
          pendingReward: response,
        );
      }
    } catch (e) {
      state = ReactorState(
        phase: ReactorPhase.error,
        errorMessage: 'Could not start spin. Please try again.',
      );
    }
  }

  Future<void> claim() async {
    final pending = state.pendingReward;
    if (state.phase != ReactorPhase.pendingClaim || pending == null) return;
    if (state.isClaimInFlight) return;

    state = state.copyWith(
      phase: ReactorPhase.claiming,
      isClaimInFlight: true,
    );

    try {
      final response = await _service.claimReward(
        spinId: pending.spinId,
        claimToken: pending.claimToken,
        idempotencyKey: '${pending.spinId}-${pending.claimToken}',
      );

      if (response.isCooldown) {
        state = ReactorState(phase: ReactorPhase.cooldown);
      } else if (response.chainedSpinId != null &&
          response.chainedSpinId!.isNotEmpty) {
        state = ReactorState(
          phase: ReactorPhase.chaining,
          pendingReward: pending,
          lastClaim: response,
        );
        await chain(response.chainedSpinId!);
      } else {
        state = ReactorState(
          phase: ReactorPhase.applied,
          pendingReward: pending,
          lastClaim: response,
        );
      }
    } catch (e) {
      state = state.copyWith(
        phase: ReactorPhase.pendingClaim,
        isClaimInFlight: false,
        errorMessage: 'Claim failed. Please try again.',
      );
    }
  }

  Future<void> chain(String chainedSpinId) async {
    if (chainedSpinId.isEmpty) return;
    if (state.phase != ReactorPhase.chaining) {
      state = state.copyWith(phase: ReactorPhase.chaining);
    }

    try {
      final response = await _service.chainSpin(chainedSpinId: chainedSpinId);
      if (response.status == 'cooldown') {
        state = ReactorState(
          phase: ReactorPhase.cooldown,
          cooldownUntil: response.cooldownUntilUtc,
          lastClaim: state.lastClaim,
        );
      } else {
        state = ReactorState(
          phase: ReactorPhase.pendingClaim,
          pendingReward: response,
          chainedSpin: response,
          lastClaim: state.lastClaim,
        );
      }
    } catch (e) {
      state = ReactorState(
        phase: ReactorPhase.error,
        pendingReward: state.pendingReward,
        lastClaim: state.lastClaim,
        errorMessage: 'Could not start chain bonus. Please try again.',
      );
    }
  }

  void dismiss() => state = const ReactorState();
}
