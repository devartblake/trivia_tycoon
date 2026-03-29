/// DTOs for the mobile economy endpoints.
///
/// All values are server-driven — never hardcode economy constants on the client.

// ─────────────────────────────────────────────────────────────────────────────
// GET /mobile/economy/state
// ─────────────────────────────────────────────────────────────────────────────

class ModeCostDto {
  final String mode;
  final String costType; // 'energy' | 'ticket'
  final int baseCost;
  final int? adjustedCost; // non-null when a session-start discount is active
  final bool available;

  const ModeCostDto({
    required this.mode,
    required this.costType,
    required this.baseCost,
    this.adjustedCost,
    required this.available,
  });

  int get effectiveCost => adjustedCost ?? baseCost;
  bool get hasDiscount => adjustedCost != null && adjustedCost! < baseCost;

  factory ModeCostDto.fromJson(Map<String, dynamic> j) => ModeCostDto(
        mode: j['mode'] as String? ?? '',
        costType: j['costType'] as String? ?? 'energy',
        baseCost: (j['baseCost'] as num?)?.toInt() ?? 0,
        adjustedCost: (j['adjustedCost'] as num?)?.toInt(),
        available: j['available'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'costType': costType,
        'baseCost': baseCost,
        if (adjustedCost != null) 'adjustedCost': adjustedCost,
        'available': available,
      };
}

class EconomyStateDto {
  final int energy;
  final int maxEnergy;
  final int regenIntervalMinutes;
  final bool firstSessionDiscount;
  final bool dailyTicketAvailable;
  final int dailyTicketsRemaining;
  final bool pityActive;
  final Map<String, ModeCostDto> modes;

  const EconomyStateDto({
    required this.energy,
    required this.maxEnergy,
    required this.regenIntervalMinutes,
    required this.firstSessionDiscount,
    required this.dailyTicketAvailable,
    required this.dailyTicketsRemaining,
    required this.pityActive,
    required this.modes,
  });

  factory EconomyStateDto.fromJson(Map<String, dynamic> j) {
    final rawModes = j['modes'] as Map<String, dynamic>? ?? {};
    final modes = rawModes.map(
      (key, value) => MapEntry(
        key,
        ModeCostDto.fromJson(value as Map<String, dynamic>),
      ),
    );
    return EconomyStateDto(
      energy: (j['energy'] as num?)?.toInt() ?? 0,
      maxEnergy: (j['maxEnergy'] as num?)?.toInt() ?? 50,
      regenIntervalMinutes: (j['regenIntervalMinutes'] as num?)?.toInt() ?? 30,
      firstSessionDiscount: j['firstSessionDiscount'] as bool? ?? false,
      dailyTicketAvailable: j['dailyTicketAvailable'] as bool? ?? false,
      dailyTicketsRemaining: (j['dailyTicketsRemaining'] as num?)?.toInt() ?? 0,
      pityActive: j['pityActive'] as bool? ?? false,
      modes: modes,
    );
  }

  Map<String, dynamic> toJson() => {
        'energy': energy,
        'maxEnergy': maxEnergy,
        'regenIntervalMinutes': regenIntervalMinutes,
        'firstSessionDiscount': firstSessionDiscount,
        'dailyTicketAvailable': dailyTicketAvailable,
        'dailyTicketsRemaining': dailyTicketsRemaining,
        'pityActive': pityActive,
        'modes': modes.map((k, v) => MapEntry(k, v.toJson())),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /mobile/economy/session/start
// ─────────────────────────────────────────────────────────────────────────────

class SessionStartDto {
  final bool discountApplied;
  final Map<String, ModeCostDto> adjustedCosts;

  const SessionStartDto({
    required this.discountApplied,
    required this.adjustedCosts,
  });

  factory SessionStartDto.fromJson(Map<String, dynamic> j) {
    final rawCosts = j['adjustedCosts'] as Map<String, dynamic>? ?? {};
    return SessionStartDto(
      discountApplied: j['discountApplied'] as bool? ?? false,
      adjustedCosts: rawCosts.map(
        (k, v) => MapEntry(k, ModeCostDto.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'discountApplied': discountApplied,
        'adjustedCosts': adjustedCosts.map((k, v) => MapEntry(k, v.toJson())),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /mobile/economy/daily-jackpot-ticket/claim
// ─────────────────────────────────────────────────────────────────────────────

class DailyTicketClaimDto {
  final bool success;
  final int ticketsRemaining;
  final String? denyReason;

  const DailyTicketClaimDto({
    required this.success,
    required this.ticketsRemaining,
    this.denyReason,
  });

  factory DailyTicketClaimDto.fromJson(Map<String, dynamic> j) =>
      DailyTicketClaimDto(
        success: j['success'] as bool? ?? false,
        ticketsRemaining: (j['ticketsRemaining'] as num?)?.toInt() ?? 0,
        denyReason: j['denyReason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'ticketsRemaining': ticketsRemaining,
        if (denyReason != null) 'denyReason': denyReason,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /mobile/economy/revive/quote
// ─────────────────────────────────────────────────────────────────────────────

class ReviveQuoteDto {
  final int baseCost;
  final int finalCost;
  final bool almostWinApplied;
  final String costCurrency; // 'coins' | 'gems'

  const ReviveQuoteDto({
    required this.baseCost,
    required this.finalCost,
    required this.almostWinApplied,
    required this.costCurrency,
  });

  bool get hasDiscount => finalCost < baseCost;

  factory ReviveQuoteDto.fromJson(Map<String, dynamic> j) => ReviveQuoteDto(
        baseCost: (j['baseCost'] as num?)?.toInt() ?? 0,
        finalCost: (j['finalCost'] as num?)?.toInt() ?? 0,
        almostWinApplied: j['almostWinApplied'] as bool? ?? false,
        costCurrency: j['costCurrency'] as String? ?? 'coins',
      );

  Map<String, dynamic> toJson() => {
        'baseCost': baseCost,
        'finalCost': finalCost,
        'almostWinApplied': almostWinApplied,
        'costCurrency': costCurrency,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /mobile/economy/pity/report-loss  (and report-win)
// ─────────────────────────────────────────────────────────────────────────────

class PityResponseDto {
  final bool pityActive;
  final int lossCount;

  const PityResponseDto({
    required this.pityActive,
    required this.lossCount,
  });

  factory PityResponseDto.fromJson(Map<String, dynamic> j) => PityResponseDto(
        pityActive: j['pityActive'] as bool? ?? false,
        lossCount: (j['lossCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'pityActive': pityActive,
        'lossCount': lossCount,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /mobile/matches/start  (409-aware result wrapper)
// ─────────────────────────────────────────────────────────────────────────────

class MatchStartResultDto {
  final bool started;
  final String? matchId;
  final String? denyReason; // populated on 409 policy denial

  const MatchStartResultDto({
    required this.started,
    this.matchId,
    this.denyReason,
  });
}
