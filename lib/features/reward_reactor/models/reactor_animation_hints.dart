class ReactorAnimationHints {
  final String layout;
  final List<String> symbols;
  final List<int> winningSymbolIndexes;
  final String rarity;
  final String intensity;

  const ReactorAnimationHints({
    required this.layout,
    required this.symbols,
    required this.winningSymbolIndexes,
    required this.rarity,
    required this.intensity,
  });

  factory ReactorAnimationHints.fromJson(Map<String, dynamic> json) {
    return ReactorAnimationHints(
      layout: json['layout']?.toString() ?? 'reel3',
      symbols: (json['symbols'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      winningSymbolIndexes: (json['winningSymbolIndexes'] as List? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      rarity: json['rarity']?.toString() ?? 'common',
      intensity: json['intensity']?.toString() ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
        'layout': layout,
        'symbols': symbols,
        'winningSymbolIndexes': winningSymbolIndexes,
        'rarity': rarity,
        'intensity': intensity,
      };
}
