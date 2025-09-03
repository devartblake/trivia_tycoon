import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/ui/widgets/animations/reward_glow_animation.dart';
import '../../models/spin_result.dart';
import 'coin/coin_balance_display.dart';
import 'coin/coin_gain_animation.dart';

class ResultDialog extends StatefulWidget {
  final SpinResult result;

  const ResultDialog({required this.result, super.key});

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return AlertDialog(
      title: Text("Congratulations!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (result.imagePath != null)
            RewardGlowAnimation(
              trigger: true,
              child: Image.asset(
                result.imagePath!,
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              ),
            ),
          const SizedBox(height: 10),
          Text(result.label, style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
        ],
      ),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                const CoinBalanceDisplay(),
                Positioned(
                  top: 0,
                  right: 0,
                  child: CoinGainAnimation(amount: result.reward),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      ],
    );
  }
}
