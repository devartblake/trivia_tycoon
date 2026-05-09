import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../api_service.dart';
import '../../models/social/friend_list_item_dto.dart';
import '../../models/social/friend_request_dto.dart';
import '../../models/social/friend_suggestion_dto.dart';
import '../../models/social/paginated_social_response.dart';
import '../../networking/encrypted_api_client.dart';

enum FriendshipStatus { notFriends, requestSent, requestReceived, friends }

class BackendProfileSocialService {
  BackendProfileSocialService(this._apiService, {EncryptedApiClient? encryptedClient})
      : _encryptedClient = encryptedClient;

  final ApiService _apiService;
  final EncryptedApiClient? _encryptedClient;
  static const Duration _socialTimeout = Duration(seconds: 10);

  Future<List<Map<String, dynamic>>> searchUsers(String handle) async {
    final response = await _apiService.get(
      '/users/search',
      queryParameters: {'handle': handle},
      timeout: _socialTimeout,
    );

    final rawItems = response['items'] ??
        response['users'] ??
        response['results'] ??
        response['data'] ??
        const <dynamic>[];

    if (rawItems is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getCareerSummary(String userId) {
    return _apiService.get(
      '/users/$userId/career-summary',
      timeout: _socialTimeout,
    );
  }

  Future<Map<String, dynamic>> getLoadout() {
    return _apiService.get(
      '/users/me/preferences/loadout',
      timeout: _socialTimeout,
    );
  }

  Future<Map<String, dynamic>> saveLoadout(Map<String, dynamic> loadout) async {
    final response = _encryptedClient != null
        ? await _encryptedClient!.putEncrypted('/users/me/preferences/loadout', body: loadout)
        : await _apiService.put('/users/me/preferences/loadout', body: loadout, timeout: _socialTimeout);
    return response;
  }

  Future<PaginatedSocialResponse<FriendListItemDto>> getFriends({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _apiService.get(
      '/users/me/friends',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
      timeout: _socialTimeout,
    );

    final envelope = _apiService.parsePageEnvelope<FriendListItemDto>(
      response,
      FriendListItemDto.fromJson,
    );

    return PaginatedSocialResponse<FriendListItemDto>(
      items: envelope.items,
      page: envelope.page,
      pageSize: envelope.pageSize,
      total: envelope.total,
      totalPages: envelope.totalPages,
    );
  }

  Future<PaginatedSocialResponse<FriendRequestDto>> getIncomingFriendRequests({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _apiService.get(
      '/users/me/friends/requests',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
      timeout: _socialTimeout,
    );

    final envelope = _apiService.parsePageEnvelope<FriendRequestDto>(
      response,
      FriendRequestDto.fromJson,
    );

    return PaginatedSocialResponse<FriendRequestDto>(
      items: envelope.items,
      page: envelope.page,
      pageSize: envelope.pageSize,
      total: envelope.total,
      totalPages: envelope.totalPages,
    );
  }

  Future<PaginatedSocialResponse<FriendRequestDto>> getSentFriendRequests({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _apiService.get(
      '/users/me/friends/requests/sent',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
      timeout: _socialTimeout,
    );

    final envelope = _apiService.parsePageEnvelope<FriendRequestDto>(
      response,
      FriendRequestDto.fromJson,
    );

    return PaginatedSocialResponse<FriendRequestDto>(
      items: envelope.items,
      page: envelope.page,
      pageSize: envelope.pageSize,
      total: envelope.total,
      totalPages: envelope.totalPages,
    );
  }

  Future<FriendRequestDto> sendFriendRequest(String targetUserId) async {
    final body = {'targetUserId': targetUserId};
    final response = _encryptedClient != null
        ? await _encryptedClient!.postEncrypted('/users/me/friends/request', body: body)
        : await _apiService.post('/users/me/friends/request', body: body, timeout: _socialTimeout);
    return FriendRequestDto.fromJson(response);
  }

  Future<FriendRequestDto> acceptFriendRequest(String requestId) async {
    const body = <String, dynamic>{};
    final response = _encryptedClient != null
        ? await _encryptedClient!.postEncrypted('/users/me/friends/requests/$requestId/accept', body: body)
        : await _apiService.post('/users/me/friends/requests/$requestId/accept', body: body, timeout: _socialTimeout);
    return FriendRequestDto.fromJson(response);
  }

  Future<FriendRequestDto> declineFriendRequest(String requestId) async {
    const body = <String, dynamic>{};
    final response = _encryptedClient != null
        ? await _encryptedClient!.postEncrypted('/users/me/friends/requests/$requestId/decline', body: body)
        : await _apiService.post('/users/me/friends/requests/$requestId/decline', body: body, timeout: _socialTimeout);
    return FriendRequestDto.fromJson(response);
  }

  Future<List<FriendSuggestionDto>> getFriendSuggestions() async {
    final response = await _apiService.getList(
      '/users/me/friends/suggestions',
      timeout: _socialTimeout,
    );
    return response.map(FriendSuggestionDto.fromJson).toList(growable: false);
  }

  Future<Map<String, dynamic>> removeFriend(
    String friendId, {
    String? playerId,
  }) {
    return _apiService.delete(
      '/friends',
      body: {
        if (playerId != null && playerId.isNotEmpty) 'playerId': playerId,
        // Send both common field names so the client remains compatible with
        // either backend binder shape while alpha contracts settle.
        'friendId': friendId,
        'targetUserId': friendId,
        'friendPlayerId': friendId,
      },
      timeout: _socialTimeout,
    );
  }

  // ---------------------------------------------------------------------------
  // Cancel sent request
  // ---------------------------------------------------------------------------

  Future<void> cancelFriendRequest(String requestId) {
    return _apiService.delete(
      '/users/me/friends/requests/$requestId',
      body: const <String, dynamic>{},
      timeout: _socialTimeout,
    );
  }

  // ---------------------------------------------------------------------------
  // Block / unblock
  // ---------------------------------------------------------------------------

  // TODO(backend): These endpoints are not yet deployed.
  // They will throw once called; stub provides the correct contract shape.

  Future<void> blockUser(String targetUserId) async {
    final body = {'targetUserId': targetUserId};
    if (_encryptedClient != null) {
      await _encryptedClient!.postEncrypted('/users/me/block', body: body);
    } else {
      await _apiService.post('/users/me/block', body: body, timeout: _socialTimeout);
    }
  }

  Future<void> unblockUser(String targetUserId) {
    return _apiService.delete(
      '/users/me/block/$targetUserId',
      body: const <String, dynamic>{},
      timeout: _socialTimeout,
    );
  }

  Future<List<String>> getBlockedUserIds() async {
    if (kIsWeb) return const [];
    final res = await _apiService.get('/users/me/block', timeout: _socialTimeout);
    final list = res['items'] as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => e['playerId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Local friend preferences — in-process lifetime (same as service singleton)
  // These survive for the duration of the app session; persist via Hive/prefs
  // in a future iteration once AppInit wires those boxes at startup.
  // ---------------------------------------------------------------------------

  final Map<String, String> _nicknames = {};
  final Set<String> _favourites = {};

  void setFriendNickname(String friendId, String nickname) =>
      _nicknames[friendId] = nickname;

  String? getFriendNickname(String friendId) => _nicknames[friendId];

  void toggleFavourite(String friendId) {
    if (_favourites.contains(friendId)) {
      _favourites.remove(friendId);
    } else {
      _favourites.add(friendId);
    }
  }

  bool isFavourite(String friendId) => _favourites.contains(friendId);

  List<String> getFavouriteFriendIds() => List.unmodifiable(_favourites);

  // ---------------------------------------------------------------------------
  // Convenience / derived helpers
  // ---------------------------------------------------------------------------

  Future<FriendshipStatus> getFriendshipStatus(String targetUserId) async {
    final friends = await getFriends();
    if (friends.items.any((f) => f.friendPlayerId == targetUserId)) {
      return FriendshipStatus.friends;
    }
    final sent = await getSentFriendRequests();
    if (sent.items.any((r) => r.toPlayerId == targetUserId)) {
      return FriendshipStatus.requestSent;
    }
    final incoming = await getIncomingFriendRequests();
    if (incoming.items.any((r) => r.fromPlayerId == targetUserId)) {
      return FriendshipStatus.requestReceived;
    }
    return FriendshipStatus.notFriends;
  }

  Future<List<FriendListItemDto>> getOnlineFriends() async {
    final all = await getFriends();
    return all.items.where((f) => f.isOnline).toList(growable: false);
  }

  Future<Map<String, int>> getSocialAnalytics() async {
    final friends = await getFriends();
    final incoming = await getIncomingFriendRequests();
    final sent = await getSentFriendRequests();
    final blocked = await getBlockedUserIds();
    return {
      'totalFriends': friends.total,
      'onlineFriends': friends.items.where((f) => f.isOnline).length,
      'pendingRequests': incoming.total,
      'sentRequests': sent.total,
      'blockedUsers': blocked.length,
      'favouriteFriends': _favourites.length,
    };
  }
}
