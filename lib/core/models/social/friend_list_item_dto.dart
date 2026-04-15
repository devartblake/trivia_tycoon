class FriendListItemDto {
  const FriendListItemDto({
    required this.friendPlayerId,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.isOnline,
    required this.lastSeenUtc,
    required this.sinceUtc,
  });

  final String friendPlayerId;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeenUtc;
  final DateTime? sinceUtc;

  factory FriendListItemDto.fromJson(Map<String, dynamic> json) {
    return FriendListItemDto(
      friendPlayerId: json['friendPlayerId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ??
          json['username']?.toString() ??
          '',
      username: json['username']?.toString() ??
          json['displayName']?.toString() ??
          '',
      avatarUrl: json['avatarUrl']?.toString(),
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenUtc: _parseDateTime(json['lastSeenUtc']),
      sinceUtc: _parseDateTime(json['sinceUtc']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friendPlayerId': friendPlayerId,
      'displayName': displayName,
      'username': username,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeenUtc': lastSeenUtc?.toIso8601String(),
      'sinceUtc': sinceUtc?.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}
