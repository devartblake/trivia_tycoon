import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/dto/season_dto.dart';
import '../../core/networking/synaptix_api_client.dart';
import '../../core/networking/http_client.dart' show HttpException;

class SeasonRewardsPreviewScreen extends StatefulWidget {
  final SynaptixApiClient api;
  final String playerId;
  final String? seasonId;

  const SeasonRewardsPreviewScreen({
    super.key,
    required this.api,
    required this.playerId,
    this.seasonId,
  });

  @override
  State<SeasonRewardsPreviewScreen> createState() =>
      _SeasonRewardsPreviewScreenState();
}

class _SeasonRewardsPreviewScreenState
    extends State<SeasonRewardsPreviewScreen> {
  late Future<RewardEligibilityDto> _future;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<RewardEligibilityDto> _load() => widget.api.getSeasonRewardEligibility(
        playerId: widget.playerId,
        seasonId: widget.seasonId,
      );

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _claim(RewardEligibilityDto eligibility) async {
    setState(() => _claiming = true);
    try {
      // Stable per-attempt idempotency key so retries don't double-grant.
      final eventId = const Uuid().v4();
      final result = await widget.api.claimSeasonReward(
        playerId: widget.playerId,
        eventId: eventId,
        seasonId: widget.seasonId ?? eligibility.seasonId,
      );
      if (!mounted) return;
      final msg = switch (result.status) {
        'Applied' =>
          'Claimed ${result.awardedCoins} coins • ${result.awardedXp} XP',
        'Duplicate' => 'Reward already claimed.',
        'NotEligible' => 'Not eligible to claim right now.',
        _ => 'Claim status: ${result.status}',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      _reload();
    } on HttpException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Claim failed: ${e.message}')));
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Season Rewards')),
      body: FutureBuilder<RewardEligibilityDto>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final e = snap.data!;
          final nextClaim = e.nextClaimAtUtc;
          final waiting = nextClaim != null && nextClaim.isAfter(DateTime.now());
          final canClaim = e.eligible && !waiting && !_claiming;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Season: ${e.seasonId}',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Text('Tier ${e.tier} • Rank #${e.tierRank}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(
                      e.eligible
                          ? 'Eligible for rewards'
                          : 'Not eligible (${e.reason})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _rewardChip('XP', e.rewardXp),
                        _rewardChip('Coins', e.rewardCoins),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (waiting)
                      Text(
                        'Next claim available at ${nextClaim.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: canClaim ? () => _claim(e) : null,
                        child: _claiming
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Claim Reward'),
                      ),
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
