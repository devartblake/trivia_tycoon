import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/providers/arcade_providers.dart';
import '../domain/arcade_difficulty.dart';
import '../domain/arcade_game_id.dart';
import 'arcade_leaderboard_api_service.dart';

class ArcadeGlobalLeaderboardView extends ConsumerStatefulWidget {
  final ArcadeGameId gameId;
  final ArcadeDifficulty difficulty;

  const ArcadeGlobalLeaderboardView({
    super.key,
    required this.gameId,
    required this.difficulty,
  });

  @override
  ConsumerState<ArcadeGlobalLeaderboardView> createState() =>
      _ArcadeGlobalLeaderboardViewState();
}

class _ArcadeGlobalLeaderboardViewState
    extends ConsumerState<ArcadeGlobalLeaderboardView> {
  int _currentPage = 1;
  static const _pageSize = 50;
  ArcadeLeaderboardPage? _currentData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(arcadeLeaderboardApiServiceProvider);
      final data = await service.fetchLeaderboard(
        gameId: widget.gameId.name,
        difficulty: widget.difficulty.name,
        page: _currentPage,
        pageSize: _pageSize,
      );
      setState(() {
        _currentData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load leaderboard: $e';
        _loading = false;
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      _currentPage--;
      _loadPage();
    }
  }

  void _nextPage() {
    if (_currentData != null &&
        (_currentPage * _pageSize) < _currentData!.total) {
      _currentPage++;
      _loadPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadPage,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentData == null || _currentData!.items.isEmpty) {
      return Center(
        child: Text(
          'No scores yet for ${widget.difficulty.label}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    final data = _currentData!;
    final hasPrevPage = _currentPage > 1;
    final hasNextPage = (_currentPage * _pageSize) < data.total;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.gameId.name} - ${widget.difficulty.label}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (data.myRank != null)
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.cyan),
                    const SizedBox(width: 8),
                    Text(
                      'Your Rank: #${data.myRank} (Score: ${data.myScore})',
                      style: const TextStyle(color: Colors.cyan),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const Divider(color: Colors.white12),
        // Leaderboard list
        Expanded(
          child: ListView.builder(
            itemCount: data.items.length,
            itemBuilder: (context, index) {
              final entry = data.items[index];
              final isMyScore = data.myRank == entry.rank;

              return Container(
                color: isMyScore
                    ? Colors.cyan.withValues(alpha: 0.1)
                    : Colors.transparent,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(
                        width: 40,
                        child: Text(
                          '#${entry.rank}',
                          style: TextStyle(
                            color: _getRankColor(entry.rank),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Username
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${entry.durationMs ~/ 1000}s',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Score
                      Text(
                        '${entry.score}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Pagination
        const Divider(color: Colors.white12),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: hasPrevPage ? _prevPage : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Previous'),
              ),
              Text(
                'Page $_currentPage of ${(data.total + _pageSize - 1) ~/ _pageSize}',
                style: const TextStyle(color: Colors.white70),
              ),
              ElevatedButton.icon(
                onPressed: hasNextPage ? _nextPage : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.orange;
      default:
        return Colors.white70;
    }
  }
}
