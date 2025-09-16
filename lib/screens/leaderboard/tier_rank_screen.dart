import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/game/controllers/leaderboard_controller.dart';
import 'package:trivia_tycoon/screens/leaderboard/widgets/leaderboard_swipe_card.dart';
import 'package:trivia_tycoon/screens/leaderboard/widgets/top_three_leaderboard.dart';

import '../../admin/leaderboard/leaderboard_filter_screen.dart';

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
      await ref.read(leaderboardControllerProvider).loadLeaderboard(); // Offline-first call
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
    if (index == -1 || index < 3) return; // Top 3 already shown

    final scrollIndex = index - 3;  // Since top 3 are in header
    await Future.delayed(const Duration(milliseconds:  300));

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollIndex * 78.0,
        duration: const Duration(milliseconds:  600),
        curve: Curves.easeInOut
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardController = ref.watch(leaderboardControllerProvider);
    final entries = leaderboardController.filteredEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        actions: [
          Consumer(
            builder: (_, ref, __) {
              final controller = ref.watch(leaderboardControllerProvider);
              final isFiltered = controller.isFilterActive;

              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.filter_alt),
                    if (isFiltered)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(),
                        ),
                      ),
                  ],
                ),
                onPressed: () async {
                  // Navigate to filter screen
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminLeaderboardFilterScreen(),
                    ),
                  );

                  // Refresh filters after returning
                  await ref.read(leaderboardControllerProvider).refreshFilters();
                },
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text("Sort by: "),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedSort,
                      onChanged: _onSortChanged,
                      items: _sortOptions
                          .map((opt) => DropdownMenuItem(
                        value: opt,
                        child: Text(opt),
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _categories.map((tab) => Tab(text: tab.key)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: leaderboardController.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: _categories.map((_) {
                      return entries.isEmpty
                          ? const Center(child: Text("No data yet."))
                          : Column(
                            children: [
                              TopThreeLeaderboard(
                                topThree: entries.take(3).toList(),
                              ),
                              const Divider(),
                              Expanded(
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: entries.length - 3,
                                  itemBuilder: (_, index) {
                                    final rank = index + 4;
                                    final entry = entries[index + 3];
                                    return LeaderboardSwipeCard(
                                      playerName: entry.playerName,
                                      score: entry.score,
                                      entry: entry,
                                      onPromote: () => ref.read(leaderboardControllerProvider).promoteUser(entry),
                                      onBan: () {
                                        ref.read(leaderboardControllerProvider).banUser(entry);
                                        setState(() {});
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                    }).toList(),
              ),
    );
  }
}
