import 'package:flutter/material.dart';
import '../models/confetti_settings.dart';
import '../models/confetti_shape.dart';
import '../core/presets/confetti_preset_images.dart';

class ConfettiTheme {
  final String name;
  final List<Color> colors;
  final List<ConfettiShapeType> shapes;
  final List<String> images;
  final double speed;
  final int density;
  final bool useImages;
  final double gravity;
  final double wind;

  ConfettiTheme({
    required this.name,
    required this.colors,
    required this.shapes,
    required this.useImages,
    this.images = const [],
    this.speed = 1.0,
    this.density = 30,
    this.gravity = 0.1,
    this.wind = 0.0,
  });

  /// Getter for preview image.
  String get previewImage => images.isNotEmpty
      ? images.first
      : 'assets/default_preview.png';

  /// **🔄 Updated copyWith method**
  ConfettiTheme copyWith({
    String? name,
    List<Color>? colors,
    List<ConfettiShapeType>? shapes,
    List<String>? images,
    double? speed,
    int? density,
    double? gravity,
    double? wind,
    bool? useImages,
  }) {
    return ConfettiTheme(
      name: name ?? this.name,
      colors: colors ??  this.colors,
      shapes: shapes ?? this.shapes,
      images: images ?? this.images,
      speed: speed ?? this.speed,
      density: density ?? this.density,
      gravity: gravity ?? this.gravity,
      wind: wind ?? this.wind,
      useImages: useImages ?? this.useImages,
    );
  }

  /// ** Enables you to convert a selected theme into a settings. **
  ConfettiSettings toSettings() {
    return ConfettiSettings(
      colors: colors,
      shapes: shapes,
      images: images,
      speed: speed,
      density: density.toDouble(),
      gravity: gravity,
      wind: wind,
      useImages: useImages,
    );
  }

  /// ** Ensures themes and settings stay in sync when customizing, preview,or persisting changes. **
  factory ConfettiTheme.fromSettings(ConfettiSettings settings, {String name = 'Custom'}) {
    return ConfettiTheme(
      name: settings.name.isEmpty ? _generateNameFromSettings(settings) : settings.name,
      colors: settings.colors,
      shapes: settings.shapes,
      images: settings.images,
      speed: settings.speed,
      density: settings.density.toInt(),
      gravity: settings.gravity,
      wind: settings.wind,
      useImages: settings.useImages,
    );
  }

  /// * Auto-generate theme name from settings
  static String _generateNameFromSettings(ConfettiSettings s) {
    final colorsHash = s.colors.map((c) => c.value.toRadixString(16)).join("-");
    final gravityLabel = s.gravity > 0.2 ? "Heavy" : "Light";
    final speedLabel = s.speed > 2.0 ? "Fast" : s.speed < 1.0 ? "Slow" : "Normal";
    return "${speedLabel}_${gravityLabel}_${s.useImages ? "Images" : "Basic"}_${colorsHash.substring(0, 6)}";
  }

  /// **🌈 Handle color updates dynamically**
  ConfettiTheme updateColors(List<Color> newColors) {
    return copyWith(colors: newColors);
  }

  static ConfettiTheme getRandomTheme() {
    return presets[(DateTime.now().millisecondsSinceEpoch % presets.length)];
  }

  /// **🔥 Predefined Preset Themes**
  static final List<ConfettiTheme> presets = [
    ConfettiTheme(
      name: "Fireworks",
      colors: [Colors.red, Colors.yellow, Colors.orange],
      shapes: [
        ConfettiShapeType.circle,
        ConfettiShapeType.square,
        ConfettiShapeType.triangle,
        ConfettiShapeType.star,
      ],
      images: [],
      speed: 2.0,
      density: 50,
      gravity: 0.3,
      wind: 0.2,
      useImages: true,
    ),
    ConfettiTheme(
      name: "Snowfall",
      colors: [Colors.white, Colors.blueGrey],
      shapes: [ConfettiShapeType.circle],
      images: [ConfettiPresetImages.snowFlake],
      speed: 0.5,
      density: 20,
      gravity: 0.05,
      wind: 0.1,
      useImages: true,
    ),
    ConfettiTheme(
      name: "Rainbow",
      colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple],
      shapes: [ConfettiShapeType.circle],
      images: [],
      speed: 1.5,
      density: 40,
      gravity: 0.2,
      wind: 0.3,
      useImages: true,
    ),
    ConfettiTheme(
      name: "Heart",
      colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple],
      shapes: [],
      images: [ConfettiPresetImages.heart],
      speed: 1.5,
      density: 40,
      gravity: 0.2,
      wind: 0.3,
      useImages: true,
    ),
    ConfettiTheme(
      name: "star",
      colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple],
      shapes: [],
      images: [ConfettiPresetImages.star],
      speed: 1.5,
      density: 40,
      gravity: 0.2,
      wind: 0.3,
      useImages: true,
    ),
  ];
}
