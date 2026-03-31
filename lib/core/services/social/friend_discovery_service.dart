import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

enum FriendshipStatus {
  notFriends,
  requestSent,
  requestReceived,
  friends,
  blocked;

  String get displayName {
    switch (this) {
      case FriendshipStatus.notFriends:
        return 'Not Friends';
      case FriendshipStatus.requestSent:
        return 'Request Sent';
      case FriendshipStatus.requestReceived:
        return 'Request Received';
      case FriendshipStatus.friends:
        return 'Friends';
      case FriendshipStatus.blocked:
        return 'Blocked';
    }
  }
}

class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String recipientId;
  final DateTime createdAt;
  final String? message;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.recipientId,
    required this.createdAt,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      'recipientId': recipientId,
      'createdAt': createdAt.toIso8601String(),
      if (message != null) 'message': message,
    };
  }

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String?,
      recipientId: json['recipientId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      message: json['message'] as String?,
    );
  }
}

class Friendship {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final String? nickname; // Custom nickname for the friend
  final bool isFavorite;

  const Friendship({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    this.nickname,
    this.isFavorite = false,
  });

  String getFriendId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  Friendship copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    DateTime? createdAt,
    String? nickname,
    bool? isFavorite,
  }) {
    return Friendship(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      createdAt: createdAt ?? this.createdAt,
      nickname: nickname ?? this.nickname,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'createdAt': createdAt.toIso8601String(),
      if (nickname != null) 'nickname': nickname,
      'isFavorite': isFavorite,
    };
  }

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      user1Id: json['user1Id'] as String,
      user2Id: json['user2Id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      nickname: json['nickname'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

class UserProfile {
  final String id;
  final String displayName;
  final String? username;
  final String? avatar;
  final String? bio;
  final int level;
  final int totalPoints;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.username,
    this.avatar,
    this.bio,
    this.level = 1,
    this.totalPoints = 0,
    this.isOnline = false,
    this.lastSeen,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      if (username != null) 'username': username,
      if (avatar != null) 'avatar': avatar,
      if (bio != null) 'bio': bio,
      'level': level,
      'totalPoints': totalPoints,
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String?,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      level: json['level'] as int? ?? 1,
      totalPoints: json['totalPoints'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
    );
  }
}

class FriendSuggestion {
  final UserProfile user;
  final int mutualFriendCount;
  final List<String> mutualFriendIds;
  final String reason; // Why this person is suggested
  final double score; // Relevance score

  const FriendSuggestion({
    required this.user,
    required this.mutualFriendCount,
    required this.mutualFriendIds,
    required this.reason,
    this.score = 0.0,
  });
}

class FriendDiscoveryService extends ChangeNotifier {
  static final FriendDiscoveryService _instance = FriendDiscoveryService._internal();
  factory FriendDiscoveryService() => _instance;
  FriendDiscoveryService._internal();

  // Storage
  final Map<String, Friendship> _friendships = {};
  final Map<String, FriendRequest> _pendingRequests = {};
  final Map<String, Set<String>> _blockedUsers = {}; // userId -> Set of blocked user IDs
  final Map<String, UserProfile> _userProfiles = {};

  // Streams
  final Map<String, StreamController<List<String>>> _friendListStreams = {};
  final Map<String, StreamController<List<FriendRequest>>> _requestStreams = {};

  // Cache
  final Map<String, List<FriendSuggestion>> _suggestionCache = {};
  DateTime? _lastSuggestionUpdate;

  void initialize() {
    _loadMockData();
    LogManager.debug('FriendDiscoveryService initialized');
  }

  @override
  void dispose() {
    for (final controller in _friendListStreams.values) {
      controller.close();
    }
    for (final controller in _requestStreams.values) {
      controller.close();
    }
    _friendListStreams.clear();
    _requestStreams.clear();
    super.dispose();
  }

  // ============ Friend Requests ============

  Future<bool> sendFriendRequest({
    required String senderId,
    required String senderName,
    required String recipientId,
    String? message,
  }) async {
    // Check if already friends
    if (areFriends(senderId, recipientId)) {
      LogManager.debug('Already friends');
      return false;
    }

    // Check if request already exists
    final existingRequest = _pendingRequests.values.firstWhere(
          (req) => req.senderId == senderId && req.recipientId == recipientId,
      orElse: () => FriendRequest(
        id: '',
        senderId: '',
        senderName: '',
        recipientId: '',
        createdAt: DateTime.now(),
      ),
    );

    if (existingRequest.id.isNotEmpty) {
      LogManager.debug('Request already sent');
      return false;
    }

    // Check if blocked
    if (isBlocked(senderId, recipientId) || isBlocked(recipientId, senderId)) {
      LogManager.debug('User is blocked');
      return false;
    }

    final request = FriendRequest(
      id: _generateRequestId(),
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId,
      createdAt: DateTime.now(),
      message: message,
    );

    _pendingRequests[request.id] = request;

    LogManager.debug('Friend request sent from $senderName to $recipientId');
    _broadcastRequestUpdate(recipientId);
    notifyListeners();

    return true;
  }

  Future<bool> acceptFriendRequest(String requestId, String currentUserId) async {
    final request = _pendingRequests[requestId];
    if (request == null || request.recipientId != currentUserId) {
      return false;
    }

    // Create friendship
    final friendship = Friendship(
      id: _generateFriendshipId(),
      user1Id: request.senderId,
      user2Id: request.recipientId,
      createdAt: DateTime.now(),
    );

    _friendships[friendship.id] = friendship;
    _pendingRequests.remove(requestId);

    LogManager.debug('Friend request accepted: ${request.senderName} and $currentUserId');

    _broadcastFriendListUpdate(request.senderId);
    _broadcastFriendListUpdate(request.recipientId);
    _broadcastRequestUpdate(currentUserId);
    notifyListeners();

    return true;
  }

  Future<bool> declineFriendRequest(String requestId, String currentUserId) async {
    final request = _pendingRequests[requestId];
    if (request == null || request.recipientId != currentUserId) {
      return false;
    }

    _pendingRequests.remove(requestId);

    LogManager.debug('Friend request declined');
    _broadcastRequestUpdate(currentUserId);
    notifyListeners();

    return true;
  }

  Future<bool> cancelFriendRequest(String requestId, String senderId) async {
    final request = _pendingRequests[requestId];
    if (request == null || request.senderId != senderId) {
      return false;
    }

    _pendingRequests.remove(requestId);

    LogManager.debug('Friend request cancelled');
    notifyListeners();

    return true;
  }

  // ============ Friendship Management ============

  Future<bool> removeFriend(String userId1, String userId2) async {
    final friendship = _friendships.values.firstWhere(
          (f) => (f.user1Id == userId1 && f.user2Id == userId2) ||
          (f.user1Id == userId2 && f.user2Id == userId1),
      orElse: () => Friendship(
        id: '',
        user1Id: '',
        user2Id: '',
        createdAt: DateTime.now(),
      ),
    );

    if (friendship.id.isEmpty) {
      return false;
    }

    _friendships.remove(friendship.id);

    LogManager.debug('Friendship removed between $userId1 and $userId2');

    _broadcastFriendListUpdate(userId1);
    _broadcastFriendListUpdate(userId2);
    notifyListeners();

    return true;
  }

  Future<bool> setFriendNickname({
    required String currentUserId,
    required String friendId,
    required String nickname,
  }) async {
    final friendship = _findFriendship(currentUserId, friendId);
    if (friendship == null) return false;

    _friendships[friendship.id] = friendship.copyWith(nickname: nickname);

    LogManager.debug('Nickname set for friend $friendId: $nickname');
    notifyListeners();

    return true;
  }

  Future<bool> toggleFavorite({
    required String currentUserId,
    required String friendId,
  }) async {
    final friendship = _findFriendship(currentUserId, friendId);
    if (friendship == null) return false;

    _friendships[friendship.id] = friendship.copyWith(
      isFavorite: !friendship.isFavorite,
    );

    LogManager.debug('Favorite toggled for friend $friendId');
    _broadcastFriendListUpdate(currentUserId);
    notifyListeners();

    return true;
  }

  // ============ Blocking ============

  Future<bool> blockUser(String userId, String targetUserId) async {
    _blockedUsers[userId] ??= {};
    _blockedUsers[userId]!.add(targetUserId);

    // Remove friendship if exists
    await removeFriend(userId, targetUserId);

    // Remove any pending requests
    final requestsToRemove = _pendingRequests.entries
        .where((entry) =>
    (entry.value.senderId == userId && entry.value.recipientId == targetUserId) ||
        (entry.value.senderId == targetUserId && entry.value.recipientId == userId))
        .map((entry) => entry.key)
        .toList();

    for (final requestId in requestsToRemove) {
      _pendingRequests.remove(requestId);
    }

    LogManager.debug('User $targetUserId blocked by $userId');
    notifyListeners();

    return true;
  }

  Future<bool> unblockUser(String userId, String targetUserId) async {
    final blocked = _blockedUsers[userId];
    if (blocked == null) return false;

    blocked.remove(targetUserId);

    LogManager.debug('User $targetUserId unblocked by $userId');
    notifyListeners();

    return true;
  }

  bool isBlocked(String userId, String targetUserId) {
    return _blockedUsers[userId]?.contains(targetUserId) ?? false;
  }

  List<String> getBlockedUsers(String userId) {
    return _blockedUsers[userId]?.toList() ?? [];
  }

  // ============ Query Methods ============

  bool areFriends(String userId1, String userId2) {
    return _friendships.values.any((f) =>
    (f.user1Id == userId1 && f.user2Id == userId2) ||
        (f.user1Id == userId2 && f.user2Id == userId1));
  }

  FriendshipStatus getFriendshipStatus(String currentUserId, String targetUserId) {
    // Check if blocked
    if (isBlocked(currentUserId, targetUserId) || isBlocked(targetUserId, currentUserId)) {
      return FriendshipStatus.blocked;
    }

    // Check if friends
    if (areFriends(currentUserId, targetUserId)) {
      return FriendshipStatus.friends;
    }

    // Check for pending request sent
    final sentRequest = _pendingRequests.values.any((req) =>
    req.senderId == currentUserId && req.recipientId == targetUserId);
    if (sentRequest) {
      return FriendshipStatus.requestSent;
    }

    // Check for pending request received
    final receivedRequest = _pendingRequests.values.any((req) =>
    req.senderId == targetUserId && req.recipientId == currentUserId);
    if (receivedRequest) {
      return FriendshipStatus.requestReceived;
    }

    return FriendshipStatus.notFriends;
  }

  List<String> getFriendIds(String userId) {
    return _friendships.values
        .where((f) => f.user1Id == userId || f.user2Id == userId)
        .map((f) => f.getFriendId(userId))
        .toList();
  }

  List<UserProfile> getFriends(String userId) {
    final friendIds = getFriendIds(userId);
    return friendIds
        .map((id) => _userProfiles[id])
        .where((profile) => profile != null)
        .cast<UserProfile>()
        .toList();
  }

  List<UserProfile> getOnlineFriends(String userId) {
    return getFriends(userId).where((friend) => friend.isOnline).toList();
  }

  List<UserProfile> getFavoriteFriends(String userId) {
    final friendIds = _friendships.values
        .where((f) =>
    (f.user1Id == userId || f.user2Id == userId) && f.isFavorite)
        .map((f) => f.getFriendId(userId))
        .toList();

    return friendIds
        .map((id) => _userProfiles[id])
        .where((profile) => profile != null)
        .cast<UserProfile>()
        .toList();
  }

  List<FriendRequest> getPendingRequests(String userId) {
    return _pendingRequests.values
        .where((req) => req.recipientId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<FriendRequest> getSentRequests(String userId) {
    return _pendingRequests.values
        .where((req) => req.senderId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ============ Mutual Friends ============

  List<String> getMutualFriendIds(String userId1, String userId2) {
    final user1Friends = getFriendIds(userId1).toSet();
    final user2Friends = getFriendIds(userId2).toSet();
    return user1Friends.intersection(user2Friends).toList();
  }

  List<UserProfile> getMutualFriends(String userId1, String userId2) {
    final mutualIds = getMutualFriendIds(userId1, userId2);
    return mutualIds
        .map((id) => _userProfiles[id])
        .where((profile) => profile != null)
        .cast<UserProfile>()
        .toList();
  }

  int getMutualFriendCount(String userId1, String userId2) {
    return getMutualFriendIds(userId1, userId2).length;
  }

  // ============ Friend Suggestions ============

  List<FriendSuggestion> getFriendSuggestions(String userId, {int limit = 20}) {
    // Check cache
    if (_suggestionCache.containsKey(userId) &&
        _lastSuggestionUpdate != null &&
        DateTime.now().difference(_lastSuggestionUpdate!).inMinutes < 10) {
      return _suggestionCache[userId]!.take(limit).toList();
    }

    // Generate suggestions
    final suggestions = _generateSuggestions(userId);
    _suggestionCache[userId] = suggestions;
    _lastSuggestionUpdate = DateTime.now();

    return suggestions.take(limit).toList();
  }

  List<FriendSuggestion> _generateSuggestions(String userId) {
    final suggestions = <FriendSuggestion>[];
    final currentFriends = getFriendIds(userId).toSet();
    final blockedByUser = getBlockedUsers(userId).toSet();

    // Get friends of friends
    for (final friendId in currentFriends) {
      final friendsOfFriend = getFriendIds(friendId);

      for (final candidateId in friendsOfFriend) {
        // Skip if already friends, self, or blocked
        if (candidateId == userId ||
            currentFriends.contains(candidateId) ||
            blockedByUser.contains(candidateId)) {
          continue;
        }

        final profile = _userProfiles[candidateId];
        if (profile == null) continue;

        final mutualIds = getMutualFriendIds(userId, candidateId);

        suggestions.add(FriendSuggestion(
          user: profile,
          mutualFriendCount: mutualIds.length,
          mutualFriendIds: mutualIds,
          reason: '${mutualIds.length} mutual ${mutualIds.length == 1 ? "friend" : "friends"}',
          score: mutualIds.length.toDouble(),
        ));
      }
    }

    // Remove duplicates and sort by score
    final uniqueSuggestions = <String, FriendSuggestion>{};
    for (final suggestion in suggestions) {
      final existing = uniqueSuggestions[suggestion.user.id];
      if (existing == null || suggestion.score > existing.score) {
        uniqueSuggestions[suggestion.user.id] = suggestion;
      }
    }

    final sortedSuggestions = uniqueSuggestions.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return sortedSuggestions;
  }

  // ============ Search ============

  List<UserProfile> searchUsers(String query, {String? excludeUserId}) {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return _userProfiles.values
        .where((profile) {
      if (excludeUserId != null && profile.id == excludeUserId) {
        return false;
      }
      return profile.displayName.toLowerCase().contains(lowerQuery) ||
          (profile.username?.toLowerCase().contains(lowerQuery) ?? false);
    })
        .toList();
  }

  // ============ Streams ============

  Stream<List<String>> watchFriendList(String userId) {
    _friendListStreams[userId] ??= StreamController<List<String>>.broadcast();

    // Send initial data
    Future.delayed(Duration.zero, () {
      _broadcastFriendListUpdate(userId);
    });

    return _friendListStreams[userId]!.stream;
  }

  Stream<List<FriendRequest>> watchPendingRequests(String userId) {
    _requestStreams[userId] ??= StreamController<List<FriendRequest>>.broadcast();

    // Send initial data
    Future.delayed(Duration.zero, () {
      _broadcastRequestUpdate(userId);
    });

    return _requestStreams[userId]!.stream;
  }

  void _broadcastFriendListUpdate(String userId) {
    final controller = _friendListStreams[userId];
    if (controller != null && !controller.isClosed) {
      controller.add(getFriendIds(userId));
    }
  }

  void _broadcastRequestUpdate(String userId) {
    final controller = _requestStreams[userId];
    if (controller != null && !controller.isClosed) {
      controller.add(getPendingRequests(userId));
    }
  }

  // ============ Helper Methods ============

  Friendship? _findFriendship(String userId1, String userId2) {
    try {
      return _friendships.values.firstWhere((f) =>
      (f.user1Id == userId1 && f.user2Id == userId2) ||
          (f.user1Id == userId2 && f.user2Id == userId1));
    } catch (e) {
      return null;
    }
  }

  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${_pendingRequests.length}';
  }

  String _generateFriendshipId() {
    return 'friendship_${DateTime.now().millisecondsSinceEpoch}_${_friendships.length}';
  }

  UserProfile? getUserProfile(String userId) {
    return _userProfiles[userId];
  }

  // ============ Mock Data ============

  void _loadMockData() {
    // Create mock user profiles
    final mockUsers = [
      UserProfile(id: 'user_1', displayName: 'Sarah Chen', username: '@sarah', level: 15, totalPoints: 2500, isOnline: true),
      UserProfile(id: 'user_2', displayName: 'Mike Johnson', username: '@mikej', level: 12, totalPoints: 1800, isOnline: false),
      UserProfile(id: 'user_3', displayName: 'Emma Davis', username: '@emmad', level: 20, totalPoints: 4200, isOnline: true),
      UserProfile(id: 'user_4', displayName: 'James Wilson', username: '@jamesw', level: 18, totalPoints: 3600, isOnline: true),
      UserProfile(id: 'user_5', displayName: 'Lisa Anderson', username: '@lisaa', level: 14, totalPoints: 2200, isOnline: false),
      UserProfile(id: 'user_6', displayName: 'David Brown', username: '@davidb', level: 16, totalPoints: 2800, isOnline: true),
      UserProfile(id: 'user_7', displayName: 'Sophie Taylor', username: '@sophiet', level: 19, totalPoints: 3900, isOnline: false),
      UserProfile(id: 'user_8', displayName: 'Ryan Martinez', username: '@ryanm', level: 13, totalPoints: 1950, isOnline: true),
    ];

    for (final user in mockUsers) {
      _userProfiles[user.id] = user;
    }

    LogManager.debug('Loaded ${mockUsers.length} mock user profiles');
  }

  // ============ Analytics ============

  Map<String, dynamic> getAnalytics(String userId) {
    final friends = getFriendIds(userId);
    final onlineFriends = getOnlineFriends(userId);
    final pendingRequests = getPendingRequests(userId);
    final sentRequests = getSentRequests(userId);
    final blocked = getBlockedUsers(userId);

    return {
      'totalFriends': friends.length,
      'onlineFriends': onlineFriends.length,
      'pendingRequests': pendingRequests.length,
      'sentRequests': sentRequests.length,
      'blockedUsers': blocked.length,
      'friendsWithNicknames': _friendships.values
          .where((f) => f.nickname != null &&
          (f.user1Id == userId || f.user2Id == userId))
          .length,
      'favoriteFriends': getFavoriteFriends(userId).length,
    };
  }
}
