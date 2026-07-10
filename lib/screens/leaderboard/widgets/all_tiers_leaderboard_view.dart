import 'package:flutter/material.dart';
import '../../../game/models/ranked_leaderboard_models.dart';
import '../../../core/models/tier_definitions.dart';

class AllTiersLeaderboardView extends StatefulWidget {
  final Future<Map<int, List<RankedLeaderboardEntry>>> Function() loadTierData;
  final String seasonId;

  const AllTiersLeaderboardView({
    super.key,
    required this.loadTierData,
    required this.seasonId,
  });

  @override
  State<AllTiersLeaderboardView> createState() =>
      _AllTiersLeaderboardViewState();
}

class _AllTiersLeaderboardViewState extends State<AllTiersLeaderboardView> {
  int? _expandedTier;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, List<RankedLeaderboardEntry>>>(
      future: widget.loadTierData(),
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

        final tierData = snapshot.data ?? {};
        if (tierData.isEmpty) {
          return const Center(
            child: Text('No leaderboard data available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tierData.length,
          itemBuilder: (context, index) {
            final tier = tierData.keys.toList()[index];
            final entries = tierData[tier] ?? [];

            return _TierSection(
              tier: tier,
              entries: entries,
              seasonId: widget.seasonId,
              isExpanded: _expandedTier == tier,
              onTap: () {
                setState(() {
                  _expandedTier = _expandedTier == tier ? null : tier;
                });
              },
            );
          },
        );
      },
    );
  }
}

class _TierSection extends StatelessWidget {
  final int tier;
  final List<RankedLeaderboardEntry> entries;
  final String seasonId;
  final bool isExpanded;
  final VoidCallback onTap;

  const _TierSection({
    required this.tier,
    required this.entries,
    required this.seasonId,
    required this.isExpanded,
    required this.onTap,
  });

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return Colors.brown[400]!; // Bronze
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.amber[600]!; // Gold
      case 4:
        return Colors.blue[300]!; // Platinum
      case 5:
        return Colors.lightBlue[300]!; // Diamond
      case 6:
        return Colors.purple[400]!; // Master
      case 7:
        return Colors.deepPurple[400]!; // Grandmaster
      case 8:
        return Colors.pink[400]!; // Ultimate
      default:
        return Colors.grey[600]!;
    }
  }

  String _getTierName(int tier) {
    const names = [
      'Bronze Rookie',
      'Silver Scholar',
      'Gold Master',
      'Platinum Elite',
      'Diamond Legend',
      'Master Sage',
      'Grandmaster',
      'Ultimate Champion',
    ];
    if (tier >= 1 && tier <= 8) {
      return names[tier - 1];
    }
    return 'Tier $tier';
  }

  IconData _getTierIcon(int tier) {
    switch (tier) {
      case 1:
        return Icons.shield; // Bronze
      case 2:
        return Icons.star; // Silver
      case 3:
        return Icons.emoji_events; // Gold
      case 4:
        return Icons.favorite; // Platinum
      case 5:
        return Icons.brightness_7; // Diamond
      case 6:
        return Icons.auto_awesome; // Master
      case 7:
        return Icons.leaderboard; // Grandmaster
      case 8:
        return Icons.verified_user; // Ultimate
      default:
        return Icons.layers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierDef = getTierDefinition(tier);
    final tierColor = tierDef?.primaryColor ?? _getTierColor(tier);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Tier Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tierColor,
                  (tierDef?.secondaryColor ?? tierColor).withValues(alpha: 0.7)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tierDef?.icon ?? _getTierIcon(tier),
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tierDef?.name ?? _getTierName(tier),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                            if (tierDef != null)
                              Text(
                                tierDef.tagline,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              '${entries.length} player${entries.length != 1 ? 's' : ''} • ${tierDef?.xpDisplayFormatted ?? 'XP'}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tier Content
          if (isExpanded)
            Column(
              children: [
                const Divider(height: 0),
                // Rewards display
                if (tierDef != null)
                  Container(
                    color: Colors.amber[50],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.attach_money, color: Colors.orange[700]),
                            const SizedBox(height: 4),
                            Text(
                              '${tierDef.reward.coins}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Coins',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.diamond, color: Colors.blue[700]),
                            const SizedBox(height: 4),
                            Text(
                              '${tierDef.reward.gems}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Gems',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (tierDef.reward.badgeName != null)
                          Column(
                            children: [
                              Icon(Icons.emoji_events,
                                  color: Colors.amber[700]),
                              const SizedBox(height: 4),
                              Text(
                                'Badge',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Unlock',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                const Divider(height: 0),
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No players in this tier yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(0),
                    child: _buildTierEntriesList(context),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTierEntriesList(BuildContext context) {
    final isMobileView = MediaQuery.of(context).size.width < 1000;

    if (isMobileView) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _buildMobileEntry(context, entry, index);
        },
      );
    } else {
      return SizedBox(
        height: (entries.length * 60).clamp(0, 400).toDouble(),
        child: SingleChildScrollView(
          child: Column(
            children: List.generate(
              entries.length,
              (index) => _buildDesktopEntry(context, entries[index], index),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMobileEntry(
    BuildContext context,
    RankedLeaderboardEntry entry,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '#${entry.tierRank}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Player ${entry.playerId.substring(0, 8)}…',
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'RP: ${entry.rankPoints} | W: ${entry.wins} L: ${entry.losses}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopEntry(
    BuildContext context,
    RankedLeaderboardEntry entry,
    int index,
  ) {
    final isEven = index.isEven;
    return Container(
      color: isEven ? Colors.grey[50] : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '#${entry.tierRank}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Player ${entry.playerId.substring(0, 8)}…',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '${entry.rankPoints}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '${entry.wins}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.green[700]),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '${entry.losses}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '${entry.draws}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.amber[700]),
            ),
          ),
        ],
      ),
    );
  }
}
