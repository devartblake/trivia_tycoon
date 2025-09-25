import 'package:flutter/material.dart';
import '../models/card_overlay_action.dart';
import '../models/depth_card_theme.dart';
import '../models/lighting_options.dart';

class DepthCardSlots {
  final Widget? topLeft;
  final Widget? topRight;
  final Widget? bottomLeft;
  final Widget? bottomRight;
  final Widget? center;
  const DepthCardSlots({
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
    this.center,
  });
}

class DepthCardConfig {
  final double width;
  final double height;
  final double borderRadius;
  final String text;
  final String modelAssetPath;

  // Background options
  final ImageProvider? backgroundImage;
  final BoxFit backgroundFit;
  final Alignment backgroundAlignment;
  final double backgroundOpacity;
  final double backgroundBlur;
  final bool backgroundKenBurns;
  final BlendMode? backgroundBlendMode;

  /// IMPORTANT: keep low on Impeller unless you generate real mipmaps.
  final FilterQuality backgroundFilterQuality;

  // 3D text options
  final bool show3DText;
  final TextStyle textStyle;
  final int textDepth;
  final double textElevation;
  final bool textShine;

  // Parallax / theme / interactions
  final double parallaxDepth;
  final DepthCardTheme theme;
  final LightingOptions lightingOptions;
  final VoidCallback? onTap;
  final List<CardOverlayAction>? overlayActions;

  // Content hooks
  final Widget child; // optional content
  final DepthCardSlots slots;

  const DepthCardConfig({
    required this.width,
    required this.height,
    required this.text,
    required this.modelAssetPath,
    required this.theme,

    this.borderRadius = 24,
    this.backgroundImage,
    this.backgroundFit = BoxFit.cover,
    this.backgroundAlignment = Alignment.center,
    this.backgroundOpacity = 1.0,
    this.backgroundBlur = 0.0,
    this.backgroundKenBurns = true,
    this.backgroundBlendMode,
    this.backgroundFilterQuality = FilterQuality.low, // 👈 safe default

    this.show3DText = true,
    this.textStyle = const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    ),
    this.textDepth = 12,
    this.textElevation = 1.0,
    this.textShine = true,

    this.parallaxDepth = 0.12,
    this.lightingOptions = const LightingOptions(), // 👈 default to avoid required arg everywhere
    this.onTap,
    this.overlayActions,

    this.child = const SizedBox.shrink(), // 👈 default to avoid required arg everywhere
    this.slots = const DepthCardSlots(),
  });
}
