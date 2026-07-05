/// Mirrors backend TierGuardianDto (GET /guardians/{tierNumber}?seasonId=).
class GuardianDto {
  final String id;
  final String seasonId;
  final int tierNumber;
  final String playerId;
  final DateTime? assignedAtUtc;
  final DateTime? expiresAtUtc;
  final int defencesWon;
  final int defencesLost;

  const GuardianDto({
    required this.id,
    required this.seasonId,
    required this.tierNumber,
    required this.playerId,
    this.assignedAtUtc,
    this.expiresAtUtc,
    required this.defencesWon,
    required this.defencesLost,
  });

  factory GuardianDto.fromJson(Map<String, dynamic> j) => GuardianDto(
        id: j['id'] as String,
        seasonId: j['seasonId'] as String,
        tierNumber: j['tierNumber'] as int? ?? 1,
        playerId: j['playerId'] as String,
        assignedAtUtc: j['assignedAtUtc'] != null
            ? DateTime.tryParse(j['assignedAtUtc'] as String)
            : null,
        expiresAtUtc: j['expiresAtUtc'] != null
            ? DateTime.tryParse(j['expiresAtUtc'] as String)
            : null,
        defencesWon: j['defencesWon'] as int? ?? 0,
        defencesLost: j['defencesLost'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'seasonId': seasonId,
        'tierNumber': tierNumber,
        'playerId': playerId,
        'assignedAtUtc': assignedAtUtc?.toIso8601String(),
        'expiresAtUtc': expiresAtUtc?.toIso8601String(),
        'defencesWon': defencesWon,
        'defencesLost': defencesLost,
      };
}

class MyGuardianStatusDto {
  final String playerId;
  final bool isGuardian;
  final int? tier;
  final int defenceCount;
  final String? currentMatchId;

  const MyGuardianStatusDto({
    required this.playerId,
    required this.isGuardian,
    this.tier,
    required this.defenceCount,
    this.currentMatchId,
  });

  factory MyGuardianStatusDto.fromJson(Map<String, dynamic> j) =>
      MyGuardianStatusDto(
        playerId: j['playerId'] as String,
        isGuardian: j['isGuardian'] as bool? ?? false,
        tier: j['tier'] as int?,
        defenceCount: j['defenceCount'] as int? ?? 0,
        currentMatchId: j['currentMatchId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'isGuardian': isGuardian,
        'tier': tier,
        'defenceCount': defenceCount,
        'currentMatchId': currentMatchId,
      };
}
