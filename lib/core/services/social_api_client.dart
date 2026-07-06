import 'package:logging/logging.dart';
import 'api_service.dart';
import 'social/friends_models.dart';
import 'social/parties_models.dart';

/// FriendsApiClient handles all friend relationship operations.
///
/// Endpoints (REST):
///   POST   /friends/request                — send friend request
///   GET    /friends                        — list friends with pagination
///   GET    /friends/requests/pending       — list pending requests
///   POST   /friends/request/{id}/accept    — accept friend request
///   POST   /friends/request/{id}/decline   — decline friend request
///   POST   /friends/{id}/remove            — remove friend
///   GET    /search/players                 — search players by username
class FriendsApiClient {
  static final _log = Logger('FriendsApiClient');

  final ApiService _apiService;

  FriendsApiClient(this._apiService);

  /// Send a friend request to another player.
  ///
  /// Backend endpoint: POST /friends/request
  /// Returns: void on success, throws exception on error
  Future<void> sendFriendRequest(String targetPlayerId) async {
    _log.info('Sending friend request to: $targetPlayerId');
    final body = {'targetPlayerId': targetPlayerId};
    await _apiService.post('/friends/request', body: body);
  }

  /// Get list of friends with pagination.
  ///
  /// Backend endpoint: GET /friends?page=X&pageSize=Y
  /// Returns: FriendsListResponse with friend list and pagination info
  Future<FriendsListResponse> listFriends({
    int page = 1,
    int pageSize = 20,
  }) async {
    _log.info('Fetching friends list: page=$page pageSize=$pageSize');
    final params = {
      'page': page,
      'pageSize': pageSize,
    };
    final json = await _apiService.get('/friends', queryParameters: params);
    return FriendsListResponse.fromJson(json);
  }

  /// Get pending friend requests.
  ///
  /// Backend endpoint: GET /friends/requests/pending?page=X&pageSize=Y
  /// Returns: FriendRequestsResponse with pending requests
  Future<FriendRequestsResponse> listPendingRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    _log.info('Fetching pending requests: page=$page pageSize=$pageSize');
    final params = {
      'page': page,
      'pageSize': pageSize,
    };
    final json = await _apiService.get(
      '/friends/requests/pending',
      queryParameters: params,
    );
    return FriendRequestsResponse.fromJson(json);
  }

  /// Accept a friend request.
  ///
  /// Backend endpoint: POST /friends/request/{requestId}/accept
  /// Returns: void on success, throws exception on error
  Future<void> acceptFriendRequest(String requestId) async {
    _log.info('Accepting friend request: $requestId');
    await _apiService.post('/friends/request/$requestId/accept', body: {});
  }

  /// Decline a friend request.
  ///
  /// Backend endpoint: POST /friends/request/{requestId}/decline
  /// Returns: void on success, throws exception on error
  Future<void> declineFriendRequest(String requestId) async {
    _log.info('Declining friend request: $requestId');
    await _apiService.post('/friends/request/$requestId/decline', body: {});
  }

  /// Remove a friend.
  ///
  /// Backend endpoint: POST /friends/{friendId}/remove
  /// Returns: void on success, throws exception on error
  Future<void> removeFriend(String friendId) async {
    _log.info('Removing friend: $friendId');
    await _apiService.post('/friends/$friendId/remove', body: {});
  }

  /// Search for players by username.
  ///
  /// Backend endpoint: GET /search/players?query=X
  /// Returns: PlayerSearchResponse with search results
  Future<PlayerSearchResponse> searchPlayers(String query) async {
    _log.info('Searching players: query=$query');
    final params = {'query': query};
    final json = await _apiService.get(
      '/search/players',
      queryParameters: params,
    );
    return PlayerSearchResponse.fromJson(json);
  }
}

/// PartyApiClient handles all party/group operations.
///
/// Endpoints (REST):
///   POST   /party                          — create party
///   GET    /party                          — list parties
///   GET    /party/{partyId}                — get party details
///   POST   /party/{partyId}/invite         — invite player to party
///   POST   /party/invites/{id}/accept      — accept party invite
///   POST   /party/invites/{id}/decline     — decline party invite
///   POST   /party/{partyId}/leave          — leave party
///   POST   /party/{partyId}/disband        — disband party (owner only)
class PartyApiClient {
  static final _log = Logger('PartyApiClient');

  final ApiService _apiService;

  PartyApiClient(this._apiService);

  /// Create a new party.
  ///
  /// Backend endpoint: POST /party
  /// Returns: PartyResponse with party details
  Future<PartyResponse> createParty({
    required String name,
    String? description,
    int maxMembers = 4,
    String? gameMode,
  }) async {
    _log.info('Creating party: $name (max: $maxMembers members)');
    final body = {
      'name': name,
      if (description != null) 'description': description,
      'maxMembers': maxMembers,
      if (gameMode != null) 'gameMode': gameMode,
    };
    final json = await _apiService.post('/party', body: body);
    return PartyResponse.fromJson(json);
  }

  /// Get party details.
  ///
  /// Backend endpoint: GET /party/{partyId}
  /// Returns: PartyDetailResponse with members and invites
  Future<PartyDetailResponse> getPartyDetails(String partyId) async {
    _log.info('Fetching party details: $partyId');
    final json = await _apiService.get('/party/$partyId');
    return PartyDetailResponse.fromJson(json);
  }

  /// List parties for current player.
  ///
  /// Backend endpoint: GET /party?page=X&pageSize=Y&status=Z
  /// Returns: PartiesListResponse with paginated list
  Future<PartiesListResponse> listParties({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    _log.info('Listing parties: page=$page status=$status');
    final params = {
      'page': page,
      'pageSize': pageSize,
      if (status != null) 'status': status,
    };
    final json = await _apiService.get('/party', queryParameters: params);
    return PartiesListResponse.fromJson(json);
  }

  /// Invite a player to the party.
  ///
  /// Backend endpoint: POST /party/{partyId}/invite
  /// Returns: void on success, throws exception on error
  Future<void> inviteToParty({
    required String partyId,
    required String targetPlayerId,
  }) async {
    _log.info('Inviting $targetPlayerId to party $partyId');
    final body = {'targetPlayerId': targetPlayerId};
    await _apiService.post('/party/$partyId/invite', body: body);
  }

  /// Accept a party invite.
  ///
  /// Backend endpoint: POST /party/invites/{inviteId}/accept
  /// Returns: void on success, throws exception on error
  Future<void> acceptPartyInvite(String inviteId) async {
    _log.info('Accepting party invite: $inviteId');
    await _apiService.post('/party/invites/$inviteId/accept', body: {});
  }

  /// Decline a party invite.
  ///
  /// Backend endpoint: POST /party/invites/{inviteId}/decline
  /// Returns: void on success, throws exception on error
  Future<void> declinePartyInvite(String inviteId) async {
    _log.info('Declining party invite: $inviteId');
    await _apiService.post('/party/invites/$inviteId/decline', body: {});
  }

  /// Leave a party.
  ///
  /// Backend endpoint: POST /party/{partyId}/leave
  /// Returns: void on success, throws exception on error
  Future<void> leaveParty(String partyId) async {
    _log.info('Leaving party: $partyId');
    await _apiService.post('/party/$partyId/leave', body: {});
  }

  /// Disband a party (owner only).
  ///
  /// Backend endpoint: POST /party/{partyId}/disband
  /// Returns: void on success, throws exception on error
  Future<void> disbandParty(String partyId) async {
    _log.info('Disbanding party: $partyId');
    await _apiService.post('/party/$partyId/disband', body: {});
  }
}
