import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/controllers/trivia_transition_controller.dart';
import 'package:trivia_tycoon/core/widgets/shimmer_card.dart';

class TriviaTransitionScreen extends ConsumerWidget {
  const TriviaTransitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(triviaTransitionControllerProvider);
    final secondsLeft = ref.watch(triviaTransitionControllerProvider.select(
          (c) => c.secondsRemaining,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: secondsLeft > 0
                    ? CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.amber,
                  child: Text(
                    '$secondsLeft',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                )
                    : ElevatedButton(
                  onPressed: () => controller.navigateToNext(context),
                  child: const Text('Next'),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Trivia Tycoon',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  ShimmerCard(width: 240, height: 120),
                  SizedBox(height: 12),
                  ShimmerCard(width: 200, height: 80),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
