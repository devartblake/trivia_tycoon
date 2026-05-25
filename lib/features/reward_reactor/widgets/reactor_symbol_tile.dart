import 'package:flutter/material.dart';

class ReactorSymbolTile extends StatelessWidget {
  final String symbolKey;
  final bool isWinning;
  final String? seasonKey;

  const ReactorSymbolTile({
    super.key,
    required this.symbolKey,
    this.isWinning = false,
    this.seasonKey,
  });

  static const Map<String, String> _symbolGlyphs = {
    'coin': '\u{1FA99}',
    'gem': '\u{1F48E}',
    'star': '\u{2B50}',
    'crown': '\u{1F451}',
    'bolt': '\u{26A1}',
    'shield': '\u{1F6E1}',
    'trophy': '\u{1F3C6}',
    'gift': '\u{1F381}',
  };

  static const Map<String, Map<String, String>> _seasonGlyphs = {
    'halloween': {
      'coin': '\u{1F383}',
      'gem': '\u{1F987}',
      'star': '\u{1F480}',
      'gift': '\u{1F36C}',
    },
    'winter': {
      'coin': '\u{2744}',
      'gem': '\u{1F9CA}',
      'star': '\u{2B50}',
      'gift': '\u{1F381}',
    },
    'spring': {
      'coin': '\u{1F33C}',
      'gem': '\u{1F343}',
      'star': '\u{2600}',
      'gift': '\u{1F331}',
    },
  };

  String get _glyph {
    final season = seasonKey?.split('_').first;
    final seasonSymbols = _seasonGlyphs[season];
    return seasonSymbols?[symbolKey] ?? _symbolGlyphs[symbolKey] ?? '?';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isWinning ? const Color(0xFF2A1F5C) : const Color(0xFF1A1040),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinning ? const Color(0xFFFFD700) : const Color(0xFF3D2E7C),
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
          _glyph,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
