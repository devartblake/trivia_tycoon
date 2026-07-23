import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/core/design_system/synaptix_scaffold.dart';
import 'package:synaptix/core/design_system/glass_app_bar.dart';
import 'package:synaptix/core/design_system/glow_text.dart';
import 'package:synaptix/core/design_system/segmented_selection_hub.dart';
import 'package:synaptix/core/design_system/holographic_dialog.dart';
import 'package:synaptix/core/design_system/demographic_asset_wrapper.dart';
import 'package:synaptix/core/design_system/neural_bloom_indicator.dart';
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
class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SynaptixScaffold(
      appBar: GlassAppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
        ),
        title: const GlowText('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            onPressed: () => _showAddFriendDialog(context, ref),
            tooltip: 'Add friend',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedSelectionHub(
                items: const ['Friends', 'Requests'],
                selectedIndex: _selectedIndex,
                onItemSelected: (index) =>
                    setState(() => _selectedIndex = index),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildFriendsTab(context, ref),
                  _buildRequestsTab(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Friends list tab
  Widget _buildFriendsTab(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);

    return friendsAsync.when(
      loading: () => const Center(child: NeuralBloomIndicator()),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      loading: () => const Center(child: NeuralBloomIndicator()),
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
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 64,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 16),
                    GlowText(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            const DemographicAssetWrapper(
              kidsAsset: 'assets/images/avatars/kids_search.png',
              teenAsset: 'assets/images/avatars/teen_lonely.png',
              adultAsset: 'assets/images/avatars/adult_networking.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 16),
            const GlowText(
              'No friends yet',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add friends to play together!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
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
    HolographicDialog.show(
      context: context,
      child: AddFriendDialog(ref: ref),
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
    HolographicDialog.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GlowText('Remove Friend?'),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to remove this friend?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white60)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await removeFriend(ref, friendId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Friend removed'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Remove',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
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
