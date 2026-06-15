/// DTOs for the powerups feature (`/powerups` REST).
///
/// Mirrors `Synaptix.Shared.Contracts.Dtos.PowerupDtos`. The backend serializes
/// the `PowerupType` enum as a string (JsonStringEnumConverter).
library;

enum PowerupType {
  fiftyFifty,
  skip,
  doublePoints,
  extraTime;

  /// Wire value sent to / received from the backend (matches the C# enum name).
  String get wire => switch (this) {
        PowerupType.fiftyFifty => 'FiftyFifty',
        PowerupType.skip => 'Skip',
        PowerupType.doublePoints => 'DoublePoints',
        PowerupType.extraTime => 'ExtraTime',
      };

  static PowerupType fromWire(Object? value) {
    final s = value?.toString().toLowerCase();
    return switch (s) {
      'fiftyfifty' || '1' => PowerupType.fiftyFifty,
      'skip' || '2' => PowerupType.skip,
      'doublepoints' || '3' => PowerupType.doublePoints,
      'extratime' || '4' => PowerupType.extraTime,
      _ => PowerupType.fiftyFifty,
    };
  }
}

class PowerupBalanceDto {
  final PowerupType type;
  final int quantity;
  final DateTime? cooldownUntilUtc;

  const PowerupBalanceDto({
    required this.type,
    required this.quantity,
    this.cooldownUntilUtc,
  });

  bool get onCooldown =>
      cooldownUntilUtc != null && cooldownUntilUtc!.isAfter(DateTime.now());

  factory PowerupBalanceDto.fromJson(Map<String, dynamic> j) =>
      PowerupBalanceDto(
        type: PowerupType.fromWire(j['type']),
        quantity: j['quantity'] as int? ?? 0,
        cooldownUntilUtc:
            DateTime.tryParse(j['cooldownUntilUtc'] as String? ?? ''),
      );
}

class PowerupStateDto {
  final String playerId;
  final List<PowerupBalanceDto> powerups;

  const PowerupStateDto({
    required this.playerId,
    required this.powerups,
  });

  PowerupBalanceDto? balanceOf(PowerupType type) {
    for (final p in powerups) {
      if (p.type == type) return p;
    }
    return null;
  }

  factory PowerupStateDto.fromJson(Map<String, dynamic> j) => PowerupStateDto(
        playerId: j['playerId'] as String,
        powerups: (j['powerups'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(PowerupBalanceDto.fromJson)
            .toList(),
      );
}

class UsePowerupResultDto {
  final String eventId;
  final String playerId;
  final PowerupType type;

  /// Used | Duplicate | Insufficient | Cooldown
  final String status;
  final int remaining;
  final DateTime? cooldownUntilUtc;

  const UsePowerupResultDto({
    required this.eventId,
    required this.playerId,
    required this.type,
    required this.status,
    required this.remaining,
    this.cooldownUntilUtc,
  });

  bool get used => status == 'Used';

  factory UsePowerupResultDto.fromJson(Map<String, dynamic> j) =>
      UsePowerupResultDto(
        eventId: j['eventId'] as String? ?? '',
        playerId: j['playerId'] as String? ?? '',
        type: PowerupType.fromWire(j['type']),
        status: j['status'] as String? ?? 'Unknown',
        remaining: j['remaining'] as int? ?? 0,
        cooldownUntilUtc:
            DateTime.tryParse(j['cooldownUntilUtc'] as String? ?? ''),
      );
}
