class FriendSuggestionDto {
  const FriendSuggestionDto({
    required this.id,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.mutualFriendCount,
    required this.reason,
  });

  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final int mutualFriendCount;
  final String reason;

  bool get hasMutualFriends => mutualFriendCount > 0;

  factory FriendSuggestionDto.fromJson(Map<String, dynamic> json) {
    return FriendSuggestionDto(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ??
          json['username']?.toString() ??
          '',
      username: json['username']?.toString() ??
          json['displayName']?.toString() ??
          '',
      avatarUrl: json['avatarUrl']?.toString(),
      mutualFriendCount: (json['mutualFriendCount'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'username': username,
      'avatarUrl': avatarUrl,
      'mutualFriendCount': mutualFriendCount,
      'reason': reason,
    };
  }
}
