import 'package:flutter/material.dart';
import '../../core/networking/synaptix_api_client.dart';
import '../../game/models/season_reward_preview_models.dart';

class SeasonRewardsPreviewScreen extends StatelessWidget {
  final SynaptixApiClient api;
  final String playerId;
  final String? seasonId;

  const SeasonRewardsPreviewScreen({
    super.key,
    required this.api,
    required this.playerId,
    this.seasonId,
  });

  Future<SeasonRewardPreview> _load() async {
    final json = await api.getJson(
      '/seasons/rewards/preview/$playerId',
      query: { if (seasonId != null) 'seasonId': seasonId! },
    );
    return SeasonRewardPreview.fromJson(json);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Season Rewards Preview')),
      body: FutureBuilder<SeasonRewardPreview>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final p = snap.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Season: ${p.seasonId}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Text('Tier ${p.tier} • Rank #${p.tierRank}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(
                      p.eligible ? 'Eligible for rewards' : 'Not eligible for rewards',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _rewardChip('XP', p.rewardXp),
                        _rewardChip('Coins', p.rewardCoins),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This is a preview. Rewards are distributed automatically at season close.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rewardChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(width: 1),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 14)),
    );
  }
}
