import 'package:flutter/material.dart';

/// **🎨 Represents a collection of colors as a palette**
class ColorPalette {
  final String name;
  final List<Color> colors;

  ColorPalette({
    required this.name,
    required this.colors,
  });

  /// **🔄 Creates a copy with updated values**
  ColorPalette copyWith({String? name, List<Color>? colors}) {
    return ColorPalette(
      name: name ?? this.name,
      colors: colors ?? List.from(this.colors),
    );
  }

  /// **📌 Convert Palette to Map (for storage)**
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'colors': colors.map((color) => color.value).toList(),
    };
  }

  /// **📥 Create Palette from Map (for retrieval)**
  factory ColorPalette.fromMap(Map<String, dynamic> map) {
    return ColorPalette(
      name: map['name'] ?? "Unnamed Palette",
      colors: (map['colors'] as List).map((c) => Color(c)).toList(),
    );
  }
}
