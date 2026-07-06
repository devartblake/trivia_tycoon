/// Data Transfer Objects and Domain Models for Friends API
///
/// This file defines all request/response shapes for friend operations:
/// - Friend requests (send, accept, decline)
/// - Friends list with pagination
/// - Player search results
library;

/// Request to send a friend request
class SendFriendRequestRequest {
  final String targetPlayerId;

  SendFriendRequestRequest({required this.targetPlayerId});

  Map<String, dynamic> toJson() => {
    'targetPlayerId': targetPlayerId,
  };
}

/// Response containing list of friends
class FriendsListResponse {
  final List<Friend> friends;
  final int totalCount;
  final int page;
  final int pageSize;

  const FriendsListResponse({
    required this.friends,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory FriendsListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> friendsList = json['friends'] as List<dynamic>? ?? [];
    return FriendsListResponse(
      friends: friendsList
          .map((f) => Friend.fromJson(Map<String, dynamic>.from(f)))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );
  }
}

/// Response containing pending friend requests
class FriendRequestsResponse {
  final List<FriendRequest> requests;
  final int totalCount;
  final int page;
  final int pageSize;

  const FriendRequestsResponse({
    required this.requests,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory FriendRequestsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> requestsList = json['requests'] as List<dynamic>? ?? [];
    return FriendRequestsResponse(
      requests: requestsList
          .map((r) => FriendRequest.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );
  }
}

/// Response containing player search results
class PlayerSearchResponse {
  final List<PlayerSearchResult> results;
  final int totalCount;

  const PlayerSearchResponse({
    required this.results,
    required this.totalCount,
  });

  factory PlayerSearchResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> resultsList = json['results'] as List<dynamic>? ?? [];
    return PlayerSearchResponse(
      results: resultsList
          .map((r) => PlayerSearchResult.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Friend domain model - represents a friend relationship
class Friend {
  final String friendId;
  final String username;
  final String? avatarUrl;
  final String? level;
  final DateTime connectedSinceUtc;
  final bool isOnline;

  const Friend({
    required this.friendId,
    required this.username,
    this.avatarUrl,
    this.level,
    required this.connectedSinceUtc,
    required this.isOnline,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      friendId: json['friendId']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      level: json['level'] as String?,
      connectedSinceUtc: DateTime.tryParse(json['connectedSinceUtc']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      isOnline: (json['isOnline'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'friendId': friendId,
    'username': username,
    'avatarUrl': avatarUrl,
    'level': level,
    'connectedSinceUtc': connectedSinceUtc.toIso8601String(),
    'isOnline': isOnline,
  };
}

/// Friend request domain model - represents a pending friend request
class FriendRequest {
  final String requestId;
  final String fromPlayerId;
  final String fromUsername;
  final String? fromAvatarUrl;
  final DateTime sentAtUtc;
  final String status; // 'pending', 'accepted', 'declined'

  const FriendRequest({
    required this.requestId,
    required this.fromPlayerId,
    required this.fromUsername,
    this.fromAvatarUrl,
    required this.sentAtUtc,
    required this.status,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      requestId: json['requestId']?.toString() ?? '',
      fromPlayerId: json['fromPlayerId']?.toString() ?? '',
      fromUsername: json['fromUsername']?.toString() ?? 'Unknown',
      fromAvatarUrl: json['fromAvatarUrl'] as String?,
      sentAtUtc: DateTime.tryParse(json['sentAtUtc']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      status: json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'fromPlayerId': fromPlayerId,
    'fromUsername': fromUsername,
    'fromAvatarUrl': fromAvatarUrl,
    'sentAtUtc': sentAtUtc.toIso8601String(),
    'status': status,
  };
}

/// Player search result - represents a player found via search
class PlayerSearchResult {
  final String playerId;
  final String username;
  final String? avatarUrl;
  final String? level;
  final bool isFriend;
  final bool hasOutgoingRequest;
  final bool hasIncomingRequest;

  const PlayerSearchResult({
    required this.playerId,
    required this.username,
    this.avatarUrl,
    this.level,
    required this.isFriend,
    required this.hasOutgoingRequest,
    required this.hasIncomingRequest,
  });

  factory PlayerSearchResult.fromJson(Map<String, dynamic> json) {
    return PlayerSearchResult(
      playerId: json['playerId']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      level: json['level'] as String?,
      isFriend: (json['isFriend'] as bool?) ?? false,
      hasOutgoingRequest: (json['hasOutgoingRequest'] as bool?) ?? false,
      hasIncomingRequest: (json['hasIncomingRequest'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'username': username,
    'avatarUrl': avatarUrl,
    'level': level,
    'isFriend': isFriend,
    'hasOutgoingRequest': hasOutgoingRequest,
    'hasIncomingRequest': hasIncomingRequest,
  };
}
