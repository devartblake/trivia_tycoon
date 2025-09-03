import 'package:flutter/material.dart';
import '../core/confetti_theme.dart';
import 'confetti_shape.dart';

int version = 2;

class ConfettiSettings {
  String name;
  double density;
  double speed;
  double gravity;
  double wind;
  List<String> images;
  List<Color> colors;
  List<ConfettiShapeType> shapes;
  bool enableGravity;
  bool enableRotation;
  bool useImages;
  int schemaVersion;

  ConfettiSettings({
    this.name = "",
    this.density = 100,
    this.speed = 1.0,
    this.gravity = 0.0,
    this.wind = 0.0,
    this.images = const [],
    this.colors = const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
    this.shapes = const [ConfettiShapeType.circle, ConfettiShapeType.square, ConfettiShapeType.triangle],
    this.enableGravity = true,
    this.enableRotation = true,
    this.useImages = false,
    this.schemaVersion = 2,
  });

  /// Returns a copy of the settings with optional modifications.
  ConfettiSettings copyWith({
    String? name,
    double? density,
    double? speed,
    double? gravity,
    double? wind,
    List<String>? images,
    List<Color>? colors,
    List<ConfettiShapeType>? shapes,
    bool? enableGravity,
    bool? enableRotation,
    bool? useImages,
  }) {
    return ConfettiSettings(
      name: name ?? this.name,
      density: density ?? this.density,
      speed: speed ?? this.speed,
      gravity: gravity ?? this.gravity,
      wind: wind ?? this.wind,
      images: images ?? this.images,
      colors: colors ?? List.from(this.colors),
      shapes: shapes ?? List.from(this.shapes),
      enableGravity: enableGravity ?? this.enableGravity,
      enableRotation: enableRotation ?? this.enableRotation,
      useImages: useImages ?? this.useImages,
    );
  }

  /// ✅ Converts settings to a serializable map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'wind': wind,
      'speed': speed,
      'density': density,
      'gravity': gravity,
      'images': images,
      'colors': colors.map((c) => c.value).toList(),
      'shapes': shapes.map((s) => s.index).toList(),
      'enableGravity': enableGravity,
      'enableRotation': enableRotation,
      'useImages': useImages,
      'schemaVersion': schemaVersion,
    };
  }

  /// ✅ Creates settings from a map
  factory ConfettiSettings.fromMap(Map<String, dynamic> map) {
    final int version = map['schemaVersion'] ?? 1;

    if (version == 1) {
      // Migrate from version 1 to 2
      return ConfettiSettings(
        name: 'Migrated Theme',
        colors: (map['colors'] as List).map((c) => Color(c)).toList(),
        shapes: (map['shapes'] as List).map((s) => ConfettiShapeType.values.firstWhere(
              (e) => e.toString().split('.').last == s,
          orElse: () => ConfettiShapeType.circle, // Fallback to circle
        )).toList(),
        speed: map['speed'],
        density: map['density'],
        enableGravity: true,
        enableRotation: true,
        useImages: true,
        gravity: 0.1,
        wind: 0.0,
        schemaVersion: 2,
      );
    }

    // Default parsing for latest version
      return ConfettiSettings(
        name: map['name'] ?? 'Untitled',
        density: map['density'] ?? 100,
        speed: map['speed'] ?? 3.0,
        gravity: map['gravity'] ?? 0.0,
        wind: map['wind'] ?? 0.0,
        colors: (map['colors'] as List).map((c) => Color(c)).toList(),
        shapes: (map['shapes'] as List)
            .map((s) => ConfettiShapeType.values[s])
            .toList(),
        enableGravity: map['enableGravity'] ?? true,
        enableRotation: map['enableRotation'] ?? true,
        useImages: map['useImages'] ?? false,
      );
    }

  /// Create settings from a "ConfettiTheme'
  factory ConfettiSettings.fromTheme(ConfettiTheme theme) {
    return ConfettiSettings(
      colors: theme.colors,
      shapes: theme.shapes,
      speed: theme.speed,
      gravity: theme.gravity,
      wind: theme.wind,
      density: theme.density.toDouble(),
    );
  }
}