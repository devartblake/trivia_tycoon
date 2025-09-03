import 'package:flutter/material.dart';
import '../models/depth_card_theme.dart';
import '../models/lighting_options.dart';
import '../models/card_overlay_action.dart';

class DepthCardConfig {
  final double width;
  final double height;
  final String text;
  final String modelAssetPath;
  final ImageProvider backgroundImage;
  final VoidCallback? onTap;
  final List<CardOverlayAction>? overlayActions;
  final double borderRadius;
  final bool enableHaptics;
  final double parallaxDepth;
  final DepthCardTheme theme;
  final LightingOptions lightingOptions;

  const DepthCardConfig({
    required this.width,
    required this.height,
    required this.text,
    required this.modelAssetPath,
    required this.backgroundImage,
    this.onTap,
    this.overlayActions,
    this.borderRadius = 16.0,
    this.enableHaptics = true,
    this.parallaxDepth = 6.0,
    this.theme = const DepthCardTheme(),
    this.lightingOptions = const LightingOptions(),
  });
}
