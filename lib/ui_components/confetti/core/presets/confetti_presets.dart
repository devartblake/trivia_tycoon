import 'package:flutter/material.dart';
import '../../models/confetti_shape.dart';
import '../presets/confetti_preset_images.dart';
import '../confetti_theme.dart';

class ConfettiPresets {
  /// Celebration confetti preset theme.
  static final ConfettiTheme celebration = ConfettiTheme(
    name: "Celebration",
    colors: [Colors.red, Colors.yellow, Colors.blue, Colors.green],
    speed: 3.0,
    density: 100,
    shapes: [
      ConfettiShapeType.circle,
      ConfettiShapeType.square,
      ConfettiShapeType.star,
    ],
    images: [ ConfettiPresetImages.star],
    useImages: true,
  );

  /// Galaxy confetti preset theme.
  static final ConfettiTheme galaxy = ConfettiTheme(
    name: "Galaxy",
    colors: [Colors.purple, Colors.blueAccent, Colors.indigo, Colors.black],
    speed: 2.5,
    density: 80,
    shapes: [
      ConfettiShapeType.circle,
      ConfettiShapeType.star,
    ],
    images: [ConfettiPresetImages.star],
    useImages: true,
  );

  /// Tropical confetti preset theme.
  static final ConfettiTheme tropical = ConfettiTheme(
    name: "Tropical",
    colors: [Colors.orange, Colors.teal, Colors.lime, Colors.pink],
    speed: 3.5,
    density: 120,
    shapes: [
      ConfettiShapeType.triangle,
      ConfettiShapeType.circle,
    ],
    images: [ConfettiPresetImages.balloon],
    useImages: true,
  );

  /// Snowstorm confetti preset theme.
  static final ConfettiTheme snowstorm = ConfettiTheme(
    name: "Snowstorm",
    colors: [Colors.white, Colors.lightBlueAccent],
    speed: 2.0,
    density: 150,
    shapes: [ConfettiShapeType.square],
    images:[ConfettiPresetImages.snowFlake ],
    useImages: true,
  );

  /// Sunset confetti preset theme.
  static final ConfettiTheme sunset = ConfettiTheme(
    name: "Sunset",
    colors: [Colors.deepOrange, Colors.pinkAccent, Colors.purpleAccent],
    speed: 2.8,
    density: 90,
    shapes: [
      ConfettiShapeType.square,
      ConfettiShapeType.circle,
    ],
    images: [ConfettiPresetImages.heart],
    useImages: true,
  );

  static List<ConfettiTheme> get allPresets => [
    celebration,
    galaxy,
    tropical,
    snowstorm,
    sunset,
  ];

  /// Returns a list of preset names.
  static List<String> get allPresetNames => allPresets.map((t) => t.name).toList();

  /// Returns a preset by name, defaulting to "Celebration" if not found.
  static ConfettiTheme getPresetByName(String name) {
    return allPresets.firstWhere(
          (theme) => theme.name == name,
      orElse: () => celebration,
    );
  }
}