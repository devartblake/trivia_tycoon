import 'package:logging/logging.dart';
import 'api_service.dart';
import 'social/friends_models.dart';
import 'social/parties_models.dart';

/// FriendsApiClient handles all friend relationship operations.
///
/// Canonical backend surface (verified against
/// Synaptix.Backend.Api/Features/Users/UserFriendsEndpoints.cs — the
/// authenticated `/users/me/...` group; the acting player is derived from the
/// JWT server-side, so no player id is ever sent by the client):
///
///   GET    /users/me/friends?page&pageSize             — list friends
///   GET    /users/me/friends/requests?page&pageSize    — incoming pending requests
///   GET    /users/me/friends/requests/sent             — outgoing requests
///   POST   /users/me/friends/request {targetUserId}    — send friend request
///   POST   /users/me/friends/requests/{id}/accept      — accept request
///   POST   /users/me/friends/requests/{id}/decline     — decline request
///   DELETE /users/me/friends/{friendPlayerId}          — remove friend
///   GET    /users/me/friends/suggestions               — friend suggestions
///   GET    /users/search?handle&page&pageSize          — search players by handle
class FriendsApiClient {
  static final _log = Logger('FriendsApiClient');

  final ApiService _apiService;

  FriendsApiClient(this._apiService);

  /// Send a friend request to another player.
  ///
  /// Backend endpoint: POST /users/me/friends/request
  Future<void> sendFriendRequest(String targetPlayerId) async {
    _log.info('Sending friend request to: $targetPlayerId');
    final body = {'targetUserId': targetPlayerId};
    await _apiService.post('/users/me/friends/request', body: body);
  }

  /// Get list of friends with pagination.
  ///
  /// Backend endpoint: GET /users/me/friends?page=X&pageSize=Y
  Future<FriendsListResponse> listFriends({
    int page = 1,
    int pageSize = 20,
  }) async {
    _log.info('Fetching friends list: page=$page pageSize=$pageSize');
    final params = {
      'page': page,
      'pageSize': pageSize,
    };
    final json =
        await _apiService.get('/users/me/friends', queryParameters: params);
    return FriendsListResponse.fromJson(json);
  }

  /// Get incoming pending friend requests.
  ///
  /// Backend endpoint: GET /users/me/friends/requests?page=X&pageSize=Y
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
      '/users/me/friends/requests',
      queryParameters: params,
    );
    return FriendRequestsResponse.fromJson(json);
  }

  /// Accept a friend request.
  ///
  /// Backend endpoint: POST /users/me/friends/requests/{requestId}/accept
  Future<void> acceptFriendRequest(String requestId) async {
    _log.info('Accepting friend request: $requestId');
    await _apiService.post(
      '/users/me/friends/requests/$requestId/accept',
      body: const {},
    );
  }

  /// Decline a friend request.
  ///
  /// Backend endpoint: POST /users/me/friends/requests/{requestId}/decline
  Future<void> declineFriendRequest(String requestId) async {
    _log.info('Declining friend request: $requestId');
    await _apiService.post(
      '/users/me/friends/requests/$requestId/decline',
      body: const {},
    );
  }

  /// Remove a friend.
  ///
  /// Backend endpoint: DELETE /users/me/friends/{friendPlayerId}
  Future<void> removeFriend(String friendId) async {
    _log.info('Removing friend: $friendId');
    await _apiService.delete('/users/me/friends/$friendId');
  }

  /// Search for players by handle/username.
  ///
  /// Backend endpoint: GET /users/search?handle=X&page&pageSize
  /// (backend requires at least 2 characters)
  Future<PlayerSearchResponse> searchPlayers(String query) async {
    _log.info('Searching players: query=$query');
    if (query.trim().length < 2) {
      return const PlayerSearchResponse(results: [], totalCount: 0);
    }
    final params = {'handle': query.trim(), 'page': 1, 'pageSize': 20};
    final json = await _apiService.get(
      '/users/search',
      queryParameters: params,
    );
    return PlayerSearchResponse.fromJson(json);
  }
}

/// PartyApiClient handles all party/group operations.
///
/// Canonical backend surface (verified against
/// Synaptix.Backend.Api/Features/Party/PartyEndpoints.cs). This surface takes
/// explicit player ids in request bodies, so callers must supply the current
/// player's id.
///
///   POST   /party {leaderPlayerId}                      — create party
///   GET    /party/{partyId}                             — get party roster
///   POST   /party/{partyId}/invite {fromPlayerId,toPlayerId} — invite player
///   POST   /party/invites/{id}/accept {playerId}        — accept invite
///   POST   /party/invites/{id}/decline {playerId}       — decline invite
///   POST   /party/{partyId}/leave {playerId}            — leave party
///   GET    /party/invites?playerId&box&page&pageSize    — list invites
class PartyApiClient {
  static final _log = Logger('PartyApiClient');

  final ApiService _apiService;

  PartyApiClient(this._apiService);

  /// Create a new party led by [leaderPlayerId].
  ///
  /// Backend endpoint: POST /party
  Future<PartyRoster> createParty({required String leaderPlayerId}) async {
    _log.info('Creating party for leader: $leaderPlayerId');
    final json = await _apiService.post(
      '/party',
      body: {'leaderPlayerId': leaderPlayerId},
    );
    return PartyRoster.fromJson(json);
  }

  /// Get party roster/details.
  ///
  /// Backend endpoint: GET /party/{partyId}
  Future<PartyRoster> getPartyRoster(String partyId) async {
    _log.info('Fetching party roster: $partyId');
    final json = await _apiService.get('/party/$partyId');
    return PartyRoster.fromJson(json);
  }

  /// List party invites for [playerId].
  ///
  /// Backend endpoint: GET /party/invites?playerId=&box=incoming|outgoing|all
  Future<List<PartyInvite>> listInvites({
    required String playerId,
    String box = 'incoming',
    int page = 1,
    int pageSize = 50,
  }) async {
    _log.info('Fetching party invites: player=$playerId box=$box');
    final json = await _apiService.get('/party/invites', queryParameters: {
      'playerId': playerId,
      'box': box,
      'page': page,
      'pageSize': pageSize,
    });
    final items = json['items'] as List? ?? const [];
    return items
        .whereType<Map>()
        .map((item) => PartyInvite.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  /// Invite a player to the party.
  ///
  /// Backend endpoint: POST /party/{partyId}/invite
  Future<void> inviteToParty({
    required String partyId,
    required String fromPlayerId,
    required String targetPlayerId,
  }) async {
    _log.info('Inviting $targetPlayerId to party $partyId');
    await _apiService.post('/party/$partyId/invite', body: {
      'fromPlayerId': fromPlayerId,
      'toPlayerId': targetPlayerId,
    });
  }

  /// Accept a party invitation.
  ///
  /// Backend endpoint: POST /party/invites/{inviteId}/accept
  Future<void> acceptInvite({
    required String inviteId,
    required String playerId,
  }) async {
    _log.info('Accepting party invite: $inviteId');
    await _apiService.post(
      '/party/invites/$inviteId/accept',
      body: {'playerId': playerId},
    );
  }

  /// Decline a party invitation.
  ///
  /// Backend endpoint: POST /party/invites/{inviteId}/decline
  Future<void> declineInvite({
    required String inviteId,
    required String playerId,
  }) async {
    _log.info('Declining party invite: $inviteId');
    await _apiService.post(
      '/party/invites/$inviteId/decline',
      body: {'playerId': playerId},
    );
  }

  /// Leave a party.
  ///
  /// Backend endpoint: POST /party/{partyId}/leave
  Future<void> leaveParty({
    required String partyId,
    required String playerId,
  }) async {
    _log.info('Leaving party: $partyId');
    await _apiService.post(
      '/party/$partyId/leave',
      body: {'playerId': playerId},
    );
  }
}
