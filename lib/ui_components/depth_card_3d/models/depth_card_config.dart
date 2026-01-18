import 'package:flutter/material.dart';
import 'card_overlay_action.dart';
import 'depth_card_theme.dart';
import 'lighting_options.dart';

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

  static const empty = DepthCardSlots();
}

class DepthCardConfig {
  final String modelAssetPath;
  final String text;
  final double width;
  final double height;
  final double borderRadius;
  final double parallaxDepth;
  final LightingOptions lightingOptions;
  final VoidCallback? onTap;
  final List<CardOverlayAction>? overlayActions;

  /// Additional overlay widgets rendered above the core visual.
  ///
  /// This supports multiple overlays being active at once (badges, chips,
  /// controls) without forcing everything into [overlayActions].
  ///
  /// Note: This is UI-only (not serializable).
  final List<Widget> overlayWidgets;

  final DepthCardSlots slots;
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
  final DepthCardTheme theme;

  // Content hooks
  final Widget child; // optional content

  /// Whether to render the built-in InteractiveOverlay.
  /// Leave default true for backward compatibility.
  final bool showInteractiveOverlay;

  const DepthCardConfig({
    required this.modelAssetPath,
    required this.text,
    required this.width,
    required this.height,
    this.borderRadius = 24,
    this.parallaxDepth = 0.1,
    this.theme = const DepthCardTheme(),
    this.lightingOptions = const LightingOptions(), // 👈 default to avoid required arg everywhere
    this.onTap,
    this.overlayActions,
    this.overlayWidgets = const [],
    this.slots = const DepthCardSlots(),
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
    this.child = const SizedBox.shrink(), // 👈 default to avoid required arg everywhere
    this.showInteractiveOverlay = true,
  });
}
