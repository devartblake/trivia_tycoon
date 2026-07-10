/// A game event as served by `/game-events/upcoming` (summary shape) and
/// `/game-events/{id}` (fuller status shape). One tolerant model covers both;
/// status-only fields are null/zero on summaries.
class ChampionEvent {
  final String id;
  final String kind;

  /// Scheduled | Open | Live | Closed
  final String status;
  final int tierId;
  final DateTime scheduledAtUtc;
  final int entryFeeCoins;
  final int maxParticipants;

  // Status-shape fields (from GET /game-events/{id}).
  final int participantCount;
  final int aliveCount;
  final int jackpotPool;
  final int effectiveJackpot;
  final double jackpotMultiplier;
  final String? championPlayerId;

  const ChampionEvent({
    required this.id,
    required this.kind,
    required this.status,
    required this.tierId,
    required this.scheduledAtUtc,
    required this.entryFeeCoins,
    required this.maxParticipants,
    this.participantCount = 0,
    this.aliveCount = 0,
    this.jackpotPool = 0,
    this.effectiveJackpot = 0,
    this.jackpotMultiplier = 1.0,
    this.championPlayerId,
  });

  bool get isChampionVsTier => kind == 'champion_vs_tier';
  bool get isOpenForEntry => status == 'Open';
  bool get isLive => status == 'Live';

  /// The jackpot to show players: the multiplied pool once known, else the raw
  /// pool (summaries don't carry a jackpot at all → 0).
  int get displayJackpot =>
      effectiveJackpot > 0 ? effectiveJackpot : jackpotPool;

  /// Backend serializes GameEventStatus via JsonStringEnumConverter (string),
  /// but tolerate the raw int enum (1..4) as well.
  static String _status(Object? raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is num) {
      const names = {1: 'Scheduled', 2: 'Open', 3: 'Live', 4: 'Closed'};
      return names[raw.toInt()] ?? 'Scheduled';
    }
    return 'Scheduled';
  }

  factory ChampionEvent.fromJson(Map<String, dynamic> json) {
    return ChampionEvent(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      status: _status(json['status']),
      tierId: (json['tierId'] as num?)?.toInt() ?? 0,
      scheduledAtUtc:
          DateTime.tryParse(json['scheduledAtUtc']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      entryFeeCoins: (json['entryFeeCoins'] as num?)?.toInt() ?? 0,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 0,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      aliveCount: (json['aliveCount'] as num?)?.toInt() ?? 0,
      jackpotPool: (json['jackpotPool'] as num?)?.toInt() ?? 0,
      effectiveJackpot: (json['effectiveJackpot'] as num?)?.toInt() ?? 0,
      jackpotMultiplier: (json['jackpotMultiplier'] as num?)?.toDouble() ?? 1.0,
      championPlayerId: json['championPlayerId']?.toString(),
    );
  }
}
