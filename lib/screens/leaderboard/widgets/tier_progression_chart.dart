import 'package:flutter/material.dart';
import '../../../core/models/tier_definitions.dart';

class TierProgressionChart extends StatefulWidget {
  final int? currentTier;
  final int? currentXp;
  final bool showXpDetails;

  const TierProgressionChart({
    super.key,
    this.currentTier,
    this.currentXp,
    this.showXpDetails = true,
  });

  @override
  State<TierProgressionChart> createState() => _TierProgressionChartState();
}

class _TierProgressionChartState extends State<TierProgressionChart> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Scroll to current tier if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.currentTier != null) {
        _scrollToCurrentTier();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTier() {
    final currentTier = widget.currentTier ?? 1;
    final targetOffset = (currentTier - 1) * 200.0; // Each tier card ~200px
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiers = getAllTierDefinitions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tier Progression Path',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (widget.currentTier != null) ...[
                const SizedBox(height: 8),
                Text(
                  'You are currently: ${tiers[widget.currentTier! - 1].name}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Tier progression cards
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: List.generate(
              tiers.length,
              (index) {
                final tier = tiers[index];
                final isCurrent = widget.currentTier == tier.tier;
                final isPassed = widget.currentTier != null &&
                    widget.currentTier! > tier.tier;

                return _TierCard(
                  tier: tier,
                  isCurrent: isCurrent,
                  isPassed: isPassed,
                  currentXp: widget.currentXp,
                  showXpDetails: widget.showXpDetails,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                'Current',
                Colors.blue,
              ),
              _buildLegendItem(
                'Completed',
                Colors.green,
              ),
              _buildLegendItem(
                'Locked',
                Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  final TierDefinition tier;
  final bool isCurrent;
  final bool isPassed;
  final int? currentXp;
  final bool showXpDetails;

  const _TierCard({
    required this.tier,
    required this.isCurrent,
    required this.isPassed,
    this.currentXp,
    required this.showXpDetails,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = isPassed || isCurrent ? 1.0 : 0.6;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      child: Card(
        elevation: isCurrent ? 8 : 2,
        shadowColor: isCurrent ? Colors.blue.withValues(alpha: 0.5) : Colors.grey,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isCurrent
                ? Border.all(color: Colors.blue, width: 2)
                : null,
          ),
          child: Column(
            children: [
              // Header with status indicator
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tier.primaryColor.withValues(alpha: opacity),
                      tier.secondaryColor.withValues(alpha: opacity),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isPassed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'LOCKED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Icon(
                      tier.icon,
                      size: 32,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ),
              // Tier content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tier number and name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tier ${tier.tier}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            tier.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tier.tagline,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // XP requirement
                      if (showXpDetails)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                tier.xpDisplayFormatted,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Rewards
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                                Text(
                                  '${tier.reward.coins}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.diamond,
                                  size: 12,
                                  color: Colors.blue,
                                ),
                                Text(
                                  '${tier.reward.gems}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
