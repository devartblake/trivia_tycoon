import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/social/friends_models.dart';
import '../providers/social_providers.dart';
import '../widgets/friend_card.dart';
import '../widgets/friend_request_card.dart';
import '../widgets/add_friend_dialog.dart';

/// Main Friends List Screen
///
/// Displays:
/// - Friends list with online status
/// - Pending friend requests
/// - Ability to search and add friends
class FriendsListScreen extends ConsumerWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              onPressed: () => _showAddFriendDialog(context, ref),
              tooltip: 'Add friend',
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(
                icon: Icon(Icons.people_rounded),
                text: 'Friends',
              ),
              Tab(
                icon: Icon(Icons.mail_rounded),
                text: 'Requests',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFriendsTab(context, ref),
            _buildRequestsTab(context, ref),
          ],
        ),
      ),
    );
  }

  /// Friends list tab
  Widget _buildFriendsTab(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);

    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildErrorState(
        context,
        error: err.toString(),
        onRetry: () => ref.refresh(friendsListProvider),
      ),
      data: (friends) => friends.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () async => ref.refresh(friendsListProvider),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return FriendCard(
                    friend: friend,
                    onRemove: () =>
                        _removeFriend(context, ref, friend.friendId),
                    onChallenge: () => _challengeFriend(context, friend),
                  );
                },
              ),
            ),
    );
  }

  /// Friend requests tab
  Widget _buildRequestsTab(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingFriendRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildErrorState(
        context,
        error: err.toString(),
        onRetry: () => ref.refresh(pendingFriendRequestsProvider),
      ),
      data: (requests) => requests.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withAlpha(128),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pending requests',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.refresh(pendingFriendRequestsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return FriendRequestCard(
                    request: request,
                    onAccept: () =>
                        _acceptRequest(context, ref, request.requestId),
                    onDecline: () =>
                        _declineRequest(context, ref, request.requestId),
                  );
                },
              ),
            ),
    );
  }

  /// Empty state UI
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.secondary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'No friends yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends to play together!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error state UI
  Widget _buildErrorState(
    BuildContext context, {
    required String error,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.withAlpha(180),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load friends',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show add friend dialog
  void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddFriendDialog(ref: ref),
    );
  }

  /// Accept friend request with confirmation
  void _acceptRequest(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    try {
      await acceptFriendRequest(ref, requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request accepted! 🎉'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Decline friend request
  void _declineRequest(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    try {
      await declineFriendRequest(ref, requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request declined'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Remove friend with confirmation
  void _removeFriend(
    BuildContext context,
    WidgetRef ref,
    String friendId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend?'),
        content: const Text('Are you sure you want to remove this friend?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await removeFriend(ref, friendId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Friend removed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  /// Challenge friend (navigate to match)
  void _challengeFriend(BuildContext context, Friend friend) {
    // TODO: Implement navigation to match creation with this friend as opponent
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Challenge ${friend.username} (coming soon)'),
      ),
    );
  }
}
