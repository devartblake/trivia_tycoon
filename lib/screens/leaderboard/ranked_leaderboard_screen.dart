import 'package:flutter/material.dart';
import '../../core/networkting/tycoon_api_client.dart';
import '../../game/models/ranked_leaderboard_models.dart';

class RankedLeaderboardScreen extends StatefulWidget {
  final TycoonApiClient api;
  final String? seasonId;

  const RankedLeaderboardScreen({super.key, required this.api, this.seasonId});

  @override
  State<RankedLeaderboardScreen> createState() => _RankedLeaderboardScreenState();
}

class _RankedLeaderboardScreenState extends State<RankedLeaderboardScreen> {
  int _tier = 1;
  int _page = 1;
  static const _pageSize = 50;

  Future<RankedLeaderboardResponse> _load() async {
    final json = await widget.api.getJson(
      '/leaderboards/ranked',
      query: {
        if (widget.seasonId != null) 'seasonId': widget.seasonId!,
        'tier': '$_tier',
        'page': '$_page',
        'pageSize': '$_pageSize',
      },
    );
    return RankedLeaderboardResponse.fromJson(json);
  }

  @override
  Widget build(BuildContext context) {
    final tiers = List<int>.generate(10, (i) => i + 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranked Leaderboard'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                final t = tiers[i];
                final selected = t == _tier;
                return ChoiceChip(
                  label: Text('Tier $t'),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _tier = t;
                    _page = 1;
                  }),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: tiers.length,
            ),
          ),
          Expanded(
            child: FutureBuilder<RankedLeaderboardResponse>(
              future: _load(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final data = snap.data!;
                final items = data.items;

                // Grid-friendly: uses SliverGrid on wide screens, list on narrow.
                final width = MediaQuery.of(context).size.width;
                final isWide = width >= 700;
                final crossAxisCount = isWide ? 2 : 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Text('Season: ${data.seasonId}', style: Theme.of(context).textTheme.bodySmall),
                          const Spacer(),
                          Text('Total: ${data.total}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: isWide ? 2.6 : 3.2,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, idx) => _RankCard(e: items[idx]),
                      ),
                    ),
                    _Pager(
                      page: data.page,
                      pageSize: data.pageSize,
                      total: data.total,
                      onPrev: data.page > 1
                          ? () => setState(() => _page--)
                          : null,
                      onNext: (data.page * data.pageSize) < data.total
                          ? () => setState(() => _page++)
                          : null,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final RankedLeaderboardEntry e;
  const _RankCard({required this.e});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${e.tierRank}', style: Theme.of(context).textTheme.titleMedium),
                  Text('Tier ${e.tier}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Player ${e.playerId.substring(0, 8)}…',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _pill('RP', '${e.rankPoints}'),
                      _pill('W', '${e.wins}'),
                      _pill('L', '${e.losses}'),
                      _pill('D', '${e.draws}'),
                      _pill('M', '${e.matchesPlayed}'),
                      _pill('Global', '${e.seasonRank}'),
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

  Widget _pill(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(width: 1),
      ),
      child: Text('$k: $v', style: const TextStyle(fontSize: 12)),
    );
  }
}

class _Pager extends StatelessWidget {
  final int page;
  final int pageSize;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _Pager({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final from = ((page - 1) * pageSize) + 1;
    final to = (page * pageSize).clamp(1, total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Text('$from–$to of $total', style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          TextButton(onPressed: onPrev, child: const Text('Prev')),
          const SizedBox(width: 8),
          TextButton(onPressed: onNext, child: const Text('Next')),
        ],
      ),
    );
  }
}
