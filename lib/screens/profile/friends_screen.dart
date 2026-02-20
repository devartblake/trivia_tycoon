import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dialogs/add_friend_dialog.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _selectedTab = 'Friends';

  final List<String> _tabs = ['Friends', 'Requests', 'Suggested'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Online Friends Section
            SliverToBoxAdapter(
              child: _buildOnlineFriendsSection(),
            ),

            // Tab Bar
            SliverToBoxAdapter(
              child: _buildTabBar(),
            ),

            // Friends List
            SliverToBoxAdapter(
              child: _buildFriendsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 18,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Friends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '24 friends online',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              ),
            ),
            child: const Icon(
              Icons.search,
              color: Color(0xFF6366F1),
              size: 20,
            ),
          ),
          onPressed: () => _showSearchDialog(),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildOnlineFriendsSection() {
    final onlineFriends = [
      {'name': 'You', 'avatar': 'assets/images/avatars/avatar-1.png', 'isOnline': true},
      {'name': 'David', 'avatar': 'assets/images/avatars/avatar-2.png', 'isOnline': true},
      {'name': 'Sarah', 'avatar': 'assets/images/avatars/avatar-3.png', 'isOnline': true},
      {'name': 'Mike', 'avatar': 'assets/images/avatars/avatar-4.png', 'isOnline': true},
      {'name': 'Emma', 'avatar': 'assets/images/avatars/avatar-5.png', 'isOnline': true},
    ];

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Online Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${onlineFriends.length} online',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: onlineFriends.length,
                      itemBuilder: (context, index) {
                        final friend = onlineFriends[index];
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 900 + (index * 100)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, animValue, child) {
                            return Transform.scale(
                              scale: animValue,
                              child: Container(
                                margin: const EdgeInsets.only(right: 16),
                                child: _buildOnlineFriendAvatar(friend),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOnlineFriendAvatar(Map<String, dynamic> friend) {
    final bool isYou = friend['name'] == 'You';

    return GestureDetector(
      onTap: () {
        if (!isYou) {
          _showFriendProfile(friend);
        }
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: isYou
                      ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                      : null,
                  color: isYou ? null : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                child: isYou
                    ? const Icon(Icons.person, color: Colors.white, size: 24)
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: Image.asset(
                    friend['avatar'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Color(0xFF64748B));
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            friend['name'],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isYou ? const Color(0xFF6366F1) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF64748B).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: _tabs.map((tab) {
                  final isSelected = tab == _selectedTab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = tab);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tab,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFriendsList() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF64748B).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Text(
                          _getTabTitle(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        if (_selectedTab == 'Requests')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ..._getFriendsForTab().asMap().entries.map((entry) {
                    final index = entry.key;
                    final friend = entry.value;
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1100 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, animValue, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - animValue)),
                          child: Opacity(
                            opacity: animValue,
                            child: _buildFriendTile(friend),
                          ),
                        );
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFriendTile(Map<String, dynamic> friend) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: friend['isOnline'] == true
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B).withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: Image.asset(
                    friend['avatar'] ?? 'assets/images/avatars/default-avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Color(0xFF64748B));
                    },
                  ),
                ),
              ),
              if (friend['isOnline'] == true)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  friend['status'] ?? 'Playing Trivia Tycoon',
                  style: TextStyle(
                    fontSize: 12,
                    color: friend['isOnline'] == true
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(friend),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> friend) {
    switch (_selectedTab) {
      case 'Requests':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _acceptFriendRequest(friend),
                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _declineFriendRequest(friend),
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        );
      case 'Suggested':
        return ElevatedButton(
          onPressed: () => _sendFriendRequest(friend),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Add',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      default:
        return PopupMenuButton<String>(
          onSelected: (value) => _handleFriendAction(friend, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'message', child: Text('Send Message')),
            const PopupMenuItem(value: 'challenge', child: Text('Challenge')),
            const PopupMenuItem(value: 'profile', child: Text('View Profile')),
            const PopupMenuItem(value: 'remove', child: Text('Remove Friend')),
          ],
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.more_vert,
              color: Color(0xFF6366F1),
              size: 18,
            ),
          ),
        );
    }
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddFriendDialog(),
      backgroundColor: const Color(0xFF6366F1),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.person_add),
      label: const Text(
        'Add Friend',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getTabTitle() {
    switch (_selectedTab) {
      case 'Requests':
        return 'Friend Requests';
      case 'Suggested':
        return 'Suggested Friends';
      default:
        return 'All Friends';
    }
  }

  List<Map<String, dynamic>> _getFriendsForTab() {
    switch (_selectedTab) {
      case 'Requests':
        return [
          {'name': 'Alex Thompson', 'avatar': 'assets/images/avatars/avatar-6.png', 'isOnline': true},
          {'name': 'Jessica Wong', 'avatar': 'assets/images/avatars/avatar-7.png', 'isOnline': false},
          {'name': 'Marcus Johnson', 'avatar': 'assets/images/avatars/avatar-8.png', 'isOnline': true},
        ];
      case 'Suggested':
        return [
          {'name': 'Chris Miller', 'avatar': 'assets/images/avatars/avatar-9.png', 'isOnline': true, 'mutualFriends': 5},
          {'name': 'Amanda Davis', 'avatar': 'assets/images/avatars/avatar-10.png', 'isOnline': false, 'mutualFriends': 3},
        ];
      default:
        return [
          {'name': 'David Wilson', 'avatar': 'assets/images/avatars/avatar-2.png', 'isOnline': true, 'status': 'Currently playing'},
          {'name': 'Sarah Johnson', 'avatar': 'assets/images/avatars/avatar-3.png', 'isOnline': true, 'status': 'Last seen 5m ago'},
          {'name': 'Mike Chen', 'avatar': 'assets/images/avatars/avatar-4.png', 'isOnline': false, 'status': 'Last seen 2h ago'},
          {'name': 'Emma Roberts', 'avatar': 'assets/images/avatars/avatar-5.png', 'isOnline': true, 'status': 'Online'},
        ];
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Search Friends'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter friend\'s name or username',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFriendProfile(Map<String, dynamic> friend) {
    // Navigate to friend profile screen
  }

  void _showAddFriendDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddFriendDialog(),
      ),
    );
  }

  void _acceptFriendRequest(Map<String, dynamic> friend) {
    _showSuccessMessage('${friend['name']} is now your friend!');
  }

  void _declineFriendRequest(Map<String, dynamic> friend) {
    _showSuccessMessage('Friend request declined');
  }

  void _sendFriendRequest(Map<String, dynamic> friend) {
    _showSuccessMessage('Friend request sent to ${friend['name']}');
  }

  void _handleFriendAction(Map<String, dynamic> friend, String action) {
    switch (action) {
      case 'message':
        _showSuccessMessage('Opening chat with ${friend['name']}');
        break;
      case 'challenge':
        _showSuccessMessage('Challenge sent to ${friend['name']}');
        break;
      case 'profile':
        _showFriendProfile(friend);
        break;
      case 'remove':
        _showSuccessMessage('${friend['name']} removed from friends');
        break;
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
