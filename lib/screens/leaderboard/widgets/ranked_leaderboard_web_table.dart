import 'package:flutter/material.dart';
import '../../../game/models/ranked_leaderboard_models.dart';

class RankedLeaderboardWebTable extends StatefulWidget {
  final List<RankedLeaderboardEntry> entries;
  final int currentPage;
  final int total;
  final int pageSize;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;
  final String seasonId;

  const RankedLeaderboardWebTable({
    super.key,
    required this.entries,
    required this.currentPage,
    required this.total,
    required this.pageSize,
    required this.seasonId,
    this.onPrevPage,
    this.onNextPage,
  });

  @override
  State<RankedLeaderboardWebTable> createState() =>
      _RankedLeaderboardWebTableState();
}

class _RankedLeaderboardWebTableState extends State<RankedLeaderboardWebTable> {
  late List<RankedLeaderboardEntry> _sortedEntries;
  SortColumn? _sortColumn;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _sortedEntries = List.from(widget.entries);
  }

  @override
  void didUpdateWidget(RankedLeaderboardWebTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _sortedEntries = List.from(widget.entries);
      _applySorting();
    }
  }

  void _applySorting() {
    if (_sortColumn == null) return;

    _sortedEntries.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case SortColumn.rank:
          comparison = a.tierRank.compareTo(b.tierRank);
          break;
        case SortColumn.seasonRank:
          comparison = a.seasonRank.compareTo(b.seasonRank);
          break;
        case SortColumn.rankPoints:
          comparison = a.rankPoints.compareTo(b.rankPoints);
          break;
        case SortColumn.wins:
          comparison = a.wins.compareTo(b.wins);
          break;
        case SortColumn.losses:
          comparison = a.losses.compareTo(b.losses);
          break;
        case SortColumn.draws:
          comparison = a.draws.compareTo(b.draws);
          break;
        case SortColumn.matches:
          comparison = a.matchesPlayed.compareTo(b.matchesPlayed);
          break;
        case null:
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _handleSort(SortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }
      _applySorting();
    });
  }

  Widget _buildSortHeader(
    String label,
    SortColumn column, {
    double? width,
  }) {
    final isActive = _sortColumn == column;
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () => _handleSort(column),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: Theme.of(context).primaryColor,
              ),
            ] else
              const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final from = ((widget.currentPage - 1) * widget.pageSize) + 1;
    final to = (widget.currentPage * widget.pageSize).clamp(1, widget.total);

    return Column(
      children: [
        // Header info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Season: ${widget.seasonId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                'Total: ${widget.total} | Showing: $from–$to',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header row
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        _buildSortHeader('Rank', SortColumn.rank, width: 80),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: _buildSortHeader(
                            'Player',
                            SortColumn.seasonRank,
                          ),
                        ),
                        const SizedBox(width: 24),
                        _buildSortHeader('RP', SortColumn.rankPoints,
                            width: 90),
                        const SizedBox(width: 24),
                        _buildSortHeader('Wins', SortColumn.wins, width: 80),
                        const SizedBox(width: 24),
                        _buildSortHeader('Losses', SortColumn.losses,
                            width: 90),
                        const SizedBox(width: 24),
                        _buildSortHeader('Draws', SortColumn.draws, width: 80),
                        const SizedBox(width: 24),
                        _buildSortHeader(
                          'Matches',
                          SortColumn.matches,
                          width: 100,
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'Global',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Data rows
                ...List.generate(
                  _sortedEntries.length,
                  (index) {
                    final entry = _sortedEntries[index];
                    final isEven = index.isEven;

                    return Container(
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : Colors.grey[50],
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            // Rank
                            SizedBox(
                              width: 80,
                              child: Text(
                                '#${entry.tierRank}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Player (Tier)
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Player ${entry.playerId.substring(0, 8)}…',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Tier ${entry.tier}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // RP
                            SizedBox(
                              width: 90,
                              child: Text(
                                '${entry.rankPoints}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Wins
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${entry.wins}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Losses
                            SizedBox(
                              width: 90,
                              child: Text(
                                '${entry.losses}',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Draws
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${entry.draws}',
                                style: TextStyle(
                                  color: Colors.amber[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Matches Played
                            SizedBox(
                              width: 100,
                              child: Text(
                                '${entry.matchesPlayed}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Global Rank
                            SizedBox(
                              width: 100,
                              child: Text(
                                '#${entry.seasonRank}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Footer pagination
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Page ${widget.currentPage} of ${(widget.total / widget.pageSize).ceil()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: widget.onPrevPage,
                  child: const Text('← Previous'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: widget.onNextPage,
                  child: const Text('Next →'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum SortColumn {
  rank,
  seasonRank,
  rankPoints,
  wins,
  losses,
  draws,
  matches,
}
