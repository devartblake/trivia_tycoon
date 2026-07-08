/// Riverpod providers for social features (Friends & Parties)
///
/// This module provides all state management for social systems.
/// Includes providers for API clients, services, and reactive state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/core_providers.dart';
import '../../../core/services/social_api_client.dart';
import '../../../core/services/social/friends_models.dart';
import '../../../core/services/social/parties_models.dart';
import '../services/friends_service.dart';
import '../services/parties_service.dart';

// ============================================================================
// API Clients
// ============================================================================

/// FriendsApiClient provider - REST API layer
final friendsApiClientProvider = Provider<FriendsApiClient>((ref) {
  return FriendsApiClient(ref.read(apiServiceProvider));
});

/// PartyApiClient provider - REST API layer
final partyApiClientProvider = Provider<PartyApiClient>((ref) {
  return PartyApiClient(ref.read(apiServiceProvider));
});

// ============================================================================
// Services
// ============================================================================

/// FriendsService provider - business logic layer
final friendsServiceProvider = Provider<FriendsService>((ref) {
  final apiClient = ref.read(friendsApiClientProvider);
  return FriendsService(apiClient);
});

/// PartiesService provider - business logic layer
final partiesServiceProvider = Provider<PartiesService>((ref) {
  final apiClient = ref.read(partyApiClientProvider);
  return PartiesService(apiClient);
});

// ============================================================================
// Friends State
// ============================================================================

/// Friends list provider - fetches all friends
final friendsListProvider = FutureProvider<List<Friend>>((ref) async {
  final service = ref.read(friendsServiceProvider);
  return await service.getFriends();
});

/// Pending friend requests provider
final pendingFriendRequestsProvider = FutureProvider<List<FriendRequest>>((ref) async {
  final service = ref.read(friendsServiceProvider);
  return await service.getPendingRequests();
});

/// Player search provider - searches by query string
///
/// Example usage:
/// ```dart
/// final results = ref.watch(playerSearchProvider('john'));
/// ```
final playerSearchProvider =
    FutureProvider.family<List<PlayerSearchResult>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final service = ref.read(friendsServiceProvider);
  return await service.searchPlayers(query);
});

/// Combined friends state provider - groups friends and requests
class CombinedFriendsState {
  final List<Friend> friends;
  final List<FriendRequest> pendingRequests;

  const CombinedFriendsState({
    required this.friends,
    required this.pendingRequests,
  });
}

final combinedFriendsStateProvider = FutureProvider<CombinedFriendsState>((ref) async {
  final friendsAsync = ref.watch(friendsListProvider);
  final requestsAsync = ref.watch(pendingFriendRequestsProvider);

  return friendsAsync.when(
    data: (friends) => requestsAsync.when(
      data: (requests) => CombinedFriendsState(
        friends: friends,
        pendingRequests: requests,
      ),
      loading: () => throw Exception('Loading requests...'),
      error: (err, stack) => throw err,
    ),
    loading: () => throw Exception('Loading friends...'),
    error: (err, stack) => throw err,
  );
});

// ============================================================================
// Parties State
// ============================================================================

/// Active parties provider - fetches user's active parties
final activePartiesProvider = FutureProvider<List<PartyResponse>>((ref) async {
  final service = ref.read(partiesServiceProvider);
  return await service.getActiveParties();
});

/// All parties provider - fetches all parties (active, completed, etc)
final allPartiesProvider = FutureProvider<List<PartyResponse>>((ref) async {
  final service = ref.read(partiesServiceProvider);
  return await service.getAllParties();
});

/// Party details provider - fetches specific party info
///
/// Example usage:
/// ```dart
/// final details = ref.watch(partyDetailsProvider('party-123'));
/// ```
final partyDetailsProvider = FutureProvider.family<PartyDetailResponse, String>(
  (ref, partyId) async {
    final service = ref.read(partiesServiceProvider);
    return await service.getPartyDetails(partyId);
  },
);

// ============================================================================
// Action Methods (for mutations)
// ============================================================================

/// Send a friend request
Future<void> sendFriendRequest(WidgetRef ref, String targetPlayerId) async {
  final service = ref.read(friendsServiceProvider);
  await service.sendRequest(targetPlayerId);
  // Invalidate search results and requests so watchers refetch
  ref.invalidate(playerSearchProvider);
  ref.invalidate(pendingFriendRequestsProvider);
}

/// Accept a friend request
Future<void> acceptFriendRequest(WidgetRef ref, String requestId) async {
  final service = ref.read(friendsServiceProvider);
  await service.acceptRequest(requestId);
  // Refresh both lists
  ref.invalidate(friendsListProvider);
  ref.invalidate(pendingFriendRequestsProvider);
}

/// Decline a friend request
Future<void> declineFriendRequest(WidgetRef ref, String requestId) async {
  final service = ref.read(friendsServiceProvider);
  await service.declineRequest(requestId);
  // Refresh requests list
  ref.invalidate(pendingFriendRequestsProvider);
}

/// Remove a friend
Future<void> removeFriend(WidgetRef ref, String friendId) async {
  final service = ref.read(friendsServiceProvider);
  await service.removeFriend(friendId);
  // Refresh friends list
  ref.invalidate(friendsListProvider);
}

/// Create a new party
Future<PartyResponse> createParty(
  WidgetRef ref, {
  required String name,
  String? description,
  int maxMembers = 4,
  String? gameMode,
}) async {
  final service = ref.read(partiesServiceProvider);
  final party = await service.createParty(
    name: name,
    description: description,
    maxMembers: maxMembers,
    gameMode: gameMode,
  );
  // Refresh parties list
  ref.invalidate(activePartiesProvider);
  return party;
}

/// Invite player to party
Future<void> inviteToParty(
  WidgetRef ref, {
  required String partyId,
  required String targetPlayerId,
}) async {
  final service = ref.read(partiesServiceProvider);
  await service.inviteToParty(
    partyId: partyId,
    targetPlayerId: targetPlayerId,
  );
  // Refresh party details
  ref.invalidate(partyDetailsProvider(partyId));
}

/// Accept party invitation
Future<void> acceptPartyInvitation(WidgetRef ref, String inviteId) async {
  final service = ref.read(partiesServiceProvider);
  await service.acceptInvite(inviteId);
  // Refresh parties list
  ref.invalidate(activePartiesProvider);
}

/// Decline party invitation
Future<void> declinePartyInvitation(WidgetRef ref, String inviteId) async {
  final service = ref.read(partiesServiceProvider);
  await service.declineInvite(inviteId);
}

/// Leave a party
Future<void> leaveParty(WidgetRef ref, String partyId) async {
  final service = ref.read(partiesServiceProvider);
  await service.leaveParty(partyId);
  // Refresh parties list
  ref.invalidate(activePartiesProvider);
}

/// Disband a party (owner only)
Future<void> disbandParty(WidgetRef ref, String partyId) async {
  final service = ref.read(partiesServiceProvider);
  await service.disbandParty(partyId);
  // Refresh parties list
  ref.invalidate(activePartiesProvider);
}
