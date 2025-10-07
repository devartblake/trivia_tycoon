import 'package:flutter/material.dart';
import '../../../game/controllers/challenge_controller.dart';
import '../../../game/models/challenge_models.dart';
import 'glass_container_widget.dart';

/// Glass-style expandable challenge card
class ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const ChallengeCard({
    super.key,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = challenge.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassExpansionCard(
        tint: const Color(0x33FFFFFF),
        borderColor: const Color(0x55FFFFFF),
        expandedTint: const Color(0x44FFFFFF),
        borderRadius: 20,
        initiallyExpanded: false,
        dense: false,
        leading: _buildLeadingIcon(theme),
        title: _buildTitle(),
        subtitle: _buildSubtitle(),
        trailing: completed ? _buildCompletedBadge() : null,
        onExpansionChanged: (expanded) {
          // Optional: Add haptic feedback or analytics
        },
        children: [
          // Expanded content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDescription(),
              const SizedBox(height: 16),
              _buildRewardRow(),
              const SizedBox(height: 16),
              _buildProgressBar(theme, completed),
              const SizedBox(height: 16),
              _buildActionButton(context, theme, completed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        challenge.icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      challenge.title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF212529),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      _getCategoryBadge(challenge.type),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _getCategoryColor(challenge.type),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x3310B981),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x5510B981),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: Color(0xFF059669),
          ),
          SizedBox(width: 4),
          Text(
            'Done',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      challenge.description,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF495057),
        height: 1.5,
      ),
    );
  }

  Widget _buildRewardRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF4E6).withOpacity(0.9),
            const Color(0xFFFFE8CC).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x88FFD8A8),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0x33FD7E14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              size: 18,
              color: Color(0xFFF76707),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rewards',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  challenge.rewardSummary,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8590C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, bool completed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF495057),
              ),
            ),
            Text(
              '${(challenge.progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: completed
                    ? const Color(0xFF10B981)
                    : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: challenge.progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: const Color(0x22000000),
              valueColor: AlwaysStoppedAnimation<Color>(
                completed
                    ? const Color(0xFF10B981)
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, ThemeData theme, bool completed) {
    return SizedBox(
      width: double.infinity,
      child: completed
          ? _buildClaimButton(context, theme)
          : _buildPlayButton(context, theme),
    );
  }

  Widget _buildPlayButton(BuildContext context, ThemeData theme) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 2,
        shadowColor: theme.colorScheme.primary.withOpacity(0.3),
      ),
      icon: const Icon(Icons.play_arrow_rounded, size: 22),
      label: const Text(
        'Start Challenge',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      onPressed: () => ChallengeController.startChallenge(context, challenge),
    );
  }

  Widget _buildClaimButton(BuildContext context, ThemeData theme) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 2,
        shadowColor: const Color(0x4410B981),
      ),
      icon: const Icon(Icons.emoji_events_rounded, size: 22),
      label: const Text(
        'Claim Reward',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      onPressed: () => ChallengeController.claimReward(context, challenge),
    );
  }

  String _getCategoryBadge(ChallengeType type) {
    return switch (type) {
      ChallengeType.daily => 'DAILY CHALLENGE',
      ChallengeType.weekly => 'WEEKLY CHALLENGE',
      ChallengeType.special => 'SPECIAL EVENT',
    };
  }

  Color _getCategoryColor(ChallengeType type) {
    return switch (type) {
      ChallengeType.daily => const Color(0xFF4C6EF5),
      ChallengeType.weekly => const Color(0xFF7950F2),
      ChallengeType.special => const Color(0xFFF76707),
    };
  }
}
