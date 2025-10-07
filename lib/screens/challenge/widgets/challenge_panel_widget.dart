import 'package:flutter/material.dart';
import '../../../game/models/challenge_models.dart';
import '../../../game/services/challenge_service.dart';
import '../../../game/utils/date_formatter.dart';
import 'challenge_card_widget.dart';
import 'challenge_countdown_timer.dart';
import 'glass_container_widget.dart';

/// Panel displaying challenges with glass aesthetic
class ChallengePanel extends StatelessWidget {
  final ChallengeType type;

  const ChallengePanel({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final bundle = ChallengeService.getChallenges(type);

    return Column(
      children: [
        _buildCountdownHeader(bundle),
        _buildChallengeList(bundle),
        _buildRefreshFooter(bundle),
      ],
    );
  }

  Widget _buildCountdownHeader(ChallengeBundle bundle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CompactGlassCard(
        tint: const Color(0x44E7F5FF), // Light blue tint
        borderColor: const Color(0x664C6EF5), // Blue border
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x334C6EF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.timer_rounded,
                size: 20,
                color: Color(0xFF4C6EF5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChallengeCountdownTimer(
                target: bundle.refreshTime,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1864AB),
                  fontSize: 14,
                ),
                prefix: _getCountdownPrefix(type),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeList(ChallengeBundle bundle) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: bundle.challenges.length,
        itemBuilder: (context, index) {
          return ChallengeCard(
            challenge: bundle.challenges[index],
          );
        },
      ),
    );
  }

  Widget _buildRefreshFooter(ChallengeBundle bundle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: CompactGlassCard(
        tint: const Color(0x33FFFFFF),
        borderColor: const Color(0x55FFFFFF),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 18,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              'Next refresh: ${DateFormatter.formatDateTime(bundle.refreshTime)}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCountdownPrefix(ChallengeType type) {
    return switch (type) {
      ChallengeType.daily => 'Daily refresh in ',
      ChallengeType.weekly => 'Weekly refresh in ',
      ChallengeType.special => 'Event ends in ',
    };
  }
}
