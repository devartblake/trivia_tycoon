import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/reactor_reward_preview.dart';

class ReactorRewardBanner extends StatelessWidget {
  final ReactorRewardPreview preview;
  final String? eventId;
  final double? eventMultiplier;
  final bool isChainBonus;

  const ReactorRewardBanner({
    super.key,
    required this.preview,
    this.eventId,
    this.eventMultiplier,
    this.isChainBonus = false,
  });

  static const Map<String, String> _typeEmoji = {
    'coins': '🪙',
    'gems': '💎',
    'xp': '⭐',
    'item': '🎁',
    'premium': '👑',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1F5C), Color(0xFF1A1040)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isChainBonus || eventId != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (isChainBonus)
                  _Badge(
                    label: 'CHAIN BONUS',
                    color: const Color(0xFF00E5FF),
                  ),
                if (eventId != null)
                  _Badge(
                    label: eventMultiplier != null
                        ? '${eventMultiplier!.toStringAsFixed(eventMultiplier! % 1 == 0 ? 0 : 1)}x EVENT'
                        : 'LIVE EVENT',
                    color: const Color(0xFFFF8A00),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            preview.displayName,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          ...preview.lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      _typeEmoji[line.type] ?? '🎁',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
