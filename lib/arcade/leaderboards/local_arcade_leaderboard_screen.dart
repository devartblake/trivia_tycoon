import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/arcade/ui/screens/widgets/wallet_counters_row.dart';

import '../../../game/providers/riverpod_providers.dart';
import '../../../game/providers/wallet_providers.dart';
import '../domain/arcade_game_id.dart';
import '../providers/arcade_providers.dart';
import 'local_arcade_leaderboard_models.dart';
import 'local_arcade_leaderboard_service.dart';

class LocalArcadeLeaderboardScreen extends ConsumerStatefulWidget {
  const LocalArcadeLeaderboardScreen({super.key});

  @override
  ConsumerState<LocalArcadeLeaderboardScreen> createState() =>
      _LocalArcadeLeaderboardScreenState();
}

class _LocalArcadeLeaderboardScreenState
    extends ConsumerState<LocalArcadeLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_GameData> _games = [
    _GameData(
      id: ArcadeGameId.patternSprint,
      title: 'Pattern Sprint',
      icon: Icons.grid_4x4_rounded,
      gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    _GameData(
      id: ArcadeGameId.memoryFlip,
      title: 'Memory Flip',
      icon: Icons.style_rounded,
      gradient: const [Color(0xFFEC4899), Color(0xFFF59E0B)],
    ),
    _GameData(
      id: ArcadeGameId.quickMathRush,
      title: 'Quick Math Rush',
      icon: Icons.calculate_rounded,
      gradient: const [Color(0xFF10B981), Color(0xFF3B82F6)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _games.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildModernAppBar(context),
        ],
        body: Column(
          children: [
            _buildDailyBonusCard(context),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _games
                    .map((game) => _buildGameLeaderboard(context, game))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0F),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPatternPainter(),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Leaderboards',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Compete for glory',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: WalletCountersRow(compact: true, backplate: true),
        ),
      ],
    );
  }

  Widget _buildDailyBonusCard(BuildContext context) {
    final bonus = ref.read(arcadeDailyBonusServiceProvider);
    final claimed = bonus.isClaimedToday;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: claimed
              ? [
            const Color(0xFF1F1F28),
            const Color(0xFF2A2A35),
          ]
              : [
            const Color(0xFFFBBF24).withOpacity(0.2),
            const Color(0xFFF59E0B).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: claimed
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFFFBBF24).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          if (!claimed)
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFBBF24).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: claimed
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xFFFBBF24).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: claimed
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFFFBBF24).withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: claimed ? Colors.white.withOpacity(0.4) : const Color(0xFFFBBF24),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Daily Bonus',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          if (!claimed) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Color(0xFF0A0A0F),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        claimed
                            ? 'Come back tomorrow for more rewards!'
                            : '+250 Coins • +2 Gems',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: claimed
                          ? null
                          : () {
                        final didClaim = bonus.tryClaimToday();
                        if (!didClaim) return;

                        incrementCoins(ref, 250);
                        incrementGems(ref, 2);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Daily bonus claimed: +250 coins, +2 gems',
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: claimed
                            ? Colors.white.withOpacity(0.1)
                            : const Color(0xFFFBBF24),
                        foregroundColor: claimed ? Colors.white54 : const Color(0xFF0A0A0F),
                        elevation: claimed ? 0 : 4,
                        shadowColor: claimed ? Colors.transparent : const Color(0xFFFBBF24).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      child: Text(
                        claimed ? 'Claimed' : 'Claim',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (!claimed) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => context.push('/arcade/daily-bonus'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 30),
                        ),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6366F1).withOpacity(0.8),
              const Color(0xFF8B5CF6).withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.5),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        tabs: _games.map((game) {
          return Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(game.icon, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    game.title.split(' ')[0],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGameLeaderboard(BuildContext context, _GameData game) {
    final svc = ref.watch(localArcadeLeaderboardServiceProvider);
    final scores = svc.topForGame(game.id, limit: 10);

    if (scores.isEmpty) {
      return _buildEmptyState(game);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildPodium(scores.take(3).toList(), game),
          const SizedBox(height: 24),
          _buildLeaderboardList(scores, game),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _showFullLeaderboard(context, svc, game),
            icon: const Icon(Icons.list_rounded, size: 20),
            label: const Text(
              'View All Scores',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LocalArcadeScoreEntry> topScores, _GameData game) {
    if (topScores.isEmpty) return const SizedBox.shrink();

    // Arrange: 2nd, 1st, 3rd
    final List<Widget> podiumCards = [];

    if (topScores.length >= 2) {
      podiumCards.add(_buildPodiumCard(topScores[1], 2, 130, game));
    } else {
      podiumCards.add(const SizedBox(width: 100));
    }

    podiumCards.add(const SizedBox(width: 12));
    podiumCards.add(_buildPodiumCard(topScores[0], 1, 150, game));
    podiumCards.add(const SizedBox(width: 12));

    if (topScores.length >= 3) {
      podiumCards.add(_buildPodiumCard(topScores[2], 3, 110, game));
    } else {
      podiumCards.add(const SizedBox(width: 100));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: podiumCards,
    );
  }

  Widget _buildPodiumCard(
      LocalArcadeScoreEntry entry,
      int rank,
      double height,
      _GameData game,
      ) {
    final colors = _getPodiumColors(rank);

    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              rank == 1
                  ? Icons.workspace_premium_rounded
                  : rank == 2
                  ? Icons.emoji_events_rounded
                  : Icons.military_tech_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 100,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                colors[0].withOpacity(0.2),
                colors[1].withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: colors[0].withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  color: colors[0],
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${entry.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'points',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.difficulty.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(
      List<LocalArcadeScoreEntry> scores,
      _GameData game,
      ) {
    final displayScores = scores.skip(3).take(7).toList();

    if (displayScores.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  game.icon,
                  color: game.gradient[0],
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Top Scores',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayScores.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withOpacity(0.05),
              height: 1,
            ),
            itemBuilder: (_, i) => _ModernLeaderboardRow(
              rank: i + 4,
              entry: displayScores[i],
              gradient: game.gradient,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(_GameData game) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    game.gradient[0].withOpacity(0.2),
                    game.gradient[1].withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: game.gradient[0].withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                game.icon,
                size: 64,
                color: game.gradient[0].withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Scores Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to set a record!\nPlay ${game.title} to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullLeaderboard(
      BuildContext context,
      LocalArcadeLeaderboardService svc,
      _GameData game,
      ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E0E12),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final all = svc.topForGame(game.id, limit: 50);

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: game.gradient),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(game.icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'All Scores',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: all.isEmpty
                      ? Center(
                    child: Text(
                      'No scores recorded yet.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 15,
                      ),
                    ),
                  )
                      : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: all.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _ModernLeaderboardRow(
                      rank: i + 1,
                      entry: all[i],
                      gradient: game.gradient,
                      showBorder: true,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Color> _getPodiumColors(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    }
  }
}

class _GameData {
  final ArcadeGameId id;
  final String title;
  final IconData icon;
  final List<Color> gradient;

  _GameData({
    required this.id,
    required this.title,
    required this.icon,
    required this.gradient,
  });
}

class _ModernLeaderboardRow extends StatelessWidget {
  final int rank;
  final LocalArcadeScoreEntry entry;
  final List<Color> gradient;
  final bool showBorder;

  const _ModernLeaderboardRow({
    required this.rank,
    required this.entry,
    required this.gradient,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final secs = (entry.durationMs / 1000).toStringAsFixed(1);
    final isTopThree = rank <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isTopThree
            ? gradient[0].withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: showBorder
            ? Border.all(
          color: isTopThree
              ? gradient[0].withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
        )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: isTopThree
                  ? LinearGradient(colors: gradient)
                  : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: isTopThree ? 14 : 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.score} points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.difficulty.name.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${secs}s',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isTopThree)
            Icon(
              rank == 1
                  ? Icons.workspace_premium_rounded
                  : rank == 2
                  ? Icons.emoji_events_rounded
                  : Icons.military_tech_rounded,
              color: gradient[0],
              size: 28,
            ),
        ],
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}