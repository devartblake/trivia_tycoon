import 'package:flutter/material.dart';

import '../../../game/models/leaderboard_entry.dart';
import '../../leaderboard/widgets/shimmer_avatar.dart';

class LeaderboardSwipeCard extends StatelessWidget {
  final String playerName;
  final int score;
  final LeaderboardEntry entry;
  final VoidCallback onPromote;
  final VoidCallback onBan;

  const LeaderboardSwipeCard({
    super.key,
    required this.playerName,
    required this.score,
    required this.entry,
    required this.onPromote,
    required this.onBan,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(playerName),
      background: _buildSwipeBackground(
        color: Colors.green,
        icon: Icons.star,
        label: 'Promote',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: Colors.red,
        icon: Icons.block,
        label: 'Ban',
        alignment: Alignment.centerRight,
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onPromote();
        } else if (direction == DismissDirection.endToStart) {
          onBan();
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: ShimmerAvatar(
            avatarPath: entry.avatar,
            initials: (entry.playerName.isNotEmpty)
                ? entry.playerName[0].toUpperCase()
                : '?',
            ageGroup: entry.ageGroup,
            gender: entry.gender,
            radius: 24,
            xpProgress: entry.xpProgress,
            status: entry.status,
          ),
          title: Text(playerName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Score: ${entry.score}"),
              const SizedBox(height: 4),
              _buildTierText(
                tier: entry.tier,
                tierRank: entry.tierRank,
                isPromotionEligible: entry.isPromotionEligible,
                isRewardEligible: entry.isRewardEligible,
              ),
            ],
          ),
          trailing: entry.isPromotionEligible
              ? const Icon(Icons.verified, color: Colors.blueGrey)
              : null,
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: alignment == Alignment.centerLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTierText({
    required int tier,
    required int tierRank,
    required bool isPromotionEligible,
    required bool isRewardEligible,
  }) {
    final tierName = _getTierName(tier);
    final rankText = "Tier: $tierName • Tier Rank: $tierRank/100";

    return Row(
      children: [
        if (isPromotionEligible)
          Container(
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Colors.amber,
                  blurRadius: 8,
                  spreadRadius: 1.5,
                )
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              rankText,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          )
        else
          Text(
            rankText,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        const SizedBox(width: 6),
        if (isRewardEligible)
          const Icon(Icons.emoji_events, color: Colors.orangeAccent, size: 18),
      ],
    );
  }

  String _getTierName(int tier) {
    const names = [
      'Unranked',
      'Bronze League',
      'Silver League',
      'Gold League',
      'Platinum League',
      'Diamond League',
      'Master League',
      'Grandmaster',
      'Champion Circle',
      'Elite Division',
      'Tycoon Hall',
    ];
    return tier > 0 && tier < names.length ? names[tier] : 'Unknown';
  }
}