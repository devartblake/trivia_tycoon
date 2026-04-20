import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/game/controllers/leaderboard_controller.dart';
import 'package:trivia_tycoon/screens/leaderboard/widgets/leaderboard_swipe_card.dart';
import 'package:trivia_tycoon/screens/leaderboard/widgets/top_three_leaderboard.dart';

enum SortField { score, level, wins, lastActive }

class TierRankScreen extends ConsumerStatefulWidget {
  const TierRankScreen({super.key});

  @override
  ConsumerState<TierRankScreen> createState() => _TierRankScreenState();
}

class _TierRankScreenState extends ConsumerState<TierRankScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<MapEntry<String, LeaderboardCategory>> _categories = [
    MapEntry('Top XP', LeaderboardCategory.topXP),
    MapEntry('Most Wins', LeaderboardCategory.mostWins),
    MapEntry('Daily', LeaderboardCategory.daily),
    MapEntry('Weekly', LeaderboardCategory.weekly),
    MapEntry('Global', LeaderboardCategory.global),
  ];

  final Map<SortField, String> sortLabels = {
    SortField.score: 'Score',
    SortField.level: 'Level',
    SortField.wins: 'Wins',
    SortField.lastActive: 'Last Active',
  };

  final List<String> _sortOptions = ['XP', 'Wins', 'Level', 'Last Active'];
  String _selectedSort = 'XP';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(leaderboardControllerProvider).loadLeaderboard();
      _scrollToCurrentUser(ref);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (_tabController.indexIsChanging) return;
    final selected = _categories[_tabController.index].value;
    ref.read(leaderboardControllerProvider).setCategory(selected);
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() => _selectedSort = value);
      ref.read(leaderboardControllerProvider).applySorting(value);
    }
  }

  Future<void> _scrollToCurrentUser(WidgetRef ref) async {
    final controller = ref.read(leaderboardControllerProvider);
    final entries = controller.filteredEntries;

    final userId = await AppSettings.getInt("currentUserId");

    final index = entries.indexWhere((e) => e.userId == userId);
    if (index == -1 || index < 3) return;

    final scrollIndex = index - 3;
    await Future.delayed(const Duration(milliseconds: 300));

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollIndex * 78.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardController = ref.watch(leaderboardControllerProvider);
    final entries = leaderboardController.filteredEntries;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () {
                    context.pop(); // Navigate to home route
                  },
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 20),
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Arena',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Compete with the best',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Consumer(
                builder: (_, ref, __) {
                  final controller = ref.watch(leaderboardControllerProvider);
                  final isFiltered = controller.isFilterActive;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Stack(
                          children: [
                            const Icon(Icons.tune_rounded, color: Colors.white),
                            if (isFiltered)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.orangeAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () async {
                          await context.push('/admin/leaderboard-filters');
                          await ref
                              .read(leaderboardControllerProvider)
                              .refreshFilters();
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // Sort and Filter Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 20,
                    color: theme.primaryColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Sort by:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          onChanged: _onSortChanged,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: theme.primaryColor,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryColor,
                          ),
                          items: _sortOptions
                              .map((opt) => DropdownMenuItem(
                                    value: opt,
                                    child: Text(opt),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category Tabs
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 48,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: _categories.map((tab) {
                  return Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(tab.key),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content
          leaderboardController.isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: _categories.map((_) {
                      return entries.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.leaderboard_outlined,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No rankings yet",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Be the first to compete!",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                // Top Three Podium
                                Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TopThreeLeaderboard(
                                    topThree: entries.take(3).toList(),
                                  ),
                                ),

                                // Rest of Rankings
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      padding:
                                          const EdgeInsets.only(bottom: 20),
                                      itemCount: entries.length - 3,
                                      itemBuilder: (_, index) {
                                        final entry = entries[index + 3];
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.04),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: LeaderboardSwipeCard(
                                            playerName: entry.playerName,
                                            score: entry.score,
                                            entry: entry,
                                            onPromote: () => ref
                                                .read(
                                                    leaderboardControllerProvider)
                                                .promoteUser(entry),
                                            onBan: () {
                                              ref
                                                  .read(
                                                      leaderboardControllerProvider)
                                                  .banUser(entry);
                                              setState(() {});
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }
}
