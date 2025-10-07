import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/riverpod_providers.dart';

class CreateChallengeButton extends ConsumerWidget {
  final String opponentId;
  final String opponentName;

  const CreateChallengeButton({
    super.key,
    required this.opponentId,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Create challenge using your existing service
        final challengeService = ref.read(challengeCoordinationServiceProvider);
        final challenge = await challengeService.createChallenge(
          challengerId: 'current_user',
          challengerName: 'John Doe',
          opponentId: opponentId,
          opponentName: opponentName,
          category: 'Science',
          questionCount: 10,
          difficulty: 'Medium',
          wager: 50,
        );

        if (challenge != null) {
          // Message is automatically created by the bridge!
          // No additional code needed here

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Challenge sent to $opponentName!')),
            );
          }
        }
      },
      child: const Text('Send Challenge'),
    );
  }
}
