import 'package:flutter/material.dart';

class RewardSection extends StatelessWidget {
  final int coins;
  final int diamonds;

  const RewardSection({super.key, required this.coins, required this.diamonds});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRewardItem(Icons.monetization_on, coins, Colors.yellow),
          SizedBox(width: 20),
          _buildRewardItem(Icons.diamond, diamonds, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildRewardItem(IconData icon, int amount, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(width: 5),
        Text(
          amount.toString(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
