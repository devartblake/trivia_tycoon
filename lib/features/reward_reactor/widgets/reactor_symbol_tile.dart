import 'package:flutter/material.dart';

class ReactorSymbolTile extends StatelessWidget {
  final String symbolKey;
  final bool isWinning;

  const ReactorSymbolTile({
    super.key,
    required this.symbolKey,
    this.isWinning = false,
  });

  static const Map<String, String> _symbolEmoji = {
    'coin': '🪙',
    'gem': '💎',
    'star': '⭐',
    'crown': '👑',
    'bolt': '⚡',
    'shield': '🛡️',
    'trophy': '🏆',
    'gift': '🎁',
  };

  String get _emoji => _symbolEmoji[symbolKey] ?? '🎰';

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isWinning
            ? const Color(0xFF2A1F5C)
            : const Color(0xFF1A1040),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinning
              ? const Color(0xFFFFD700)
              : const Color(0xFF3D2E7C),
          width: isWinning ? 2 : 1,
        ),
        boxShadow: isWinning
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          _emoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
