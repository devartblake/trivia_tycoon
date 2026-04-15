import '../api_service.dart';
import '../../models/social/friend_list_item_dto.dart';
import '../../models/social/friend_request_dto.dart';
import '../../models/social/friend_suggestion_dto.dart';
import '../../models/social/paginated_social_response.dart';

class BackendProfileSocialService {
  BackendProfileSocialService(this._apiService);

  final ApiService _apiService;

  Future<List<Map<String, dynamic>>> searchUsers(String handle) async {
    final response = await _apiService.get(
      '/users/search',
      queryParameters: {'handle': handle},
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
    return _apiService.get('/users/$userId/career-summary');
  }

  Future<Map<String, dynamic>> getLoadout() {
    return _apiService.get('/users/me/preferences/loadout');
  }

  Future<Map<String, dynamic>> saveLoadout(Map<String, dynamic> loadout) {
    return _apiService.put('/users/me/preferences/loadout', body: loadout);
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
    final response = await _apiService.post(
      '/users/me/friends/request',
      body: {
        'targetUserId': targetUserId,
      },
    );
    return FriendRequestDto.fromJson(response);
  }

  Future<FriendRequestDto> acceptFriendRequest(String requestId) async {
    final response = await _apiService.post(
      '/users/me/friends/requests/$requestId/accept',
      body: const <String, dynamic>{},
    );
    return FriendRequestDto.fromJson(response);
  }

  Future<FriendRequestDto> declineFriendRequest(String requestId) async {
    final response = await _apiService.post(
      '/users/me/friends/requests/$requestId/decline',
      body: const <String, dynamic>{},
    );
    return FriendRequestDto.fromJson(response);
  }

  Future<List<FriendSuggestionDto>> getFriendSuggestions() async {
    final response = await _apiService.getList('/users/me/friends/suggestions');
    return response
        .map(FriendSuggestionDto.fromJson)
        .toList(growable: false);
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
    );
  }
}
