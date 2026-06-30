import 'package:flutter/material.dart';

/// Builds power-up indicators (time boost, shield, XP multiplier)
class PowerUpIndicators extends StatelessWidget {
  final bool isBoostedTime;
  final bool isShielded;
  final int? multiplier;

  const PowerUpIndicators({
    super.key,
    required this.isBoostedTime,
    required this.isShielded,
    required this.multiplier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBoostedTime) ...[
            Icon(Icons.speed, color: Colors.blue.shade600, size: 16),
            const SizedBox(width: 4),
            Text('Time Boost',
                style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
            const SizedBox(width: 8),
          ],
          if (isShielded) ...[
            Icon(Icons.shield, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 4),
            Text('Protected',
                style: TextStyle(color: Colors.green.shade600, fontSize: 12)),
            const SizedBox(width: 8),
          ],
          if (multiplier != null) ...[
            Icon(Icons.close, color: Colors.purple.shade600, size: 16),
            Text('${multiplier}x XP',
                style: TextStyle(color: Colors.purple.shade600, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

/// Builds hint reveal panel
class HintPanel extends StatelessWidget {
  final String hint;

  const HintPanel({
    super.key,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.orange.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Multiplayer indicator badge
class MultiplayerBadge extends StatelessWidget {
  const MultiplayerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          const Text(
            'LIVE MULTIPLAYER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
