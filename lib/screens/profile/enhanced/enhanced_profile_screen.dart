import 'package:flutter/material.dart';
import '../../../core/services/presence/rich_presence_service.dart';
import '../../../game/models/user_presence_models.dart';
import '../../../ui_components/presence/rich_presence_indicator.dart';
import 'widgets/game_stats_widget.dart';
import 'widgets/profile_header.dart';
import 'mutual_friends_screen.dart';

class EnhancedProfileScreen extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final bool isOwnProfile;

  const EnhancedProfileScreen({
    super.key,
    required this.userId,
    required this.currentUserId,
    this.isOwnProfile = false,
  });

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen>
    with SingleTickerProviderStateMixin {
  final RichPresenceService _presenceService = RichPresenceService();
  late TabController _tabController;

  // Mock user data
  final Map<String, dynamic> _userData = {
    'displayName': 'Alex Johnson',
    'username': '@alexj',
    'bio': 'Trivia enthusiast | Quiz champion | Always up for a challenge 🎯',
    'joinDate': DateTime(2023, 1, 15),
    'friendCount': 127,
    'mutualFriends': 12,
    'level': 42,
    'totalPoints': 15420,
    'achievements': 23,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileInfo(context),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 8),
                _buildTabBar(),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatsTab(context),
                _buildActivityTab(context),
                _buildAchievementsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.network(
                'https://example.com/banner.jpg', // Placeholder
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isOwnProfile)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditProfile(),
          )
        else
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'message',
                child: ListTile(
                  leading: Icon(Icons.message),
                  title: Text('Send Message'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'challenge',
                child: ListTile(
                  leading: Icon(Icons.sports_esports),
                  title: Text('Challenge to Quiz'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'block',
                child: ListTile(
                  leading: Icon(Icons.block, color: Colors.red),
                  title: Text('Block', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -50),
      child: Column(
        children: [
          ProfileHeader(
            userId: widget.userId,
            displayName: _userData['displayName'],
            username: _userData['username'],
            bio: _userData['bio'],
            isOwnProfile: widget.isOwnProfile,
          ),
          const SizedBox(height: 16),
          _buildPresenceStatus(context),
          const SizedBox(height: 16),
          _buildStatsRow(context),
        ],
      ),
    );
  }

  Widget _buildPresenceStatus(BuildContext context) {
    return StreamBuilder<UserPresence?>(
      stream: _presenceService.watchUserPresence(widget.userId),
      builder: (context, snapshot) {
        final presence = snapshot.data;
        if (presence == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: RichPresenceIndicator(
            presence: presence,
            showDetailedInfo: true,
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            '${_userData['friendCount']}',
            'Friends',
            Icons.people,
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          _buildStatItem(
            context,
            'Lv ${_userData['level']}',
            'Level',
            Icons.stars,
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          _buildStatItem(
            context,
            '${_userData['achievements']}',
            'Achievements',
            Icons.emoji_events,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String value,
      String label,
      IconData icon,
      ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    if (widget.isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _navigateToEditProfile,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add),
              label: const Text('Add Friend'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.message),
              label: const Text('Message'),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _showMutualFriends(),
            child: Text('${_userData['mutualFriends']} mutual'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        tabs: const [
          Tab(text: 'Stats'),
          Tab(text: 'Activity'),
          Tab(text: 'Achievements'),
        ],
      ),
    );
  }

  Widget _buildStatsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GameStatsWidget(userId: widget.userId),
        const SizedBox(height: 16),
        _buildRecentMatchesCard(context),
        const SizedBox(height: 16),
        _buildStreaksCard(context),
      ],
    );
  }

  Widget _buildRecentMatchesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Matches',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._generateRecentMatches().map((match) => _buildMatchTile(context, match)),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchTile(BuildContext context, Map<String, dynamic> match) {
    final isWin = match['result'] == 'win';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWin
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWin
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isWin ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWin ? Icons.check : Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match['category'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${match['score']} points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            match['time'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Streaks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStreakItem(context, 'Current Streak', '7 days', Colors.orange),
            const SizedBox(height: 12),
            _buildStreakItem(context, 'Longest Streak', '23 days', Colors.blue),
            const SizedBox(height: 12),
            _buildStreakItem(context, 'Win Streak', '5 games', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(BuildContext context, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActivityTimeline(context),
      ],
    );
  }

  Widget _buildActivityTimeline(BuildContext context) {
    final activities = _generateRecentActivities();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...activities.map((activity) => _buildActivityItem(context, activity)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'],
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['time'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _generateAchievements().length,
      itemBuilder: (context, index) {
        final achievement = _generateAchievements()[index];
        return _buildAchievementCard(context, achievement);
      },
    );
  }

  Widget _buildAchievementCard(BuildContext context, Map<String, dynamic> achievement) {
    final isUnlocked = achievement['unlocked'];

    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              achievement['icon'],
              size: 32,
              color: isUnlocked
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              achievement['name'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isUnlocked ? null : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    // Navigate to edit profile screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMutualFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MutualFriendsScreen(
          userId: widget.userId,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(achievement['icon']),
            const SizedBox(width: 8),
            Expanded(child: Text(achievement['name'])),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement['description']),
            const SizedBox(height: 12),
            if (achievement['unlocked'])
              Text(
                'Unlocked: ${achievement['unlockedDate']}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else
              Text(
                'Progress: ${achievement['progress']}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'message':
      // Open message screen
        break;
      case 'challenge':
      // Send challenge
        break;
      case 'block':
      // Block user
        break;
    }
  }

  List<Map<String, dynamic>> _generateRecentMatches() {
    return [
      {'category': 'Science', 'score': 850, 'result': 'win', 'time': '2h ago'},
      {'category': 'History', 'score': 720, 'result': 'win', 'time': '5h ago'},
      {'category': 'Sports', 'score': 640, 'result': 'loss', 'time': '1d ago'},
      {'category': 'Movies', 'score': 910, 'result': 'win', 'time': '1d ago'},
    ];
  }

  List<Map<String, dynamic>> _generateRecentActivities() {
    return [
      {'icon': Icons.emoji_events, 'title': 'Earned "Quiz Master" achievement', 'time': '2 hours ago'},
      {'icon': Icons.people, 'title': 'Added 3 new friends', 'time': '5 hours ago'},
      {'icon': Icons.star, 'title': 'Reached Level 42', 'time': '1 day ago'},
      {'icon': Icons.sports_esports, 'title': 'Won 5 games in a row', 'time': '1 day ago'},
      {'icon': Icons.group, 'title': 'Joined "Trivia Champions" group', 'time': '2 days ago'},
    ];
  }

  List<Map<String, dynamic>> _generateAchievements() {
    return [
      {'name': 'First Win', 'icon': Icons.star, 'unlocked': true, 'description': 'Win your first game', 'unlockedDate': '15 Jan 2024'},
      {'name': 'Speed Demon', 'icon': Icons.flash_on, 'unlocked': true, 'description': 'Answer 10 questions in under 30 seconds', 'unlockedDate': '20 Jan 2024'},
      {'name': 'Brain Box', 'icon': Icons.psychology, 'unlocked': true, 'description': 'Get 100% in a quiz', 'unlockedDate': '3 Feb 2024'},
      {'name': 'Social Butterfly', 'icon': Icons.people, 'unlocked': true, 'description': 'Add 50 friends', 'unlockedDate': '10 Feb 2024'},
      {'name': 'Streak Master', 'icon': Icons.local_fire_department, 'unlocked': false, 'description': 'Maintain a 30-day streak', 'progress': 70},
      {'name': 'Quiz Champion', 'icon': Icons.emoji_events, 'unlocked': false, 'description': 'Win 100 games', 'progress': 45},
      {'name': 'Category King', 'icon': Icons.rocket, 'unlocked': false, 'description': 'Master all categories', 'progress': 60},
      {'name': 'Team Player', 'icon': Icons.group, 'unlocked': false, 'description': 'Play 50 team games', 'progress': 30},
      {'name': 'Night Owl', 'icon': Icons.nightlight, 'unlocked': false, 'description': 'Play after midnight 10 times', 'progress': 80},
    ];
  }
}
