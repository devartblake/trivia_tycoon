import 'dart:math';

import 'package:flutter/material.dart';
import 'skill_node_widget.dart';

class SkillTreeLayout extends StatelessWidget {
  const SkillTreeLayout({super.key});

  // Define hex-like axial coordinates and convert to pixels
  Offset hexToPixel(int q, int r, double size) {
    final x = size * (3 / 2 * q);
    final y = size * (sqrt(3) * (r + q / 2));
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    const double nodeSize = 100.0;

    // Dummy hex layout (q, r) coordinates
    final nodes = <Map<String, dynamic>>[
      {'id': 'center', 'label': 'Core', 'q': 0, 'r': 0},
      {'id': 'hint', 'label': 'Faster Hint', 'q': -1, 'r': 0},
      {'id': 'double_hint', 'label': 'Show 2 Hints', 'q': 1, 'r': 0},
      {'id': 'xp1', 'label': 'XP Boost I', 'q': 0, 'r': -1},
      {'id': 'xp2', 'label': 'XP Boost II', 'q': 0, 'r': 1},
      {'id': 'cooldown', 'label': 'Cooldown Cut', 'q': -1, 'r': 1},
      {'id': 'lifeline', 'label': 'Extra Lifeline', 'q': 1, 'r': -1},
    ];

    return Stack(
      children: nodes.map((node) {
        final Offset pos = hexToPixel(node['q'], node['r'], nodeSize) + const Offset(300, 300); // Center offset
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: SkillNodeWidget(
            title: node['label'],
            unlocked: node['id'] == 'center',
            onTap: () => debugPrint('Tapped ${node['id']}'),
          ),
        );
      }).toList(),
    );
  }
}
