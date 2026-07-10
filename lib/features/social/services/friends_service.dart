import 'package:logging/logging.dart';
import '../../../core/services/social_api_client.dart';
import '../../../core/services/social/friends_models.dart';

/// Business logic layer for friend operations.
///
/// Handles:
/// - Friend requests (send, accept, decline)
/// - Friends list management
/// - Player search
/// - Error handling and logging
class FriendsService {
  static final _log = Logger('FriendsService');

  final FriendsApiClient _apiClient;

  FriendsService(this._apiClient);

  /// Send a friend request to another player
  Future<void> sendRequest(String targetPlayerId) async {
    try {
      _log.info('Sending friend request to: $targetPlayerId');
      await _apiClient.sendFriendRequest(targetPlayerId);
      _log.fine('Friend request sent successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to send friend request', e, stackTrace);
      rethrow;
    }
  }

  /// Get current player's friends list
  Future<List<Friend>> getFriends({int page = 1, int pageSize = 20}) async {
    try {
      _log.info('Fetching friends: page=$page pageSize=$pageSize');
      final response =
          await _apiClient.listFriends(page: page, pageSize: pageSize);
      _log.fine('Fetched ${response.friends.length} friends');
      return response.friends;
    } catch (e, stackTrace) {
      _log.warning('Failed to fetch friends', e, stackTrace);
      rethrow;
    }
  }

  /// Get pending friend requests
  Future<List<FriendRequest>> getPendingRequests(
      {int page = 1, int pageSize = 20}) async {
    try {
      _log.info('Fetching pending requests: page=$page pageSize=$pageSize');
      final response =
          await _apiClient.listPendingRequests(page: page, pageSize: pageSize);
      _log.fine('Fetched ${response.requests.length} pending requests');
      return response.requests;
    } catch (e, stackTrace) {
      _log.warning('Failed to fetch pending requests', e, stackTrace);
      rethrow;
    }
  }

  /// Accept a friend request
  Future<void> acceptRequest(String requestId) async {
    try {
      _log.info('Accepting request: $requestId');
      await _apiClient.acceptFriendRequest(requestId);
      _log.fine('Request accepted successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to accept request', e, stackTrace);
      rethrow;
    }
  }

  /// Decline a friend request
  Future<void> declineRequest(String requestId) async {
    try {
      _log.info('Declining request: $requestId');
      await _apiClient.declineFriendRequest(requestId);
      _log.fine('Request declined successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to decline request', e, stackTrace);
      rethrow;
    }
  }

  /// Remove a friend
  Future<void> removeFriend(String friendId) async {
    try {
      _log.info('Removing friend: $friendId');
      await _apiClient.removeFriend(friendId);
      _log.fine('Friend removed successfully');
    } catch (e, stackTrace) {
      _log.warning('Failed to remove friend', e, stackTrace);
      rethrow;
    }
  }

  /// Search for players by username
  Future<List<PlayerSearchResult>> searchPlayers(String query) async {
    if (query.isEmpty) {
      return [];
    }
    try {
      _log.info('Searching players: $query');
      final response = await _apiClient.searchPlayers(query);
      _log.fine('Found ${response.results.length} players');
      return response.results;
    } catch (e, stackTrace) {
      _log.warning('Failed to search players', e, stackTrace);
      rethrow;
    }
  }
}
