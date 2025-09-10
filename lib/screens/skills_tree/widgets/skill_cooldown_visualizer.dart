import 'package:flutter/material.dart';
import '../../../game/models/skill_tree_graph.dart';

class SkillCooldownVisualizer extends StatelessWidget {
  final SkillNode node;
  final double size;
  final Duration? remainingOverride;

  const SkillCooldownVisualizer({
    super.key,
    required this.node,
    this.size = 64.0,
    this.remainingOverride,
  });

  double get cooldownProgress {
    if (node.cooldown == null) return 0.0;

    if (remainingOverride != null) {
      final total = node.cooldown!.inMilliseconds.toDouble();
      final rem = remainingOverride!.inMilliseconds.toDouble();
      final done = (total - rem).clamp(0.0, total);
      return (done / total).clamp(0.0, 1.0);
    }

    if (node.lastUsed == null) return 1.0;
    final elapsed = DateTime.now().difference(node.lastUsed!);
    final ratio = elapsed.inMilliseconds / node.cooldown!.inMilliseconds;
    return ratio.clamp(0.0, 1.0);
  }

  bool get isCoolingDown => cooldownProgress < 1.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: cooldownProgress,
            strokeWidth: 5,
            backgroundColor: Colors.grey.shade300,
            color: isCoolingDown ? Colors.orange : Colors.green,
          ),
        ),
        Icon(
          isCoolingDown ? Icons.timer : Icons.flash_on,
          color: isCoolingDown ? Colors.orange : Colors.green,
          size: size * 0.5,
        ),
      ],
    );
  }
}
