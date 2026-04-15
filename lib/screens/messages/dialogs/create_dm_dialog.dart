import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/social/friend_list_item_dto.dart';
import '../../../game/providers/friends_providers.dart';
import '../../../game/providers/message_providers.dart';
import '../../profile/dialogs/add_friend_dialog.dart';
import '../message_detail_screen.dart';

class CreateDMDialog extends ConsumerStatefulWidget {
  const CreateDMDialog({super.key});

  @override
  ConsumerState<CreateDMDialog> createState() => _CreateDMDialogState();
}

class _CreateDMDialogState extends ConsumerState<CreateDMDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedUserIds = [];

  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36393F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Message',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_selectedUserIds.isNotEmpty)
            TextButton(
              onPressed: _isCreating ? null : () => _createConversation(),
              child: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _selectedUserIds.length > 1 ? 'Create Group' : 'Create',
                      style: const TextStyle(
                        color: Color(0xFF5865F2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: friendsAsync.when(
        data: (friendsPage) {
          final users = _filteredFriends(friendsPage.items);
          final userById = {
            for (final user in friendsPage.items) user.friendPlayerId: user,
          };

          return Column(
            children: [
              _buildSearchField(),
              if (_selectedUserIds.isNotEmpty) _buildSelectedUsers(userById),
              _buildQuickActions(),
              _buildUsersList(users),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white70, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Could not load friends right now',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB9BBBE), fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(friendsListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Text(
            'To: ',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search your friends',
                hintStyle: TextStyle(color: Color(0xFF72767D)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedUsers(Map<String, FriendListItemDto> userById) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _selectedUserIds.map((userId) {
          final user = userById[userId];
          if (user == null) return const SizedBox.shrink();

          return Chip(
            backgroundColor: const Color(0xFF5865F2),
            deleteIconColor: Colors.white,
            avatar: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: _avatarProvider(user.avatarUrl),
              child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                  ? Text(
                      _initial(user.displayName),
                      style: const TextStyle(
                        color: Color(0xFF5865F2),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            label: Text(
              user.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            onDeleted: () {
              setState(() {
                _selectedUserIds.remove(userId);
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF5865F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.group_add, color: Colors.white, size: 20),
            ),
            title: const Text(
              'New Group',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              'Select multiple friends',
              style: TextStyle(color: Color(0xFF72767D), fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Select multiple friends to create a group'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF5865F2),
                ),
              );
            },
          ),
          const Divider(color: Color(0xFF36393F), height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person_add, color: Colors.white, size: 20),
            ),
            title: const Text(
              'Add a Friend',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              'Search by username',
              style: TextStyle(color: Color(0xFF72767D), fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: _showAddFriendDialog,
          ),
        ],
      ),
    );
  }

  void _showAddFriendDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddFriendDialog(),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildUsersList(List<FriendListItemDto> users) {
    if (users.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchController.text.isEmpty
                    ? Icons.people_outline
                    : Icons.search_off,
                color: const Color(0xFF72767D),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'No friends yet'
                    : 'No friends match your search',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isEmpty
                    ? 'Add friends to start messaging'
                    : 'Try a different name or username',
                style: const TextStyle(color: Color(0xFF72767D), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final groupedUsers = <String, List<FriendListItemDto>>{};
    for (final user in users) {
      final firstLetter = _initial(user.displayName).toUpperCase();
      groupedUsers.putIfAbsent(firstLetter, () => []).add(user);
    }

    final sortedKeys = groupedUsers.keys.toList()..sort();

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final letter = sortedKeys[index];
          final letterUsers = groupedUsers[letter]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...letterUsers.map(_buildUserTile),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserTile(FriendListItemDto user) {
    final isSelected = _selectedUserIds.contains(user.friendPlayerId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: const Color(0xFF5865F2), width: 2)
            : null,
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF5865F2),
              backgroundImage: _avatarProvider(user.avatarUrl),
              child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                  ? Text(
                      _initial(user.displayName).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (user.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3BA55C),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF40444B),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user.isOnline) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3BA55C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '@${user.username}',
          style: const TextStyle(color: Color(0xFF72767D), fontSize: 12),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF5865F2))
            : const Icon(Icons.circle_outlined, color: Color(0xFF72767D)),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedUserIds.remove(user.friendPlayerId);
            } else {
              _selectedUserIds.add(user.friendPlayerId);
            }
          });
        },
      ),
    );
  }

  Future<void> _createConversation() async {
    if (_selectedUserIds.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final friendsPage = await ref.read(friendsListProvider.future);
      final currentUserId = ref.read(currentUserIdProvider);
      final userById = {
        for (final user in friendsPage.items) user.friendPlayerId: user,
      };

      if (_selectedUserIds.length == 1) {
        final otherUserId = _selectedUserIds.first;
        final otherUser = userById[otherUserId];

        if (otherUser == null) {
          throw Exception('Friend not found');
        }

        final conversation = findOrCreateDirectConversation(
          ref,
          currentUserId,
          otherUserId,
        );

        if (conversation != null && mounted) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessageDetailScreen(
                conversationId: conversation.id,
                contactName: otherUser.displayName,
                contactAvatar: otherUser.avatarUrl,
                isOnline: otherUser.isOnline,
                currentActivity: null,
              ),
            ),
          );
        }
      } else {
        final selectedUsers = _selectedUserIds
            .map((id) => userById[id])
            .whereType<FriendListItemDto>()
            .toList(growable: false);
        final names = selectedUsers.map((u) => u.displayName).join(', ');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Group chat with $names - Coming soon!'),
              backgroundColor: const Color(0xFF5865F2),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  List<FriendListItemDto> _filteredFriends(List<FriendListItemDto> users) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return users;
    }

    return users.where((user) {
      final displayName = user.displayName.toLowerCase();
      final username = user.username.toLowerCase();
      return displayName.contains(query) || username.contains(query);
    }).toList(growable: false);
  }

  ImageProvider<Object>? _avatarProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return NetworkImage(avatarUrl);
    }
    return AssetImage(avatarUrl);
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed[0];
  }
}
