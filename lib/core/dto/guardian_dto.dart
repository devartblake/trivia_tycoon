class GuardianDto {
  final String id;
  final String playerId;
  final String username;
  final String? avatarUrl;
  final int tier;
  final int defenceCount;
  final DateTime? lastChallengedAt;

  const GuardianDto({
    required this.id,
    required this.playerId,
    required this.username,
    this.avatarUrl,
    required this.tier,
    required this.defenceCount,
    this.lastChallengedAt,
  });

  factory GuardianDto.fromJson(Map<String, dynamic> j) => GuardianDto(
    id: j['id'] as String,
    playerId: j['playerId'] as String,
    username: j['username'] as String,
    avatarUrl: j['avatarUrl'] as String?,
    tier: j['tier'] as int? ?? 1,
    defenceCount: j['defenceCount'] as int? ?? 0,
    lastChallengedAt: j['lastChallengedAt'] != null
        ? DateTime.tryParse(j['lastChallengedAt'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'playerId': playerId,
    'username': username,
    'avatarUrl': avatarUrl,
    'tier': tier,
    'defenceCount': defenceCount,
    'lastChallengedAt': lastChallengedAt?.toIso8601String(),
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