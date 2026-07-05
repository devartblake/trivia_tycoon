import 'package:logging/logging.dart';
import 'api_service.dart';

/// TODO: IMPLEMENTATION NEEDED
///
/// This file documents the social API contract.
/// Backend endpoints are ready but Flutter client implementation is incomplete.
/// Implementation status: PENDING (marked as future scope in Sprint Planning)
///
/// Endpoints provided by backend:
///   POST   /friends/request                — send friend request
///   GET    /friends                        — list friends with pagination
///   POST   /friends/request/{id}/accept    — accept friend request
///   POST   /friends/request/{id}/decline   — decline friend request
///   POST   /party                          — create or join party
///   GET    /party/{partyId}                — get party details
///   POST   /party/{partyId}/invite         — invite player to party
///   POST   /party/invites/{id}/accept      — accept party invite
///   POST   /party/invites/{id}/decline     — decline party invite

class FriendsApiClient {
  static final _log = Logger('FriendsApiClient');

  final ApiService _apiService;

  FriendsApiClient(this._apiService);

  /// Send a friend request to another player.
  ///
  /// Backend endpoint ready: POST /friends/request
  /// IMPLEMENTATION STATUS: PENDING
  Future<void> sendFriendRequest(String targetPlayerId) async {
    throw UnimplementedError(
      'Friends feature is currently out of scope for this release.\n'
      'Backend endpoint is ready: POST /friends/request\n'
      'To implement: Create request DTO, call ApiService.post(), handle response'
    );
  }

  /// Get list of friends.
  ///
  /// Backend endpoint ready: GET /friends?page=X&pageSize=Y
  /// IMPLEMENTATION STATUS: PENDING
  Future<List<Map<String, dynamic>>> listFriends({int page = 1, int pageSize = 20}) async {
    throw UnimplementedError(
      'Friends feature is currently out of scope for this release.\n'
      'Backend endpoint is ready: GET /friends\n'
      'To implement: Call ApiService.get(), parse response list'
    );
  }

  /// Accept a friend request from another player.
  ///
  /// Backend endpoint ready: POST /friends/request/{requestId}/accept
  /// IMPLEMENTATION STATUS: PENDING
  Future<void> acceptFriendRequest(String requestId) async {
    throw UnimplementedError(
      'Friends feature is currently out of scope for this release.\n'
      'Backend endpoint is ready: POST /friends/request/{id}/accept'
    );
  }

  /// Decline a friend request.
  ///
  /// Backend endpoint ready: POST /friends/request/{requestId}/decline
  /// IMPLEMENTATION STATUS: PENDING
  Future<void> declineFriendRequest(String requestId) async {
    throw UnimplementedError(
      'Friends feature is currently out of scope for this release.\n'
      'Backend endpoint is ready: POST /friends/request/{id}/decline'
    );
  }
}

class PartyApiClient {
  static final _log = Logger('PartyApiClient');

  final ApiService _apiService;

  PartyApiClient(this._apiService);

  /// Create or join a party for group gameplay.
  ///
  /// Backend endpoint ready: POST /party
  /// IMPLEMENTATION STATUS: PENDING
  Future<Map<String, dynamic>> createParty({
    required String name,
    String? gameMode,
  }) async {
    throw UnimplementedError(
      'Party/Team feature is currently out of scope for this release.\n'
      'Backend endpoint is ready: POST /party\n'
      'To implement: Create party request DTO, call ApiService.post()'
    );
  }

  /// Get party details and member list.
  ///
  /// Backend endpoint ready: GET /party/{partyId}
  /// IMPLEMENTATION STATUS: PENDING
  Future<Map<String, dynamic>> getPartyDetails(String partyId) async {
    throw UnimplementedError(
      'Party/Team feature is currently out of scope for this release.\n'
      'Backend endpoint is ready: GET /party/{partyId}'
    );
  }

  /// Invite a player to the party.
  ///
  /// Backend endpoint ready: POST /party/{partyId}/invite
  /// IMPLEMENTATION STATUS: PENDING
  Future<void> inviteToParty({
    required String partyId,
    required String targetPlayerId,
  }) async {
    throw UnimplementedError(
      'Party/Team feature is currently out of scope for this release.\n'
      'Backend endpoint is ready: POST /party/{partyId}/invite'
    );
  }

  /// Accept a party invite.
  ///
  /// Backend endpoint ready: POST /party/invites/{inviteId}/accept
  /// IMPLEMENTATION STATUS: PENDING
  Future<void> acceptPartyInvite(String inviteId) async {
    throw UnimplementedError(
      'Party/Team feature is currently out of scope for this release.\n'
      'Backend endpoint is ready: POST /party/invites/{inviteId}/accept'
    );
  }

  /// Decline a party invite.
  ///
  /// Backend endpoint ready: POST /party/invites/{inviteId}/decline
  /// IMPLEMENTATION STATUS: PENDING
  Future<void> declinePartyInvite(String inviteId) async {
    throw UnimplementedError(
      'Party/Team feature is currently out of scope for this release.\n'
      'Backend endpoint is ready: POST /party/invites/{inviteId}/decline'
    );
  }
}
