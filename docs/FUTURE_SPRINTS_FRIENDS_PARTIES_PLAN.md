# Future Sprints Plan: Friends & Parties Systems

**Date**: 2026-07-05  
**Scope**: Turn-based Friends + Parties/Teams implementation  
**Total Effort**: 12-14 weeks (3-3.5 sprints)  
**Priority**: FUTURE (After Tier 1 Core Features)

---

## Executive Overview

Implement two interconnected social systems enabling:
1. **Friends System** — Player discovery, friend requests, friend lists
2. **Parties/Teams System** — Group formation, invitations, party matchmaking

**Strategic Value**:
- Increases engagement through social connectivity
- Enables group challenges and team-based leaderboards
- Reduces churn through community building
- Supports future group multiplayer features

**Dependencies**:
- ✅ Auth system (already complete)
- ✅ User profiles (already complete)
- ✅ Match REST API (just completed)
- ❌ Group chat/messaging (future, optional)
- ❌ Real-time notifications (WebSocket, future enhancement)

---

## Timeline Overview

```
Sprint 1 (2 weeks): Friends System — Core
Sprint 2 (1.5 weeks): Parties System — Core
Sprint 3 (1 week): Integration & Polish
Sprint 4+ (Optional): Real-time enhancements
```

---

## Sprint 1: Friends System — Core (2 weeks)

### Goals
- [x] FriendsApiClient fully implemented
- [x] Friend request flow working
- [x] Friend list UI displaying
- [x] Accept/decline actions functional
- [x] Search for players by username/handle

### Scope

#### Week 1: Backend Integration + Data Models

**Day 1-2: API Client Implementation**

**File**: `lib/core/services/social_api_client.dart` (Already stubbed, expand from existing)

Replace the UnimplementedError stubs with real implementations:

```dart
class FriendsApiClient {
  final ApiService _apiService;
  static final _log = Logger('FriendsApiClient');

  /// Send friend request to another player
  Future<void> sendFriendRequest(String targetPlayerId) async {
    _log.info('Sending friend request to $targetPlayerId');
    final body = {'targetPlayerId': targetPlayerId};
    await _apiService.post('/friends/request', body: body);
  }

  /// Get list of friends with pagination
  Future<FriendsListResponse> listFriends({
    int page = 1,
    int pageSize = 20,
  }) async {
    _log.info('Fetching friends list: page=$page pageSize=$pageSize');
    final params = {'page': page, 'pageSize': pageSize};
    final json = await _apiService.get('/friends', queryParameters: params);
    return FriendsListResponse.fromJson(json);
  }

  /// Get pending friend requests
  Future<FriendRequestsResponse> listPendingRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    _log.info('Fetching pending requests: page=$page pageSize=$pageSize');
    final params = {'page': page, 'pageSize': pageSize};
    final json = await _apiService.get(
      '/friends/requests/pending',
      queryParameters: params,
    );
    return FriendRequestsResponse.fromJson(json);
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String requestId) async {
    _log.info('Accepting friend request: $requestId');
    await _apiService.post('/friends/request/$requestId/accept', body: {});
  }

  /// Decline friend request
  Future<void> declineFriendRequest(String requestId) async {
    _log.info('Declining friend request: $requestId');
    await _apiService.post('/friends/request/$requestId/decline', body: {});
  }

  /// Remove friend
  Future<void> removeFriend(String friendId) async {
    _log.info('Removing friend: $friendId');
    await _apiService.post('/friends/$friendId/remove', body: {});
  }

  /// Search for players by username
  Future<PlayerSearchResponse> searchPlayers(String query) async {
    _log.info('Searching players: $query');
    final params = {'query': query};
    final json = await _apiService.get('/search/players', queryParameters: params);
    return PlayerSearchResponse.fromJson(json);
  }
}
```

**Create DTOs** (New file: `lib/core/services/social/friends_models.dart`)

```dart
// Request/Response Models
class FriendsListResponse {
  final List<Friend> friends;
  final int totalCount;
  final int page;
  final int pageSize;
  
  // ... fromJson, toJson
}

class FriendRequestsResponse {
  final List<FriendRequest> requests;
  final int totalCount;
  final int page;
  
  // ... fromJson, toJson
}

class PlayerSearchResponse {
  final List<PlayerSearchResult> results;
  final int totalCount;
  
  // ... fromJson, toJson
}

// Domain Models
class Friend {
  final String friendId;
  final String username;
  final String? avatarUrl;
  final String? level;
  final DateTime connectedSince;
  final bool isOnline;
  
  // ... constructor, methods
}

class FriendRequest {
  final String requestId;
  final String fromPlayerId;
  final String fromUsername;
  final DateTime sentAt;
  final String status; // 'pending', 'accepted', 'declined'
  
  // ... constructor, methods
}

class PlayerSearchResult {
  final String playerId;
  final String username;
  final String? avatarUrl;
  final String? level;
  final bool isFriend;
  final bool hasOutgoingRequest;
  final bool hasIncomingRequest;
  
  // ... constructor, methods
}
```

**Day 3: State Management Setup**

**File**: `lib/features/social/providers/friends_providers.dart` (NEW)

```dart
// API Client Provider
final friendsApiClientProvider = Provider<FriendsApiClient>((ref) {
  return FriendsApiClient(ref.read(apiServiceProvider));
});

// Friends Service (Combines API + business logic)
class FriendsService {
  final FriendsApiClient _apiClient;
  
  FriendsService(this._apiClient);
  
  Future<void> sendRequest(String targetPlayerId) async {
    await _apiClient.sendFriendRequest(targetPlayerId);
  }
  
  Future<List<Friend>> getFriends() async {
    final response = await _apiClient.listFriends();
    return response.friends;
  }
  
  Future<List<FriendRequest>> getPendingRequests() async {
    final response = await _apiClient.listPendingRequests();
    return response.requests;
  }
  
  // ... other methods
}

final friendsServiceProvider = Provider<FriendsService>((ref) {
  return FriendsService(ref.read(friendsApiClientProvider));
});

// Friends List State (Riverpod)
final friendsListProvider = FutureProvider<List<Friend>>((ref) async {
  final service = ref.read(friendsServiceProvider);
  return await service.getFriends();
});

final pendingRequestsProvider = FutureProvider<List<FriendRequest>>((ref) async {
  final service = ref.read(friendsServiceProvider);
  return await service.getPendingRequests();
});

// Search State
final playerSearchProvider = FutureProvider.family<
  List<PlayerSearchResult>,
  String
>((ref, query) async {
  if (query.isEmpty) return [];
  final apiClient = ref.read(friendsApiClientProvider);
  final response = await apiClient.searchPlayers(query);
  return response.results;
});
```

**Day 4-5: Service Layer Tests**

Create unit tests for FriendsApiClient:
- Test all 6 methods
- Mock HTTP responses
- Verify error handling
- Test pagination

**File**: `test/core/services/social/friends_api_client_test.dart`

---

#### Week 2: UI Implementation

**Day 1-2: Friends List Screen**

**File**: `lib/features/social/screens/friends_list_screen.dart` (NEW)

```dart
class FriendsListScreen extends ConsumerWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);
    final pendingAsync = ref.watch(pendingRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAddFriendDialog(context),
          ),
        ],
      ),
      body: friendsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorState(context, () => ref.refresh(friendsListProvider)),
        data: (friends) => _buildFriendsList(context, ref, friends, pendingAsync),
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    WidgetRef ref,
    List<Friend> friends,
    AsyncValue<List<FriendRequest>> pendingAsync,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Friends (${friends.length})'),
              Tab(
                text: pendingAsync.maybeWhen(
                  data: (reqs) => 'Requests (${reqs.length})',
                  orElse: () => 'Requests',
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFriendsTab(context, ref, friends),
                _buildRequestsTab(context, ref, pendingAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(BuildContext context, WidgetRef ref, List<Friend> friends) {
    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No friends yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Add friends to play together!', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) => _FriendCard(friend: friends[index]),
    );
  }

  Widget _buildRequestsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<FriendRequest>> pendingAsync,
  ) {
    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading requests')),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(child: Text('No pending requests'));
        }
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) => _FriendRequestCard(
            request: requests[index],
            onAccept: () => _acceptRequest(ref, requests[index].requestId),
            onDecline: () => _declineRequest(ref, requests[index].requestId),
          ),
        );
      },
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    // Show search dialog
    showDialog(
      context: context,
      builder: (context) => _AddFriendDialog(),
    );
  }

  void _acceptRequest(WidgetRef ref, String requestId) async {
    final service = ref.read(friendsServiceProvider);
    await service.acceptRequest(requestId);
    ref.refresh(pendingRequestsProvider);
    ref.refresh(friendsListProvider);
  }

  void _declineRequest(WidgetRef ref, String requestId) async {
    final service = ref.read(friendsServiceProvider);
    await service.declineRequest(requestId);
    ref.refresh(pendingRequestsProvider);
  }
}

// Friend Card Widget
class _FriendCard extends StatelessWidget {
  final Friend friend;

  const _FriendCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(friend.avatarUrl ?? ''),
        ),
        title: Text(friend.username),
        subtitle: Row(
          children: [
            Icon(friend.isOnline ? Icons.circle : Icons.circle_outlined,
              size: 8,
              color: friend.isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(friend.isOnline ? 'Online' : 'Offline'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(child: Text('Challenge')),
            PopupMenuItem(child: Text('Message')),
            PopupMenuItem(child: Text('Remove')),
          ],
        ),
      ),
    );
  }
}

// Friend Request Card Widget
class _FriendRequestCard extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _FriendRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(request.fromUsername),
        subtitle: Text('Sent ${_formatTime(request.sentAt)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: onAccept,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onDecline,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    // Relative time like "2 hours ago"
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// Add Friend Dialog
class _AddFriendDialog extends ConsumerWidget {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(playerSearchProvider(_searchController.text));

    return AlertDialog(
      title: const Text('Add Friend'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search players...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => ref.refresh(playerSearchProvider(_searchController.text)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: searchResults.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
              data: (results) => ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final player = results[index];
                  return ListTile(
                    title: Text(player.username),
                    trailing: _buildActionButton(player, ref),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(PlayerSearchResult player, WidgetRef ref) {
    if (player.isFriend) {
      return Chip(label: const Text('Friend'));
    } else if (player.hasOutgoingRequest) {
      return Chip(label: const Text('Pending'));
    } else if (player.hasIncomingRequest) {
      return const Text('Incoming');
    } else {
      return IconButton(
        icon: const Icon(Icons.person_add),
        onPressed: () => _sendRequest(player.playerId, ref),
      );
    }
  }

  void _sendRequest(String playerId, WidgetRef ref) async {
    final service = ref.read(friendsServiceProvider);
    await service.sendRequest(playerId);
    ref.refresh(playerSearchProvider(_searchController.text));
  }
}
```

**Day 3: Integration with Profile Screen**

Add friend action button to player profile view:
- Show friend status
- Allow sending friend request
- Allow removing friend
- Show mutual friends count

**Day 4-5: Polish & Edge Cases**

- Handle network errors with retry
- Show loading states
- Handle already-friend cases
- Block/unblock functionality (optional)

---

### Deliverables (Sprint 1)

✅ **Code**: 800 LOC (Models + Services + UI)
✅ **Tests**: Unit tests for API client + integration tests
✅ **UI**: Friends list + pending requests + player search
✅ **Features**: Send/accept/decline friend requests
✅ **Error Handling**: Network failures, edge cases

### Success Criteria (Sprint 1)

- [ ] User can search for players by username
- [ ] User can send friend request
- [ ] User can view pending requests
- [ ] User can accept/decline requests
- [ ] User can view friends list with status
- [ ] All actions reflect immediately in UI
- [ ] No unhandled exceptions
- [ ] Works on low-end device

### Estimated Effort

- Backend Integration: 3 days
- UI Implementation: 4 days
- Testing & Polish: 2 days
- **Total: 9 days (2 weeks with buffer)**

---

## Sprint 2: Parties System — Core (1.5 weeks)

### Goals

- [x] PartyApiClient fully implemented
- [x] Party creation and joining
- [x] Party member invitations
- [x] Party list UI
- [x] Party detail view

### Scope

#### Week 1: Party Backend + Core UI

**Day 1-2: PartyApiClient Implementation**

**File**: Expand `lib/core/services/social_api_client.dart` with PartyApiClient

```dart
class PartyApiClient {
  final ApiService _apiService;
  static final _log = Logger('PartyApiClient');

  /// Create a new party
  Future<PartyResponse> createParty({
    required String name,
    String? description,
    int maxMembers = 4,
    String? gameMode,
  }) async {
    _log.info('Creating party: $name');
    final body = {
      'name': name,
      'description': description,
      'maxMembers': maxMembers,
      'gameMode': gameMode,
    };
    final json = await _apiService.post('/party', body: body);
    return PartyResponse.fromJson(json);
  }

  /// Get party details
  Future<PartyDetailResponse> getPartyDetails(String partyId) async {
    _log.info('Fetching party details: $partyId');
    final json = await _apiService.get('/party/$partyId');
    return PartyDetailResponse.fromJson(json);
  }

  /// List parties for current player
  Future<PartiesListResponse> listParties({
    int page = 1,
    int pageSize = 20,
    String? status, // 'active', 'completed', 'disbanded'
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

  /// Invite player to party
  Future<void> inviteToParty({
    required String partyId,
    required String targetPlayerId,
  }) async {
    _log.info('Inviting $targetPlayerId to party $partyId');
    final body = {'targetPlayerId': targetPlayerId};
    await _apiService.post('/party/$partyId/invite', body: body);
  }

  /// Accept party invite
  Future<void> acceptPartyInvite(String inviteId) async {
    _log.info('Accepting party invite: $inviteId');
    await _apiService.post('/party/invites/$inviteId/accept', body: {});
  }

  /// Decline party invite
  Future<void> declinePartyInvite(String inviteId) async {
    _log.info('Declining party invite: $inviteId');
    await _apiService.post('/party/invites/$inviteId/decline', body: {});
  }

  /// Leave party
  Future<void> leaveParty(String partyId) async {
    _log.info('Leaving party: $partyId');
    await _apiService.post('/party/$partyId/leave', body: {});
  }

  /// Disband party (owner only)
  Future<void> disbandParty(String partyId) async {
    _log.info('Disbanding party: $partyId');
    await _apiService.post('/party/$partyId/disband', body: {});
  }
}
```

**Create Party DTOs**

**File**: `lib/core/services/social/parties_models.dart` (NEW)

```dart
class PartyResponse {
  final String partyId;
  final String name;
  final String description;
  final String ownerId;
  final int memberCount;
  final int maxMembers;
  final String status;
  final DateTime createdAtUtc;

  PartyResponse({...});
  factory PartyResponse.fromJson(Map<String, dynamic> json) {...}
}

class PartyDetailResponse {
  final String partyId;
  final String name;
  final String description;
  final String ownerId;
  final String ownerUsername;
  final List<PartyMember> members;
  final List<PartyInvite> pendingInvites;
  final int maxMembers;
  final String status;
  final String? gameMode;
  final DateTime createdAtUtc;

  PartyDetailResponse({...});
  factory PartyDetailResponse.fromJson(Map<String, dynamic> json) {...}
}

class PartyMember {
  final String playerId;
  final String username;
  final String? avatarUrl;
  final String role; // 'owner', 'member'
  final DateTime joinedAtUtc;
  final bool isReady;

  PartyMember({...});
  factory PartyMember.fromJson(Map<String, dynamic> json) {...}
}

class PartyInvite {
  final String inviteId;
  final String toPlayerId;
  final String toUsername;
  final DateTime sentAtUtc;

  PartyInvite({...});
  factory PartyInvite.fromJson(Map<String, dynamic> json) {...}
}

class PartiesListResponse {
  final List<PartyResponse> parties;
  final int totalCount;
  final int page;
  final int pageSize;

  PartiesListResponse({...});
  factory PartiesListResponse.fromJson(Map<String, dynamic> json) {...}
}
```

**Day 3: State Management**

**File**: `lib/features/social/providers/parties_providers.dart` (NEW)

```dart
final partiesApiClientProvider = Provider<PartyApiClient>((ref) {
  return PartyApiClient(ref.read(apiServiceProvider));
});

class PartiesService {
  final PartyApiClient _apiClient;

  PartiesService(this._apiClient);

  Future<PartyResponse> createParty({...}) async {
    return await _apiClient.createParty(...);
  }

  Future<PartyDetailResponse> getPartyDetails(String partyId) async {
    return await _apiClient.getPartyDetails(partyId);
  }

  Future<List<PartyResponse>> getActiveParties() async {
    final response = await _apiClient.listParties(status: 'active');
    return response.parties;
  }

  // ... other methods
}

final partiesServiceProvider = Provider<PartiesService>((ref) {
  return PartiesService(ref.read(partiesApiClientProvider));
});

// List active parties
final activePartiesProvider = FutureProvider<List<PartyResponse>>((ref) async {
  final service = ref.read(partiesServiceProvider);
  return await service.getActiveParties();
});

// Get party details (family for dynamic partyId)
final partyDetailsProvider = FutureProvider.family<PartyDetailResponse, String>((ref, partyId) async {
  final service = ref.read(partiesServiceProvider);
  return await service.getPartyDetails(partyId);
});
```

**Day 4-5: Party List Screen**

**File**: `lib/features/social/screens/parties_screen.dart` (NEW)

```dart
class PartiesScreen extends ConsumerWidget {
  const PartiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(activePartiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreatePartyDialog(context),
          ),
        ],
      ),
      body: partiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (parties) => _buildPartiesList(context, parties),
      ),
    );
  }

  Widget _buildPartiesList(BuildContext context, List<PartyResponse> parties) {
    if (parties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No parties yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Create or join a party to play with friends!'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: parties.length,
      itemBuilder: (context, index) => _PartyCard(
        party: parties[index],
        onTap: () => _navigateToPartyDetail(context, parties[index].partyId),
      ),
    );
  }

  void _navigateToPartyDetail(BuildContext context, String partyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartyDetailScreen(partyId: partyId),
      ),
    );
  }

  void _showCreatePartyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreatePartyDialog(),
    );
  }
}

// Party Card
class _PartyCard extends StatelessWidget {
  final PartyResponse party;
  final VoidCallback onTap;

  const _PartyCard({required this.party, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.groups, color: Theme.of(context).colorScheme.primary),
        title: Text(party.name),
        subtitle: Text('${party.memberCount}/${party.maxMembers} members'),
        trailing: const Icon(Icons.arrow_forward),
      ),
    );
  }
}

// Party Detail Screen
class PartyDetailScreen extends ConsumerWidget {
  final String partyId;

  const PartyDetailScreen({required this.partyId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyAsync = ref.watch(partyDetailsProvider(partyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Party Details')),
      body: partyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (party) => _buildPartyDetail(context, ref, party),
      ),
    );
  }

  Widget _buildPartyDetail(BuildContext context, WidgetRef ref, PartyDetailResponse party) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(party.name, style: Theme.of(context).textTheme.headlineMedium),
                Text('${party.members.length}/${party.maxMembers} members'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Members Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Members', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...party.members.map((member) => _MemberTile(member: member)),
              ],
            ),
          ),

          // Pending Invites Section
          if (party.pendingInvites.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pending Invites', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...party.pendingInvites.map((invite) => _InviteTile(invite: invite)),
                ],
              ),
            ),
          ],

          // Action Buttons
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: () => _inviteFriend(context, ref),
                  child: const Text('Invite Friend'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _leaveParty(context, ref),
                  child: const Text('Leave'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _inviteFriend(BuildContext context, WidgetRef ref) {
    // Show friend selection dialog
    // Call partyApiClient.inviteToParty()
  }

  void _leaveParty(BuildContext context, WidgetRef ref) {
    // Call partyApiClient.leaveParty()
    // Pop back to parties list
  }
}

class _MemberTile extends StatelessWidget {
  final PartyMember member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(member.avatarUrl ?? '')),
      title: Text(member.username),
      subtitle: Text(member.role),
      trailing: member.isReady ? Icon(Icons.check_circle, color: Colors.green) : null,
    );
  }
}

class _InviteTile extends StatelessWidget {
  final PartyInvite invite;

  const _InviteTile({required this.invite});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(invite.toUsername),
      subtitle: const Text('Pending...'),
    );
  }
}

class _CreatePartyDialog extends ConsumerWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Create Party'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Party Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _createParty(context, ref),
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createParty(BuildContext context, WidgetRef ref) async {
    final service = ref.read(partiesServiceProvider);
    await service.createParty(
      name: _nameController.text,
      description: _descController.text,
    );
    ref.refresh(activePartiesProvider);
    Navigator.pop(context);
  }
}
```

#### Week 2: Integration + Polish

**Day 1-2: Link Friends with Parties**

- Show friend invite action in party detail
- Filter party members list
- Add "invite friends from party" quick action

**Day 3-4: Party Matchmaking (Optional for Sprint 2)**

- Queue system to find matches for parties
- Display ready/not-ready status for members
- Start match as group

**Day 5: Polish & Testing**

- Error states and retry
- Loading skeletons
- Edge case handling

---

### Deliverables (Sprint 2)

✅ **Code**: 600 LOC (Models + Services + UI)
✅ **Tests**: API client unit tests
✅ **UI**: Parties list + party detail + create party
✅ **Features**: Create/join/invite/leave parties
✅ **Integration**: Link to friends system

### Success Criteria (Sprint 2)

- [ ] User can create party with name/description
- [ ] User can view party members
- [ ] User can invite friends to party
- [ ] User can accept/decline party invites
- [ ] User can leave party
- [ ] Owner can disband party
- [ ] Party list shows member count and capacity
- [ ] No unhandled exceptions

### Estimated Effort

- Party backend: 3 days
- UI Implementation: 4 days
- Integration & Polish: 2 days
- **Total: 9 days (1.5 weeks)**

---

## Sprint 3: Integration & Polish (1 week)

### Goals

- [x] Cross-system integration (Friends + Parties)
- [x] Performance optimization
- [x] Error handling polish
- [x] End-to-end testing
- [x] Documentation

### Scope

**Day 1-2: Cross-System Features**

1. **Quick Party Creation**
   - Start party with friend from friend's detail screen
   - Accept friend + create party in one action

2. **Party Invitations**
   - Show party invites in friends screen
   - Accept/decline from notification

3. **Mutual Friends**
   - Display mutual friends with party members
   - Suggest friends to invite based on activity

**Day 3-4: Performance & UX Polish**

1. **Pagination**
   - Infinite scroll for friends/parties lists
   - Load more functionality

2. **Search & Filter**
   - Filter friends by online status
   - Filter parties by game mode
   - Search within lists

3. **Loading States**
   - Skeleton loaders for lists
   - Better loading indicators

4. **Animations**
   - Smooth transitions between screens
   - Card transitions
   - Accept/decline animations

**Day 5: Testing & Deployment**

1. **Integration Tests**
   - Create friend + create party + invite flow
   - Accept invite + join party flow

2. **Performance Testing**
   - Profile with 100+ friends
   - Profile with 50+ parties

3. **QA Sign-off**
   - Create test scenarios
   - Verify all user flows
   - Check edge cases

---

### Deliverables (Sprint 3)

✅ **Code**: 400 LOC (Integration + polish)
✅ **Tests**: Integration test suite
✅ **Features**: Cross-system flows
✅ **Performance**: Optimized lists and transitions
✅ **Documentation**: User guide + troubleshooting

### Estimated Effort

- Integration: 2 days
- Performance & UX: 2 days
- Testing & Deployment: 1 day
- **Total: 5 days (1 week)**

---

## Sprint 4+: Real-Time Enhancements (Optional)

### WebSocket Enhancements (2-3 weeks)

1. **Real-Time Status Updates**
   - Friend online/offline notifications
   - Party member ready status
   - Live member list updates

2. **Party Chat**
   - Send messages in party channel
   - Persist last N messages

3. **Instant Notifications**
   - Friend request notifications
   - Party invite notifications
   - Member joined/left notifications

### Implementation Notes

**File**: `lib/features/social/services/social_websocket_service.dart`

```dart
class SocialWebSocketService {
  // Listen for friend online status changes
  Stream<FriendStatusChanged> onFriendStatusChanged() {}
  
  // Listen for party member updates
  Stream<PartyMemberJoined> onPartyMemberJoined() {}
  Stream<PartyMemberLeft> onPartyMemberLeft() {}
  
  // Send messages
  Future<void> sendPartyMessage(String partyId, String message) {}
}
```

---

## Architecture Overview

### Layered Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   UI Layer (Flutter)                    │
│  FriendsListScreen | PartyDetailScreen | Create Dialogs │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              Providers Layer (Riverpod)                 │
│  friendsListProvider | activePartiesProvider            │
│  partyDetailsProvider(id) | playerSearchProvider(query)  │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│            Services Layer (Business Logic)              │
│  FriendsService | PartiesService                        │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│             API Client Layer (REST)                     │
│  FriendsApiClient | PartyApiClient                      │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│           Backend API (RESTful endpoints)               │
│  POST /friends/request | GET /friends                   │
│  POST /party | GET /party/{id} | POST /party/{id}/invite│
└─────────────────────────────────────────────────────────┘
```

### Data Flow

**Friend Request Flow**:
```
FriendSearchDialog
  → _sendRequest()
    → FriendsService.sendRequest()
      → FriendsApiClient.sendFriendRequest()
        → POST /friends/request
          → 200 OK
            → refresh playerSearchProvider
            → show "Request Sent"
```

**Party Invite Flow**:
```
PartyDetailScreen
  → _inviteFriend()
    → PartyInviteDialog
      → PartiesService.inviteToParty()
        → PartyApiClient.inviteToParty()
          → POST /party/{id}/invite
            → 200 OK
              → refresh partyDetailsProvider
              → show "Invite Sent"
```

---

## Testing Strategy

### Unit Tests (Sprint 1-2)
- API client methods
- Service methods
- DTO parsing

### Integration Tests (Sprint 3)
- Friend request → send → accept → view
- Party creation → invite → join → play
- Error scenarios

### E2E Tests (Sprint 4+)
- Full user flows
- Network failures
- WebSocket connectivity

### Performance Tests
- List rendering with 100+ items
- Search responsiveness
- Memory usage

---

## Risk Assessment & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|-----------|
| **API Contract Mismatch** | High | Medium | Backend provides clear API docs; early integration testing |
| **Pagination Performance** | Medium | Medium | Implement infinite scroll; lazy load images |
| **Real-Time Sync Issues** | Medium | Medium | Queue failed actions; retry with exponential backoff |
| **User Privacy Concerns** | High | Low | Block feature; report user feature; privacy docs |
| **Scope Creep** | Medium | High | Strictly limit to defined scope; defer nice-to-haves |

---

## Success Metrics

### Feature Adoption
- [ ] 30% of users add a friend within first month
- [ ] 20% of users join/create a party within first month

### Performance
- [ ] Friends list loads in <500ms
- [ ] Party detail loads in <800ms
- [ ] Search returns results in <300ms

### Reliability
- [ ] <0.1% error rate on friend operations
- [ ] <0.1% error rate on party operations
- [ ] No crashes related to social features

### Engagement
- [ ] Users with friends play 2x more matches
- [ ] Users in parties play 3x more matches
- [ ] Retention improves by 15%

---

## Dependencies & Prerequisites

### Must Complete Before Sprint 1
- ✅ Auth system
- ✅ User profiles
- ✅ Match REST API
- ✅ OpenAPI spec (already done)

### Optional Enhancements (Sprint 4+)
- Group chat/messaging
- Real-time WebSocket
- Achievements tied to social actions
- Clan/guild system

---

## Resource Allocation

### Sprint 1 (Friends System)
- 1 Senior Developer (Architecture + complex logic)
- 1 Mid-level Developer (UI implementation)
- 1 QA Engineer (0.5 weeks)

### Sprint 2 (Parties System)
- 1 Mid-level Developer (Primary)
- 1 Junior Developer (UI components)
- 1 QA Engineer (0.5 weeks)

### Sprint 3 (Integration)
- 1 Senior Developer (Integration + optimization)
- 1 QA Engineer (Testing + edge cases)

**Total Team Weeks**: ~6 developer weeks + ~1.5 QA weeks

---

## Documentation Plan

### For Developers
- API contracts (via OpenAPI update)
- Architecture decision records (ADRs)
- Setup guide for local development
- Common patterns (provider setup, error handling)

### For QA
- Test plan with 40+ test cases
- User flows documentation
- Known limitations and edge cases

### For Product/PMs
- Feature spec with user stories
- Metrics dashboard (adoption, performance)
- User feedback loops

### For End Users
- In-app help text
- Tutorial for adding friends
- Tutorial for creating parties

---

## Rollout Plan

### Phase 1: Closed Beta (1 week)
- Limited to 5% of users
- Monitor error rates and performance
- Collect feedback

### Phase 2: Soft Launch (1 week)
- Roll out to 25% of users
- Monitor adoption metrics
- Fix any critical issues

### Phase 3: Full Launch
- 100% of users get access
- Monitor adoption and engagement
- Plan Sprint 4+ enhancements

---

## Post-Launch Roadmap

### 2-3 Months After Launch
- **Analytics**: Review adoption, engagement, retention metrics
- **User Feedback**: Collect and prioritize requests
- **Performance**: Optimize slow queries, reduce API calls

### 3-6 Months After Launch
- **Sprint 4**: Real-time WebSocket enhancements
- **Clans/Guilds**: Larger group organization (optional)
- **Social Leaderboards**: Competitive features

### 6+ Months After Launch
- **Advanced Features**: Group tournaments, team seasons
- **Integration**: Facebook/Discord friend sync (optional)
- **Monetization**: Premium social features (optional)

---

## Summary

| Phase | Duration | Focus | Output |
|-------|----------|-------|--------|
| **Sprint 1** | 2 weeks | Friends system | 800 LOC + full UI |
| **Sprint 2** | 1.5 weeks | Parties system | 600 LOC + full UI |
| **Sprint 3** | 1 week | Integration & polish | 400 LOC + testing |
| **Sprint 4+** | Optional | Real-time enhancements | WebSocket + chat |

**Total Critical Path**: 4.5 weeks (3-4 sprints)  
**Total with Enhancements**: 8-10 weeks (5-6 sprints)

---

## Approval & Sign-Off

**Recommended by**: Claude Code (API Migration Lead)  
**Date**: 2026-07-05  
**Status**: Ready for Product Planning

**Next Steps**:
1. Product team reviews this plan
2. Prioritize against other roadmap items
3. Schedule kick-off meeting for Sprint 1
4. Assign team members
5. Begin development

---

**Document Version**: 1.0  
**Last Updated**: 2026-07-05
