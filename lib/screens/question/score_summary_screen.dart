import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ui_components/confetti/confetti.dart';
import '../../ui_components/confetti/core/presets/confetti_presets.dart';

class ScoreSummaryScreen extends StatelessWidget {
  final int score;
  final int money;
  final int diamonds;

  const ScoreSummaryScreen({
    super.key,
    required this.score,
    required this.money,
    required this.diamonds,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Your Results"),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //Lottie.asset('assets/animations/celebration.json', width: 200),
                const SizedBox(height: 16),
                Text(
                  "🎉 Great Job!",
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildAnimatedStat("Score", score, Colors.deepPurple),
                _buildAnimatedStat("Money", money, Colors.green),
                _buildAnimatedStat("Diamonds", diamonds, Colors.blue),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: const Text("Back to Home"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                )
              ],
            ),
          ),
        ),
        ConfettiWidget(controller: ConfettiController(),
            theme: ConfettiPresets.celebration),
      ],
    );
  }

  Widget _buildAnimatedStat(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: value),
        duration: const Duration(seconds: 2),
        builder: (context, val, _) {
          return Column(
            children: [
              Text(
                val.toString(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 16)),
            ],
          );
        },
      ),
    );
  }
}
