import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/advanced/spectate_streaming_service.dart';

class SpectateLobbyScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserDisplayName;

  const SpectateLobbyScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserDisplayName,
  }) : super(key: key);

  @override
  State<SpectateLobbyScreen> createState() => _SpectateLobbyScreenState();
}

class _SpectateLobbyScreenState extends State<SpectateLobbyScreen> with SingleTickerProviderStateMixin {
  final SpectateStreamingService _spectateService = SpectateStreamingService();
  late TabController _tabController;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _spectateService.initialize();
    _loadAvailableGames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAvailableGames() {
    // In a real app, load games from backend
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildCategoryFilter()),
          SliverToBoxAdapter(child: _buildTabBar()),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPopularGames(),
                _buildFriendsGames(),
                _buildFollowingGames(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickJoin,
        icon: const Icon(Icons.flash_on),
        label: const Text('Quick Join'),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Spectate Live Games'),
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
              right: -50,
              top: -50,
              child: Icon(
                Icons.visibility,
                size: 200,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Science', 'History', 'Sports', 'Movies', 'Music'];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          );
        },
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
          Tab(text: 'Popular'),
          Tab(text: 'Friends'),
          Tab(text: 'Following'),
        ],
      ),
    );
  }

  Widget _buildPopularGames() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _buildGameCard(
          gameId: 'game_$index',
          title: 'Science Showdown #${index + 1}',
          category: 'Science',
          players: ['Alex', 'Jordan'],
          spectators: 42 - index * 3,
          isLive: true,
          thumbnail: null,
        );
      },
    );
  }

  Widget _buildFriendsGames() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildGameCard(
          gameId: 'friend_game_$index',
          title: 'History Battle',
          category: 'History',
          players: ['Sarah', 'Mike'],
          spectators: 15,
          isLive: true,
          thumbnail: null,
        );
      },
    );
  }

  Widget _buildFollowingGames() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Follow players to see their games here',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required String gameId,
    required String title,
    required String category,
    required List<String> players,
    required int spectators,
    required bool isLive,
    String? thumbnail,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _joinGame(gameId),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                if (isLive)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '$spectators',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...players.take(3).map((player) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: CircleAvatar(
                          radius: 12,
                          child: Text(
                            player[0].toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      )),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          players.join(' vs '),
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _joinGame(String gameId) {
    context.push('/spectate/$gameId', extra: {
      'currentUserId': widget.currentUserId,
      'currentUserDisplayName': widget.currentUserDisplayName,
    });
  }

  void _showQuickJoin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Join'),
        content: const Text('Join the most popular live game right now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _joinGame('popular_game_1');
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
