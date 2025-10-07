import 'package:flutter/material.dart';
import '../models/challenge_models.dart';

/// Controller for challenge interactions
/// TODO: Hook up with your routing and game flow
class ChallengeController {
  /// Start a challenge
  static Future<void> startChallenge(
      BuildContext context,
      Challenge challenge,
      ) async {
    debugPrint('[ChallengeController] Starting challenge: ${challenge.title}');

    // TODO: Navigate to the proper game mode based on challenge type
    // Example:
    // if (challenge.type == ChallengeType.daily) {
    //   Navigator.push(context, MaterialPageRoute(
    //     builder: (_) => DailyGameScreen(challenge: challenge),
    //   ));
    // }

    // For now, show a placeholder
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting: ${challenge.title}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Claim challenge reward
  static Future<void> claimReward(
      BuildContext context,
      Challenge challenge,
      ) async {
    debugPrint('[ChallengeController] Claiming reward for: ${challenge.title}');

    // TODO: Show reward dialog/bottom sheet
    // Example:
    // await showRewardDialog(context, challenge);

    // For now, show a placeholder
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Claimed: ${challenge.rewardSummary}'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
