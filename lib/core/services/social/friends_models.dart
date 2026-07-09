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

  // Backend contract: UserFriendsEndpoints.SendFriendRequestBody(TargetUserId)
  Map<String, dynamic> toJson() => {
    'targetUserId': targetPlayerId,
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

  // Backend contract: FriendsListResponseDto {page, pageSize, total,
  // totalPages, items: [FriendDto]}
  factory FriendsListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> friendsList = json['items'] as List<dynamic>? ??
        json['friends'] as List<dynamic>? ??
        [];
    return FriendsListResponse(
      friends: friendsList
          .map((f) => Friend.fromJson(Map<String, dynamic>.from(f)))
          .toList(),
      totalCount: (json['total'] as num?)?.toInt() ??
          (json['totalCount'] as num?)?.toInt() ??
          0,
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

  // Backend contract: FriendRequestsDetailListResponseDto {page, pageSize,
  // total, totalPages, items: [FriendRequestDetailDto]}
  factory FriendRequestsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> requestsList = json['items'] as List<dynamic>? ??
        json['requests'] as List<dynamic>? ??
        [];
    return FriendRequestsResponse(
      requests: requestsList
          .map((r) => FriendRequest.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
      totalCount: (json['total'] as num?)?.toInt() ??
          (json['totalCount'] as num?)?.toInt() ??
          0,
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

  // Backend contract: UserSearchResponseDto {page, pageSize, total,
  // totalPages, items: [UserSearchResultDto]}
  factory PlayerSearchResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> resultsList = json['items'] as List<dynamic>? ??
        json['results'] as List<dynamic>? ??
        [];
    return PlayerSearchResponse(
      results: resultsList
          .map((r) => PlayerSearchResult.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
      totalCount: (json['total'] as num?)?.toInt() ??
          (json['totalCount'] as num?)?.toInt() ??
          0,
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

  // Backend contract: FriendDto {friendPlayerId, displayName, username,
  // avatarUrl, isOnline, lastSeenUtc, sinceUtc}
  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      friendId: json['friendPlayerId']?.toString() ??
          json['friendId']?.toString() ??
          '',
      username: json['username']?.toString() ??
          json['displayName']?.toString() ??
          'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      level: json['level'] as String?,
      connectedSinceUtc: DateTime.tryParse(json['sinceUtc']?.toString() ??
                  json['connectedSinceUtc']?.toString() ??
                  '')
              ?.toUtc() ??
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

  // Backend contract: FriendRequestDetailDto {requestId, fromPlayerId,
  // senderDisplayName, senderUsername, senderAvatarUrl, toPlayerId, status,
  // createdAtUtc, respondedAtUtc}
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      requestId: json['requestId']?.toString() ?? '',
      fromPlayerId: json['fromPlayerId']?.toString() ?? '',
      fromUsername: json['senderUsername']?.toString() ??
          json['senderDisplayName']?.toString() ??
          json['fromUsername']?.toString() ??
          'Unknown',
      fromAvatarUrl: (json['senderAvatarUrl'] ?? json['fromAvatarUrl']) as String?,
      sentAtUtc: DateTime.tryParse(json['createdAtUtc']?.toString() ??
                  json['sentAtUtc']?.toString() ??
                  '')
              ?.toUtc() ??
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

  // Backend contract: UserSearchResultDto {id, handle, displayName,
  // username, avatarUrl, country, tier, mmr}. Relationship flags are not
  // provided by the search endpoint and default to false.
  factory PlayerSearchResult.fromJson(Map<String, dynamic> json) {
    return PlayerSearchResult(
      playerId: json['id']?.toString() ?? json['playerId']?.toString() ?? '',
      username: json['username']?.toString() ??
          json['handle']?.toString() ??
          'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      level: (json['tier'] ?? json['level'])?.toString(),
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
