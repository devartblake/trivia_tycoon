import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dialogs/add_friend_dialog.dart';
import '../../core/services/api_service.dart';
import '../../core/models/social/friend_list_item_dto.dart';
import '../../core/models/social/friend_request_dto.dart';
import '../../core/models/social/friend_suggestion_dto.dart';
import '../../core/services/presence/rich_presence_service.dart';
import '../../game/models/user_presence_models.dart';
import '../../game/providers/friends_providers.dart';
import '../../game/providers/message_providers.dart';
import '../../game/providers/profile_providers.dart' hide currentUserIdProvider;
import '../../ui_components/presence/presence_status_widget.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import '../messages/message_detail_screen.dart';

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

  // ✅ ADD THIS - Presence service
  final _presenceService = RichPresenceService();

  List<Friend> _friends = [];
  List<Friend> _onlineFriends = [];
  List<FriendRequestDto> _pendingRequests = [];
  List<FriendSuggestionDto> _suggestions = [];
  bool _isLoadingFriends = true;
  String? _loadErrorMessage;

  String get _currentUserId => ref.read(currentUserIdProvider);

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

    // ✅ ADD THIS - Initialize presence and friends
    _initializeFriends();

    // ✅ ADD THIS - Listen to presence changes
    _presenceService.addListener(_onPresenceChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _presenceService.removeListener(_onPresenceChanged);
    super.dispose();
  }

  Future<void> _initializeFriends() async {
    try {
      setState(() {
        _isLoadingFriends = true;
        _loadErrorMessage = null;
      });

      await Future.wait([
        _loadFriends(),
        _loadRequests(),
        _loadSuggestions(),
      ]);
      _subscribeToFriends();

      if (!mounted) return;
      setState(() {
        _isLoadingFriends = false;
      });
    } on ApiRequestException catch (e) {
      LogManager.debug('[Friends] Social load failed: ${e.message} (${e.path})');
      if (!mounted) return;
      setState(() {
        _isLoadingFriends = false;
        _loadErrorMessage = _friendlyLoadErrorMessage(e);
      });
    } catch (e) {
      LogManager.debug('[Friends] Social load failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingFriends = false;
        _loadErrorMessage =
            'Could not load friends right now. Please try again.';
      });
    }
  }

  Future<void> _loadFriends() async {
    final response = await ref.refresh(friendsListProvider.future);
    _friends = response.items.map(_friendFromDto).toList(growable: false);
    _updateOnlineFriends();
  }

  Future<void> _loadRequests() async {
    final response = await ref.refresh(incomingFriendRequestsProvider.future);
    _pendingRequests = response.items;
  }

  Future<void> _loadSuggestions() async {
    _suggestions = await ref.refresh(friendSuggestionsProvider.future);
  }

  Friend _friendFromDto(FriendListItemDto dto) => Friend(
    id: dto.friendPlayerId,
    name: dto.displayName,
    username: dto.username,
    avatar: dto.avatarUrl,
    isOnline: dto.isOnline,
  );

  Friend _friendFromRequest(FriendRequestDto request) => Friend(
    id: request.fromPlayerId,
    name: request.senderDisplayName ?? request.senderUsername ?? 'Unknown',
    username: request.senderUsername ?? request.senderDisplayName ?? 'unknown',
    avatar: request.senderAvatarUrl,
  );

  Friend _friendFromSuggestion(FriendSuggestionDto suggestion) => Friend(
    id: suggestion.id,
    name: suggestion.displayName,
    username: suggestion.username,
    avatar: suggestion.avatarUrl,
  );

  // ✅ ADD THIS - Subscribe to friends' presence
  void _subscribeToFriends() {
    if (_friends.isEmpty) return;

    // Get friend IDs
    final friendIds = _friends.map((f) => f.id).toList();

    // Subscribe to their presence updates via WebSocket
    _presenceService.subscribeToUsers(friendIds);

    LogManager.debug('[Friends] Subscribed to ${friendIds.length} friends');
  }

  // ✅ ADD THIS - Handle presence changes
  void _onPresenceChanged() {
    if (!mounted) return;

    // Update online friends list
    _updateOnlineFriends();

    setState(() {
      // Rebuild UI with new presence data
    });
  }

  // ✅ ADD THIS - Update online friends based on presence
  void _updateOnlineFriends() {
    _onlineFriends = _friends.where((friend) {
      final presence = _presenceService.getUserPresence(friend.id);
      return presence?.status == PresenceStatus.online ||
          presence?.status == PresenceStatus.inGame ||
          presence?.status == PresenceStatus.busy ||
          (presence == null && friend.isOnline);
    }).toList(growable: false);
  }

  // ✅ ADD THIS - Start quiz (update my presence)
  void _startQuiz({
    String difficulty = 'Easy',
    String category = 'General',
  }) {
    _presenceService.setGameActivity(
      gameType: 'quiz',
      gameMode: 'solo',
      currentLevel: difficulty,
      gameState: GameState.playing,
      metadata: {
        'category': category,
        'startedAt': DateTime.now().toIso8601String(),
      },
    );

    LogManager.debug('[Friends] Started quiz - presence updated');

    // Navigate to quiz screen
    // Navigator.of(context).push(...);
  }

  // ✅ ADD THIS - Join match (update my presence)
  void _joinMatch(String matchId, {String? opponentId, String? opponentName}) {
    _presenceService.setGameActivity(
      gameType: 'match',
      gameMode: 'pvp',
      gameState: GameState.lobby,
      metadata: {
        'matchId': matchId,
        if (opponentId != null) 'opponentId': opponentId,
        if (opponentName != null) 'opponentName': opponentName,
      },
    );

    LogManager.debug('[Friends] Joined match $matchId - presence updated');

    // Navigate to match screen
    // Navigator.of(context).push(...);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoadingFriends
            ? const Center(child: CircularProgressIndicator())
            : _loadErrorMessage != null
                ? _buildLoadErrorState()
            : CustomScrollView(
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

  Widget _buildLoadErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 16),
            const Text(
              'Friends are unavailable right now',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadErrorMessage ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initializeFriends,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _friendlyLoadErrorMessage(ApiRequestException error) {
    if (error.message == 'API Timeout') {
      return 'The friends service did not respond in time. Check that the backend is running and reachable from this device.';
    }
    return error.message;
  }

  PreferredSizeWidget _buildAppBar() {
    // ✅ CHANGED - Use real online count
    final onlineCount = _onlineFriends.length;

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
        onPressed: () => context.pop(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Friends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '$onlineCount friends online', // ✅ Real count
                style: const TextStyle(
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
    // ✅ CHANGED - Use real online friends with presence
    if (_onlineFriends.isEmpty) {
      return const SizedBox.shrink();
    }

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
                        '${_onlineFriends.length} online',
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
                      itemCount: _onlineFriends.length,
                      itemBuilder: (context, index) {
                        final friend = _onlineFriends[index];
                        final presence = _presenceService.getUserPresence(friend.id);

                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 900 + (index * 100)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, animValue, child) {
                            return Transform.scale(
                              scale: animValue,
                              child: Opacity(
                                opacity: animValue,
                                child: _buildOnlineFriendAvatar(friend, presence),
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

  Widget _buildOnlineFriendAvatar(Friend friend, UserPresence? presence) {
    return GestureDetector(
      onTap: () => _showFriendDetails(friend),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // ✅ Use YOUR PresenceStatusIndicator
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 23,
                    backgroundImage: _avatarProvider(friend.avatar),
                    child: friend.avatar == null
                        ? Text(friend.name[0])
                        : null,
                  ),
                ),
                if (presence != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: PresenceStatusIndicator(
                      status: presence.status,
                      size: 14,
                      showBorder: true,
                      animated: true,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: Text(
                friend.name.split(' ').first,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = tab == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFriendsList() {
    final friends = _getFriendsForTab();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
          Text(
            _getTabTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: friends.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final friend = friends[index];
              return _buildFriendItem(friend);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(Friend friend) {
    // ✅ CHANGED - Get real presence
    final presence = _presenceService.getUserPresence(friend.id);
    final presenceText = presence != null
        ? _presenceService.getFormattedPresence(friend.id)
        : (friend.isOnline ? 'Online' : 'Offline');

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Row(
            children: [
              // ✅ Use YOUR PresenceStatusIndicator
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: _avatarProvider(friend.avatar),
                      child: friend.avatar == null
                          ? Text(friend.name[0])
                          : null,
                    ),
                  ),
                  if (presence != null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: PresenceStatusIndicator(
                        status: presence.status,
                        size: 12,
                        showBorder: true,
                        animated: true,
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
                      friend.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      presenceText,
                      style: TextStyle(
                        fontSize: 12,
                        color: presence?.status == PresenceStatus.online ||
                            presence?.status == PresenceStatus.inGame
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
      },
    );
  }

  Widget _buildActionButton(Friend friend) {
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
            const PopupMenuItem(value: 'challenge', child: Text('Challenge to Match')),
            const PopupMenuItem(value: 'quiz', child: Text('Start Quiz Together')),
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

  List<Friend> _getFriendsForTab() {
    switch (_selectedTab) {
      case 'Requests':
        return _pendingRequests.map(_friendFromRequest).toList();
      case 'Suggested':
        return _suggestions.map(_friendFromSuggestion).toList();
      default:
        return _friends;
    }
  }

  // ✅ ADD THIS - Show friend details with presence
  void _showFriendDetails(Friend friend) {
    final presence = _presenceService.getUserPresence(friend.id);

    if (presence == null) {
      _showFriendProfile(friend);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DetailedPresenceCard(
        presence: presence,
        userName: friend.name,
        userAvatar: friend.avatar,
      ),
    );
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

  void _showFriendProfile(Friend friend) {
    // Navigate to friend profile screen
    LogManager.debug('[Friends] Showing profile for ${friend.name}');
  }

  void _showAddFriendDialog() {
    context.push('/messages/add-friend');
  }

  Future<void> _acceptFriendRequest(Friend friend) async {
    final request = _pendingRequests.firstWhere(
      (r) => r.fromPlayerId == friend.id,
      orElse: () => const FriendRequestDto(
        requestId: '',
        fromPlayerId: '',
        toPlayerId: '',
        status: 'Pending',
        createdAtUtc: null,
        respondedAtUtc: null,
      ),
    );
    if (request.requestId.isEmpty) return;
    final backendService = ref.read(backendProfileSocialServiceProvider);
    await backendService.acceptFriendRequest(request.requestId);
    ref.invalidate(friendsListProvider);
    ref.invalidate(incomingFriendRequestsProvider);
    if (mounted) {
      await Future.wait([_loadFriends(), _loadRequests()]);
      _subscribeToFriends();
      setState(() {});
      _showSuccessMessage('${friend.name} is now your friend!');
    }
  }

  Future<void> _declineFriendRequest(Friend friend) async {
    final request = _pendingRequests.firstWhere(
      (r) => r.fromPlayerId == friend.id,
      orElse: () => const FriendRequestDto(
        requestId: '',
        fromPlayerId: '',
        toPlayerId: '',
        status: 'Pending',
        createdAtUtc: null,
        respondedAtUtc: null,
      ),
    );
    if (request.requestId.isEmpty) return;
    final backendService = ref.read(backendProfileSocialServiceProvider);
    await backendService.declineFriendRequest(request.requestId);
    ref.invalidate(incomingFriendRequestsProvider);
    if (mounted) {
      await _loadRequests();
      setState(() {});
      _showSuccessMessage('Friend request declined');
    }
  }

  Future<void> _sendFriendRequest(Friend friend) async {
    final backendService = ref.read(backendProfileSocialServiceProvider);
    final response = await backendService.sendFriendRequest(friend.id);
    final success = response.requestId.isNotEmpty;
    ref.invalidate(sentFriendRequestsProvider);
    ref.invalidate(friendSuggestionsProvider);
    if (mounted) {
      await _loadSuggestions();
      setState(() {});
      _showSuccessMessage(success
          ? 'Friend request sent to ${friend.name}'
          : 'Could not send request to ${friend.name}');
    }
  }

  void _handleFriendAction(Friend friend, String action) {
    switch (action) {
      case 'message':
        final conversation = findOrCreateDirectConversation(ref, _currentUserId, friend.id);
        if (conversation != null) {
          final presence = _presenceService.getUserPresence(friend.id);
          context.push('/messages/detail/${conversation.id}', extra: {
            'contactName': friend.name,
            'contactAvatar': friend.avatar,
            'isOnline': presence?.status == PresenceStatus.online || presence?.status == PresenceStatus.inGame,
            'currentActivity': presence != null ? _presenceService.getFormattedPresence(friend.id) : null,
          });
        }
        break;
      case 'challenge':
        _joinMatch(
          'match_${DateTime.now().millisecondsSinceEpoch}',
          opponentId: friend.id,
          opponentName: friend.name,
        );
        _showSuccessMessage('Challenge sent to ${friend.name}');
        break;
      case 'quiz':
        _startQuiz(difficulty: 'Medium', category: 'General');
        _showSuccessMessage('Starting quiz with ${friend.name}');
        break;
      case 'profile':
        _showFriendProfile(friend);
        break;
      case 'remove':
        _removeFriend(friend);
        break;
    }
  }

  Future<void> _removeFriend(Friend friend) async {
    try {
      final backendService = ref.read(backendProfileSocialServiceProvider);
      final backendResponse = await backendService.removeFriend(
        friend.id,
        playerId: _currentUserId,
      );
      final backendSucceeded = backendResponse['removed'] == true ||
          backendResponse['success'] == true ||
          backendResponse.isEmpty;
      if (backendSucceeded && mounted) {
        ref.invalidate(friendsListProvider);
        await _loadFriends();
        _subscribeToFriends();
        _updateOnlineFriends();
        setState(() {});
        _showSuccessMessage('${friend.name} removed from friends');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove ${friend.name} right now'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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

  ImageProvider<Object>? _avatarProvider(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return null;
    }
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return NetworkImage(avatar);
    }
    return AssetImage(avatar);
  }
}

// ✅ ADD THIS - Friend model (if you don't have one already)
class Friend {
  final String id;
  final String name;
  final String username;
  final String? avatar;
  final bool isOnline;

  Friend({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.isOnline = false,
  });
}
