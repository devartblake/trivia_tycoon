import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/social/friends_models.dart';
import '../providers/social_providers.dart';

/// Dialog for searching and adding friends
///
/// Features:
/// - Real-time player search by username
/// - Shows friend status (already friend, pending request, etc)/// - Send friend requests directly
class AddFriendDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const AddFriendDialog({
    super.key,
    required this.ref,
  });

  @override
  ConsumerState<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends ConsumerState<AddFriendDialog> {
  late TextEditingController _searchController;

  /// The query actually sent to the search API. Updated ~350ms after the
  /// user stops typing so each keystroke doesn't fire a network request.
  String _debouncedQuery = '';
  Timer? _debounceTimer;

  static const _debounceDelay = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (!mounted) return;
      setState(() => _debouncedQuery = value.trim());
    });
    // Rebuild immediately for the clear-button/empty-state UI only.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchQuery = _debouncedQuery;
    final searchAsync = ref.watch(playerSearchProvider(searchQuery));

    return AlertDialog(
      title: const Text('Add Friend'),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by username...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _debounceTimer?.cancel();
                            setState(() => _debouncedQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _onQueryChanged,
              ),
            ),
            // Search results
            Flexible(
              child: searchQuery.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 48,
                              color: theme.colorScheme.secondary.withAlpha(128),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start typing to search',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : searchAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.red.withAlpha(180),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Search failed',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                err.toString(),
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (results) => results.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_off_rounded,
                                      size: 48,
                                      color:
                                          theme.colorScheme.secondary.withAlpha(128),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No players found',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final player = results[index];
                                return _PlayerSearchResult(
                                  player: player,
                                  onAction: () =>
                                      _handlePlayerAction(player),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Handle player action (send request, etc)
  Future<void> _handlePlayerAction(PlayerSearchResult player) async {
    if (player.isFriend) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Already friends with ${player.username}'),
        ),
      );
      return;
    }

    if (player.hasOutgoingRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request already sent to ${player.username}'),
        ),
      );
      return;
    }

    if (player.hasIncomingRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.username} has sent you a friend request'),
        ),
      );
      return;
    }

    // Send friend request
    try {
      await sendFriendRequest(widget.ref, player.playerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${player.username}! 🎉'),
            duration: const Duration(seconds: 2),
          ),
        );
        // Trigger rebuild so search results refresh
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Individual player search result tile
class _PlayerSearchResult extends StatelessWidget {
  final PlayerSearchResult player;
  final VoidCallback? onAction;

  const _PlayerSearchResult({
    required this.player,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: player.avatarUrl != null
              ? NetworkImage(player.avatarUrl!)
              : null,
          child: player.avatarUrl == null
              ? Icon(
                  Icons.person_rounded,
                  color: theme.colorScheme.primary,
                )
              : null,
        ),
        title: Text(player.username),
        subtitle: player.level != null ? Text('Lvl ${player.level}') : null,
        trailing: _buildActionButton(context, theme),
      ),
    );
  }

  /// Build action button based on player status
  Widget _buildActionButton(BuildContext context, ThemeData theme) {
    if (player.isFriend) {
      return Chip(
        label: const Text('Friend'),
        backgroundColor: theme.colorScheme.primaryContainer,
      );
    } else if (player.hasOutgoingRequest) {
      return Chip(
        label: const Text('Pending'),
        backgroundColor: Colors.orange.withAlpha(51),
      );
    } else if (player.hasIncomingRequest) {
      return Chip(
        label: const Text('Incoming'),
        backgroundColor: Colors.green.withAlpha(51),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.person_add_rounded),
        onPressed: onAction,
        tooltip: 'Send friend request',
      );
    }
  }
}
