import 'package:flutter/material.dart';
import '../../core/models/tier_definitions.dart';
import 'widgets/tier_progression_chart.dart';

/// Showcase screen for the tier progression system
/// Displays the complete tier hierarchy with XP requirements and rewards
class TierProgressionShowcaseScreen extends StatefulWidget {
  final int? userCurrentTier;
  final int? userCurrentXp;

  const TierProgressionShowcaseScreen({
    super.key,
    this.userCurrentTier,
    this.userCurrentXp,
  });

  @override
  State<TierProgressionShowcaseScreen> createState() =>
      _TierProgressionShowcaseScreenState();
}

class _TierProgressionShowcaseScreenState
    extends State<TierProgressionShowcaseScreen> {
  late int _selectedTier;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.userCurrentTier ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final tiers = getAllTierDefinitions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tier Progression System'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tier Progression Path',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete the tier system to unlock rewards and advance your rank',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Tier progression chart
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: TierProgressionChart(
                currentTier: widget.userCurrentTier,
                currentXp: widget.userCurrentXp,
                showXpDetails: true,
              ),
            ),

            // Detailed tier information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tier Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  // Tier selector
                  SegmentedButton<int>(
                    segments: List.generate(
                      10,
                      (i) => ButtonSegment(
                        value: i + 1,
                        label: Text('Tier ${i + 1}'),
                      ),
                    ),
                    selected: {_selectedTier},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() => _selectedTier = newSelection.first);
                    },
                  ),
                ],
              ),
            ),

            // Selected tier detail card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTierDetailCard(
                context,
                tiers[_selectedTier - 1],
              ),
            ),

            // All tiers overview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Tiers Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tiers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tier = tiers[index];
                      return _buildTierRow(context, tier);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTierDetailCard(BuildContext context, TierDefinition tier) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tier.primaryColor,
              tier.secondaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tier header
            Row(
              children: [
                Icon(
                  tier.icon,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tier.tagline,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // XP requirement
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'XP Required',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        tier.xpDisplayFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (tier.tier < 10)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Next Tier',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          getAllTierDefinitions()[tier.tier].xpDisplayFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Rewards
            Text(
              'Rewards on Achievement:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRewardItem(
                  'Coins',
                  '${tier.reward.coins}',
                  Icons.attach_money,
                  Colors.orange,
                ),
                _buildRewardItem(
                  'Gems',
                  '${tier.reward.gems}',
                  Icons.diamond,
                  Colors.blue,
                ),
                if (tier.reward.badgeName != null)
                  _buildRewardItem(
                    'Badge',
                    tier.reward.badgeName!.split(' ').first,
                    Icons.emoji_events,
                    Colors.amber,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTierRow(BuildContext context, TierDefinition tier) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: tier.primaryColor,
            width: 4,
          ),
        ),
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            tier.icon,
            color: tier.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  tier.tagline,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tier.xpDisplayFormatted,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_money, size: 14, color: Colors.orange),
                  Text(
                    '${tier.reward.coins}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.diamond, size: 14, color: Colors.blue),
                  Text(
                    '${tier.reward.gems}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
