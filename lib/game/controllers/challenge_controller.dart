import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/challenge_models.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Controller for challenge interactions — wired to GoRouter and reward dialog.
class ChallengeController {
  /// Start a challenge by routing to the matching game mode.
  static Future<void> startChallenge(
    BuildContext context,
    Challenge challenge,
  ) async {
    LogManager.debug(
        '[ChallengeController] Starting challenge: ${challenge.title}');

    if (!context.mounted) return;

    switch (challenge.type) {
      case ChallengeType.daily:
        context.push('/daily-quiz');
      case ChallengeType.weekly:
        // Weekly challenges use the standard quiz flow with classic mode.
        context.push('/quiz/start/classic');
      case ChallengeType.special:
        // Special/event challenges open the multiplayer arena mode.
        context.push('/multiplayer/quiz/arena');
    }
  }

  /// Claim a completed challenge reward — shows a reward bottom sheet.
  static Future<void> claimReward(
    BuildContext context,
    Challenge challenge,
  ) async {
    LogManager.debug(
        '[ChallengeController] Claiming reward for: ${challenge.title}');

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RewardSheet(challenge: challenge),
    );
  }
}

class _RewardSheet extends StatelessWidget {
  final Challenge challenge;

  const _RewardSheet({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Trophy icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),

          Text(
            'Challenge Complete!',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Text(
            challenge.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Reward summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.card_giftcard,
                    color: Colors.amber.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    challenge.rewardSummary,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Claim Reward', fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
