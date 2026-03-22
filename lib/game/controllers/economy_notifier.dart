import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dto/economy_dto.dart';
import '../../core/networking/tycoon_api_client.dart';
import '../../core/services/settings/general_key_value_storage_service.dart';
import '../../game/analytics/services/analytics_service.dart';
import 'energy_lives_notifier.dart';

const _kEconomyStateCacheKey = 'economy_last_state_json';

class EconomyState {
  final bool isLoading;
  final String? error;
  final bool firstSessionDiscount;
  final bool dailyTicketAvailable;
  final int dailyTicketsRemaining;
  final bool pityActive;
  final Map<String, ModeCostDto> modes;
  final DateTime? lastFetched;

  const EconomyState({
    this.isLoading = false,
    this.error,
    this.firstSessionDiscount = false,
    this.dailyTicketAvailable = false,
    this.dailyTicketsRemaining = 0,
    this.pityActive = false,
    this.modes = const {},
    this.lastFetched,
  });

  static const EconomyState initial = EconomyState();

  EconomyState copyWith({
    bool? isLoading,
    String? error,
    bool? firstSessionDiscount,
    bool? dailyTicketAvailable,
    int? dailyTicketsRemaining,
    bool? pityActive,
    Map<String, ModeCostDto>? modes,
    DateTime? lastFetched,
  }) =>
      EconomyState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        firstSessionDiscount: firstSessionDiscount ?? this.firstSessionDiscount,
        dailyTicketAvailable: dailyTicketAvailable ?? this.dailyTicketAvailable,
        dailyTicketsRemaining:
            dailyTicketsRemaining ?? this.dailyTicketsRemaining,
        pityActive: pityActive ?? this.pityActive,
        modes: modes ?? this.modes,
        lastFetched: lastFetched ?? this.lastFetched,
      );
}

class EconomyNotifier extends StateNotifier<EconomyState> {
  final TycoonApiClient _api;
  final EnergyNotifier _energy;
  final AnalyticsService _analytics;
  final GeneralKeyValueStorageService _storage;

  EconomyNotifier(
    this._api,
    this._energy,
    this._analytics,
    this._storage,
  ) : super(EconomyState.initial) {
    _hydrateCachedState();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Load last-known economy state from local cache so the HUD renders on cold
  /// start before the first network fetch completes.
  Future<void> _hydrateCachedState() async {
    final raw = await _storage.getString(_kEconomyStateCacheKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final dto = EconomyStateDto.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      _applyDto(dto);
    } catch (_) {
      // Stale / corrupt cache — silently ignore; fetchState will overwrite.
    }
  }

  void _applyDto(EconomyStateDto dto) {
    _energy.syncWithServer(
      dto.energy,
      dto.maxEnergy,
      Duration(minutes: dto.regenIntervalMinutes),
    );
    state = state.copyWith(
      isLoading: false,
      firstSessionDiscount: dto.firstSessionDiscount,
      dailyTicketAvailable: dto.dailyTicketAvailable,
      dailyTicketsRemaining: dto.dailyTicketsRemaining,
      pityActive: dto.pityActive,
      modes: dto.modes,
      lastFetched: DateTime.now(),
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetch authoritative economy state from the server and sync energy.
  Future<void> fetchState(String playerId) async {
    state = state.copyWith(isLoading: true);
    try {
      final dto = await _api.getEconomyState(playerId: playerId);
      _applyDto(dto);
      // Persist to cache for next cold start
      await _storage.setString(
          _kEconomyStateCacheKey, jsonEncode(dto.toJson()));
      _analytics.logEvent('economy_state_loaded', {
        'playerId': playerId,
        'energy': dto.energy,
        'pityActive': dto.pityActive,
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Call before showing adjusted mode costs to the player.
  Future<SessionStartDto?> startSession(
      String playerId, String mode) async {
    try {
      final dto = await _api.startEconomySession(playerId: playerId);
      // Merge in adjusted costs from session start
      if (dto.adjustedCosts.isNotEmpty) {
        final merged = Map<String, ModeCostDto>.from(state.modes)
          ..addAll(dto.adjustedCosts);
        state = state.copyWith(modes: merged);
      }
      return dto;
    } catch (_) {
      return null;
    }
  }

  /// Attempt to enter a mode. Handles 409 policy denial internally.
  Future<MatchStartResultDto> enterMode(
      String playerId, String mode) async {
    final result =
        await _api.startPolicyMatch(playerId: playerId, mode: mode);
    if (result.started) {
      _analytics.logEvent('mode_entry_attempted', {
        'playerId': playerId,
        'mode': mode,
      });
    } else {
      _analytics.logEvent('mode_entry_blocked', {
        'playerId': playerId,
        'mode': mode,
        'reasonCode': result.denyReason,
      });
    }
    return result;
  }

  /// Claim the daily jackpot ticket. Updates local ticket state on success.
  Future<DailyTicketClaimDto> claimTicket(String playerId) async {
    final dto = await _api.claimDailyJackpotTicket(playerId: playerId);
    if (dto.success) {
      state = state.copyWith(
        dailyTicketAvailable: dto.ticketsRemaining > 0,
        dailyTicketsRemaining: dto.ticketsRemaining,
      );
      _analytics.logEvent('daily_ticket_claimed', {'playerId': playerId});
    } else {
      _analytics.logEvent('daily_ticket_denied', {
        'playerId': playerId,
        'reason': dto.denyReason,
      });
    }
    return dto;
  }

  /// Report a match loss for pity tracking.
  Future<void> reportLoss(String playerId) async {
    try {
      final dto = await _api.reportPityLoss(playerId: playerId);
      state = state.copyWith(pityActive: dto.pityActive);
      _analytics.logEvent('pity_state_changed', {
        'playerId': playerId,
        'pityActive': dto.pityActive,
        'lossCount': dto.lossCount,
      });
    } catch (_) {
      // Non-blocking — pity reporting should never interrupt the game flow.
    }
  }

  /// Report a match win to reset pity state.
  Future<void> reportWin(String playerId) async {
    try {
      final dto = await _api.reportPityWin(playerId: playerId);
      state = state.copyWith(pityActive: dto.pityActive);
      _analytics.logEvent('pity_state_changed', {
        'playerId': playerId,
        'pityActive': dto.pityActive,
        'lossCount': dto.lossCount,
      });
    } catch (_) {
      // Non-blocking.
    }
  }
}
