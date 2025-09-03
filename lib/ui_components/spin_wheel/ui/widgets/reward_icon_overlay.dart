import 'package:flutter/material.dart';
import '../../models/wheel_segment.dart';

class RewardIconOverlay extends StatelessWidget {
  final WheelSegment segment;

  const RewardIconOverlay({super.key, required this.segment});

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    switch (segment.rewardType) {
      case 'jackpot':
        icon = Icons.star;
        break;
      case 'large':
        icon = Icons.gif_box;
        break;
      case 'medium':
        icon = Icons.bolt;
        break;
      case 'small':
        icon = Icons.catching_pokemon;
        break;
      default:
        icon = Icons.redeem;
    }

    return Positioned(
      top: 4,
      right: 4,
      child: Icon(
        icon,
        size: 16,
        color: Colors.yellowAccent,
      ),
    );
  }
}