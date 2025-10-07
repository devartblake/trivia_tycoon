import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/social/friend_discovery_service.dart';
import '../../../game/providers/message_providers.dart';
import '../../profile/dialogs/add_friend_dialog.dart';
import '../message_detail_screen.dart';

// Provider for FriendDiscoveryService
final friendDiscoveryServiceProvider = Provider<FriendDiscoveryService>((ref) {
  return FriendDiscoveryService();
});

// Provider for current user ID (you can replace this with your auth provider)
final currentUserIdProvider = Provider<String>((ref) {
  // TODO: Replace with actual auth provider
  return 'current_user_id';
});

class CreateDMDialog extends ConsumerStatefulWidget {
  const CreateDMDialog({super.key});

  @override
  ConsumerState<CreateDMDialog> createState() => _CreateDMDialogState();
}

class _CreateDMDialogState extends ConsumerState<CreateDMDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedUserIds = [];

  List<UserProfile> _filteredUsers = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text;
      final friendService = ref.read(friendDiscoveryServiceProvider);
      final currentUserId = ref.read(currentUserIdProvider);

      if (query.trim().isEmpty) {
        // Show all friends when search is empty
        _filteredUsers = friendService.getFriends(currentUserId);
      } else {
        // Search users
        _filteredUsers = friendService.searchUsers(
          query,
          excludeUserId: currentUserId,
        );

        // Filter to only show friends and friend suggestions
        final friendIds = friendService.getFriendIds(currentUserId).toSet();
        _filteredUsers = _filteredUsers.where((user) {
          return friendIds.contains(user.id) ||
              friendService.getFriendshipStatus(currentUserId, user.id) != FriendshipStatus.blocked;
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendService = ref.watch(friendDiscoveryServiceProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    // Load friends on first build
    if (_filteredUsers.isEmpty && _searchController.text.isEmpty) {
      _filteredUsers = friendService.getFriends(currentUserId);
    }

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
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (_selectedUserIds.isNotEmpty)
            TextButton(
              onPressed: _isCreating ? null : _createConversation,
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
      body: Column(
        children: [
          _buildSearchField(),
          if (_selectedUserIds.isNotEmpty) _buildSelectedUsers(),
          _buildQuickActions(),
          _buildUsersList(),
        ],
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

  Widget _buildSelectedUsers() {
    final friendService = ref.read(friendDiscoveryServiceProvider);

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
          final user = friendService.getUserProfile(userId);
          if (user == null) return const SizedBox.shrink();

          return Chip(
            backgroundColor: const Color(0xFF5865F2),
            deleteIconColor: Colors.white,
            avatar: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF5865F2),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
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
            onTap: () => _showAddFriendDialog(),
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

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
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
                    : 'No users found',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isEmpty
                    ? 'Add friends to start messaging'
                    : 'Try a different search',
                style: const TextStyle(color: Color(0xFF72767D), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Group users by first letter
    final groupedUsers = <String, List<UserProfile>>{};
    for (final user in _filteredUsers) {
      final firstLetter = user.displayName[0].toUpperCase();
      groupedUsers.putIfAbsent(firstLetter, () => []).add(user);
    }

    // Sort groups alphabetically
    final sortedKeys = groupedUsers.keys.toList()..sort();

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final letter = sortedKeys[index];
          final users = groupedUsers[letter]!;

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
              ...users.map((user) => _buildUserTile(user)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserTile(UserProfile user) {
    final isSelected = _selectedUserIds.contains(user.id);
    final currentUserId = ref.read(currentUserIdProvider);
    final friendService = ref.read(friendDiscoveryServiceProvider);
    final mutualCount = friendService.getMutualFriendCount(currentUserId, user.id);

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
              backgroundImage: user.avatar != null ? AssetImage(user.avatar!) : null,
              child: user.avatar == null
                  ? Text(
                user.displayName[0].toUpperCase(),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.username != null)
              Text(
                '@${user.username}',
                style: const TextStyle(color: Color(0xFF72767D), fontSize: 12),
              ),
            if (mutualCount > 0)
              Text(
                '$mutualCount mutual ${mutualCount == 1 ? "friend" : "friends"}',
                style: const TextStyle(color: Color(0xFF72767D), fontSize: 11),
              ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF5865F2))
            : const Icon(Icons.circle_outlined, color: Color(0xFF72767D)),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedUserIds.remove(user.id);
            } else {
              _selectedUserIds.add(user.id);
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
      final currentUserId = ref.read(currentUserIdProvider);
      final friendService = ref.read(friendDiscoveryServiceProvider);

      if (_selectedUserIds.length == 1) {
        // Create direct message
        final otherUserId = _selectedUserIds.first;
        final otherUser = friendService.getUserProfile(otherUserId);

        if (otherUser == null) {
          throw Exception('User not found');
        }

        // Find or create direct conversation
        final conversation = findOrCreateDirectConversation(
          ref,
          currentUserId,
          otherUserId,
        );

        if (conversation != null && mounted) {
          Navigator.pop(context); // Close dialog
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessageDetailScreen(
                conversationId: conversation.id,
                contactName: otherUser.displayName,
                contactAvatar: otherUser.avatar,
                isOnline: otherUser.isOnline,
                currentActivity: null,
              ),
            ),
          );
        }
      } else {
        // Create group conversation
        final selectedUsers = _selectedUserIds
            .map((id) => friendService.getUserProfile(id))
            .whereType<UserProfile>()
            .toList();

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
}
