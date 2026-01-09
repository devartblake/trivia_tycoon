import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/helpers/responsive_layout.dart';

class MiniGamesHubScreen extends StatelessWidget {
  const MiniGamesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFF),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        ),
      ),
    );
  }

  // Mobile Layout - Original vertical scroll
  Widget _buildMobileLayout(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildFeaturedGameCard(context),
              const SizedBox(height: 32),
              ..._buildLogicPuzzlesSection(context),
              const SizedBox(height: 32),
              ..._buildWordGamesSection(context),
              const SizedBox(height: 32),
              ..._buildMemoryStrategySection(context),
              const SizedBox(height: 32),
              // NEW: CTA Card
              _buildCTACard(context),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  // Tablet Layout
  Widget _buildTabletLayout(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildFeaturedGameCard(context),
              const SizedBox(height: 36),
              ..._buildLogicPuzzlesSection(context),
              const SizedBox(height: 36),
              ..._buildWordGamesSection(context),
              const SizedBox(height: 36),
              ..._buildMemoryStrategySection(context),
              const SizedBox(height: 36),
              // NEW: CTA Card
              _buildCTACard(context),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  // Desktop Layout - Grid with better space utilization
  Widget _buildDesktopLayout(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured Game - Full Width
                    _buildFeaturedGameCard(context),

                    const SizedBox(height: 48),

                    // Logic Puzzles Section
                    const Text(
                      'Logic Puzzles',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGameGrid(context, _getLogicPuzzleGames()),

                    const SizedBox(height: 48),

                    // Word Games Section
                    const Text(
                      'Word Games',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGameGrid(context, _getWordGames()),

                    const SizedBox(height: 48),

                    // Memory & Strategy Section
                    const Text(
                      'Memory & Strategy',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGameGrid(context, _getMemoryStrategyGames()),

                    const SizedBox(height: 48),

                    // NEW: CTA Card - Full Width
                    _buildCTACard(context),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Game grid for desktop layout
  Widget _buildGameGrid(BuildContext context, List<Map<String, dynamic>> games) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of columns based on width
        int crossAxisCount = 2;
        double childAspectRatio = 3.2;

        if (constraints.maxWidth > 1200) {
          crossAxisCount = 3;
          childAspectRatio = 3.0; // More height for 3 columns
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 2;
          childAspectRatio = 3.2; // More height for 2 columns
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio, // Adjusted for better fit
            crossAxisSpacing: 20,
            mainAxisSpacing: 16,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return _buildGameCard(
              context,
              title: game['title'],
              subtitle: game['subtitle'],
              description: game['description'],
              icon: game['icon'],
              gradient: game['gradient'],
              route: game['route'],
              difficulty: game['difficulty'],
              comingSoon: game['comingSoon'] ?? false,
            );
          },
        );
      },
    );
  }

  // App Bar
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Center(
        child: Container(
          margin: const EdgeInsets.only(left: 12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mini Games',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Challenge your brain with fun puzzles',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Section builders for mobile
  List<Widget> _buildLogicPuzzlesSection(BuildContext context) {
    return [
      const Text(
        'Logic Puzzles',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
      const SizedBox(height: 16),
      ..._getLogicPuzzleGames().map((game) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildGameCard(
          context,
          title: game['title'],
          subtitle: game['subtitle'],
          description: game['description'],
          icon: game['icon'],
          gradient: game['gradient'],
          route: game['route'],
          difficulty: game['difficulty'],
          comingSoon: game['comingSoon'] ?? false,
        ),
      )),
    ];
  }

  List<Widget> _buildWordGamesSection(BuildContext context) {
    return [
      const Text(
        'Word Games',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
      const SizedBox(height: 16),
      ..._getWordGames().map((game) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildGameCard(
          context,
          title: game['title'],
          subtitle: game['subtitle'],
          description: game['description'],
          icon: game['icon'],
          gradient: game['gradient'],
          route: game['route'],
          difficulty: game['difficulty'],
          comingSoon: game['comingSoon'] ?? false,
        ),
      )),
    ];
  }

  List<Widget> _buildMemoryStrategySection(BuildContext context) {
    return [
      const Text(
        'Memory & Strategy',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
      const SizedBox(height: 16),
      ..._getMemoryStrategyGames().map((game) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildGameCard(
          context,
          title: game['title'],
          subtitle: game['subtitle'],
          description: game['description'],
          icon: game['icon'],
          gradient: game['gradient'],
          route: game['route'],
          difficulty: game['difficulty'],
          comingSoon: game['comingSoon'] ?? false,
        ),
      )),
    ];
  }

  // Game data getters
  List<Map<String, dynamic>> _getLogicPuzzleGames() {
    return [
      {
        'title': '2048',
        'subtitle': 'Number Puzzle',
        'description': 'Combine tiles to reach 2048',
        'icon': Icons.grid_4x4_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        'route': '/2048',
        'difficulty': 'Medium',
        'comingSoon': false,
      },
      {
        'title': 'Sudoku',
        'subtitle': 'Logic Grid',
        'description': 'Fill the grid with numbers',
        'icon': Icons.grid_on_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        'route': '/sudoku',
        'difficulty': 'Hard',
        'comingSoon': true,
      },
      {
        'title': 'Nonogram',
        'subtitle': 'Picture Logic',
        'description': 'Reveal hidden pictures',
        'icon': Icons.image_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
        'route': '/nonogram',
        'difficulty': 'Medium',
        'comingSoon': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getWordGames() {
    return [
      {
        'title': 'Word Search',
        'subtitle': 'Find Hidden Words',
        'description': 'Locate words in the grid',
        'icon': Icons.search_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        'route': '/word-search',
        'difficulty': 'Easy',
        'comingSoon': true,
      },
      {
        'title': 'Crossword',
        'subtitle': 'Word Puzzle',
        'description': 'Fill in the blanks with clues',
        'icon': Icons.border_all_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
        ),
        'route': '/crossword',
        'difficulty': 'Hard',
        'comingSoon': true,
      },
      {
        'title': 'Anagram',
        'subtitle': 'Scrambled Words',
        'description': 'Unscramble letters to form words',
        'icon': Icons.shuffle_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        ),
        'route': '/anagram',
        'difficulty': 'Medium',
        'comingSoon': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getMemoryStrategyGames() {
    return [
      {
        'title': 'Memory Match',
        'subtitle': 'Card Matching',
        'description': 'Find all matching pairs',
        'icon': Icons.layers_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        'route': '/memory-match',
        'difficulty': 'Easy',
        'comingSoon': true,
      },
      {
        'title': 'Simon Says',
        'subtitle': 'Pattern Memory',
        'description': 'Repeat the color sequence',
        'icon': Icons.album_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
        ),
        'route': '/simon-says',
        'difficulty': 'Medium',
        'comingSoon': true,
      },
      {
        'title': 'Chess Puzzle',
        'subtitle': 'Strategic Thinking',
        'description': 'Solve chess challenges',
        'icon': Icons.sports_esports_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF64748B), Color(0xFF475569)],
        ),
        'route': '/chess-puzzle',
        'difficulty': 'Hard',
        'comingSoon': true,
      },
    ];
  }

  Widget _buildFeaturedGameCard(BuildContext context) {
    return Container(
      height: 220, // Increased from 180
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/connections-puzzle'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🔥 FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Connections',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Group words by finding hidden connections',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildFeatureBadge(Icons.groups_rounded, 'Social'),
                          const SizedBox(width: 8),
                          _buildFeatureBadge(Icons.psychology_rounded, 'Brain'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hub_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NEW: CTA Card - Similar style to Featured Game Card
  Widget _buildCTACard(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEF4444), // Red
            Color(0xFFF59E0B), // Amber/Orange
            Color(0xFFFBBF24), // Yellow
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/arcade'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '✨ SPECIAL OFFER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Get Premium Access',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock all games and premium features',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildFeatureBadge(Icons.star_rounded, 'Premium'),
                          const SizedBox(width: 8),
                          _buildFeatureBadge(Icons.trending_up_rounded, 'Popular'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String description,
        required IconData icon,
        required LinearGradient gradient,
        required String route,
        required String difficulty,
        bool comingSoon = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: comingSoon
              ? () => _showComingSoonDialog(context)
              : () => context.push(route),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12), // Reduced from 14
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 48, // Reduced from 52
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24, // Reduced from 26
                  ),
                ),

                const SizedBox(width: 12), // Reduced from 14

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14, // Reduced from 15
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (comingSoon) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'SOON',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF59E0B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11, // Reduced from 12
                          color: Colors.grey.shade600,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5), // Reduced from 6
                      Row(
                        children: [
                          _buildDifficultyBadge(difficulty),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.circle,
                            size: 3,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              description,
                              style: TextStyle(
                                fontSize: 10, // Reduced from 11
                                color: Colors.grey.shade500,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8), // Reduced from 10

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = const Color(0xFF10B981);
        break;
      case 'medium':
        color = const Color(0xFFF59E0B);
        break;
      case 'hard':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), // Reduced from 6
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 9, // Reduced from 10
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.2,
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.construction_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 12),
            Text('Coming Soon'),
          ],
        ),
        content: const Text(
          'This mini game is currently under development. Stay tuned for updates!',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}