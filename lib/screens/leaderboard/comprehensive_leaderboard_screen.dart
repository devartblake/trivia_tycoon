import 'package:flutter/material.dart';
import '../../core/networking/synaptix_api_client.dart';
import '../../game/models/ranked_leaderboard_models.dart';
import '../../arcade/domain/arcade_game_id.dart';
import '../../arcade/domain/arcade_difficulty.dart';
import '../../arcade/leaderboards/arcade_global_leaderboard_view.dart';
import 'widgets/leaderboard_filter_panel.dart';
import 'widgets/all_tiers_leaderboard_view.dart';
import 'widgets/ranked_leaderboard_web_table.dart';

class ComprehensiveLeaderboardScreen extends StatefulWidget {
  final SynaptixApiClient api;
  final String? seasonId;

  const ComprehensiveLeaderboardScreen({
    super.key,
    required this.api,
    this.seasonId,
  });

  @override
  State<ComprehensiveLeaderboardScreen> createState() =>
      _ComprehensiveLeaderboardScreenState();
}

class _ComprehensiveLeaderboardScreenState
    extends State<ComprehensiveLeaderboardScreen> {
  int? _selectedTier;
  DateTimeRange? _dateRange;
  String? _searchQuery;
  int _currentPage = 1;
  String _viewMode = 'tier'; // 'tier', 'all_tiers', or 'arcade'

  // Arcade view state
  ArcadeGameId _selectedArcadeGame = ArcadeGameId.patternSprint;
  ArcadeDifficulty _selectedArcadeDifficulty = ArcadeDifficulty.normal;

  static const _pageSize = 50;

  Future<RankedLeaderboardResponse> _loadTierLeaderboard() async {
    final json = await widget.api.getJson(
      '/leaderboards/ranked',
      query: {
        if (widget.seasonId != null) 'seasonId': widget.seasonId!,
        if (_selectedTier != null) 'tier': '$_selectedTier',
        'page': '$_currentPage',
        'pageSize': '$_pageSize',
      },
    );
    return RankedLeaderboardResponse.fromJson(json);
  }

  Future<Map<int, List<RankedLeaderboardEntry>>> _loadAllTiers() async {
    final result = <int, List<RankedLeaderboardEntry>>{};

    for (int tier = 1; tier <= 10; tier++) {
      try {
        final json = await widget.api.getJson(
          '/leaderboards/ranked',
          query: {
            if (widget.seasonId != null) 'seasonId': widget.seasonId!,
            'tier': '$tier',
            'page': '1',
            'pageSize': '50',
          },
        );
        final response = RankedLeaderboardResponse.fromJson(json);

        // Apply filters if needed
        var entries = response.items;
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          entries = entries
              .where((e) =>
                  e.playerId.toLowerCase().contains(_searchQuery!.toLowerCase()))
              .toList();
        }

        if (entries.isNotEmpty) {
          result[tier] = entries;
        }
      } catch (e) {
        debugPrint('Error loading tier $tier: $e');
      }
    }

    return result;
  }

  void _clearFilters() {
    setState(() {
      _selectedTier = null;
      _dateRange = null;
      _searchQuery = null;
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // View mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'tier',
                        label: Text('By Tier'),
                        icon: Icon(Icons.equalizer),
                      ),
                      ButtonSegment(
                        value: 'all_tiers',
                        label: Text('All Tiers'),
                        icon: Icon(Icons.view_list),
                      ),
                      ButtonSegment(
                        value: 'arcade',
                        label: Text('Arcade'),
                        icon: Icon(Icons.games),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _viewMode = newSelection.first;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Filter panel (hidden for arcade view)
          if (_viewMode != 'arcade')
            LeaderboardFilterPanel(
              selectedTier: _selectedTier,
              dateRange: _dateRange,
              searchQuery: _searchQuery,
              onClearFilters: _clearFilters,
              onTierChanged: (tier) => setState(() {
                _selectedTier = tier;
                _currentPage = 1;
              }),
              onDateRangeChanged: (range) =>
                  setState(() => _dateRange = range),
              onSearchChanged: (query) => setState(() {
                _searchQuery = query;
                _currentPage = 1;
              }),
            ),

          // Content area
          Expanded(
            child: _viewMode == 'tier'
                ? _buildTierView()
                : _viewMode == 'all_tiers'
                    ? _buildAllTiersView()
                    : _buildArcadeView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTierView() {
    return FutureBuilder<RankedLeaderboardResponse>(
      future: _loadTierLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final width = MediaQuery.of(context).size.width;
        final isWideWeb = width >= 1000;

        if (isWideWeb) {
          // Web table view
          return RankedLeaderboardWebTable(
            entries: data.items,
            currentPage: data.page,
            total: data.total,
            pageSize: data.pageSize,
            seasonId: data.seasonId,
            onPrevPage: data.page > 1
                ? () => setState(() => _currentPage--)
                : null,
            onNextPage: (data.page * data.pageSize) < data.total
                ? () => setState(() => _currentPage++)
                : null,
          );
        } else {
          // Mobile card view
          return _buildMobileCardView(data);
        }
      },
    );
  }

  Widget _buildMobileCardView(RankedLeaderboardResponse data) {
    return Column(
      children: [
        Expanded(
          child: data.items.isEmpty
              ? Center(
                  child: Text(
                    'No players in this tier',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: data.items.length,
                  itemBuilder: (_, idx) {
                    final entry = data.items[idx];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('#${entry.tierRank}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const Spacer(),
                                Text('RP: ${entry.rankPoints}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Player ${entry.playerId.substring(0, 8)}…',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildStat('W', entry.wins, Colors.green),
                                _buildStat('L', entry.losses, Colors.red),
                                _buildStat('D', entry.draws, Colors.amber),
                                _buildStat('M', entry.matchesPlayed, null),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Pagination
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Text(
                'Page ${data.page} of ${(data.total / data.pageSize).ceil()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: data.page > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                child: const Text('← Prev'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: (data.page * data.pageSize) < data.total
                    ? () => setState(() => _currentPage++)
                    : null,
                child: const Text('Next →'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllTiersView() {
    return AllTiersLeaderboardView(
      loadTierData: _loadAllTiers,
      seasonId: widget.seasonId ?? 'Unknown',
    );
  }

  Widget _buildArcadeView() {
    final games = [
      ('Pattern Sprint', ArcadeGameId.patternSprint),
      ('Memory Flip', ArcadeGameId.memoryFlip),
      ('Quick Math Rush', ArcadeGameId.quickMathRush),
    ];

    const difficulties = [
      ArcadeDifficulty.easy,
      ArcadeDifficulty.normal,
      ArcadeDifficulty.hard,
      ArcadeDifficulty.insane,
    ];

    return Column(
      children: [
        // Game Picker
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Game',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: games.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, idx) {
                    final (label, gameId) = games[idx];
                    final isSelected = _selectedArcadeGame == gameId;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedArcadeGame = gameId);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Difficulty Picker
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Difficulty',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: difficulties.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, idx) {
                    final difficulty = difficulties[idx];
                    final isSelected = _selectedArcadeDifficulty == difficulty;
                    return ChoiceChip(
                      label: Text(difficulty.label),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedArcadeDifficulty = difficulty);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Leaderboard View
        Expanded(
          child: ArcadeGlobalLeaderboardView(
            gameId: _selectedArcadeGame,
            difficulty: _selectedArcadeDifficulty,
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, int value, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
