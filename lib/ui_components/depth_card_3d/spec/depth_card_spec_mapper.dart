import 'package:flutter/material.dart';

import '../models/depth_card_config.dart';
import '../models/depth_card_theme.dart';
import 'depth_card_spec.dart';

/// Converts DepthCardSpec (data-only) into DepthCardConfig (UI-only).
///
/// Backward compatibility:
/// - Existing screens can keep passing DepthCardConfig directly.
/// - Backend-driven flows pass DepthCardSpec and convert here.
///
/// Notes:
/// - We keep overlays lightweight.
/// - Unknown overlay kinds return SizedBox.shrink() to avoid crashes.
/// - We DO NOT change DepthCardConfig; this mapper adapts to it.
class DepthCardSpecMapper {
  static DepthCardConfig toConfig(
      DepthCardSpec spec, {
        VoidCallback? onTap,
        DepthCardSlots slots = DepthCardSlots.empty,
        List<dynamic>? overlayActions, // keeps this mapper independent of your action type
      }) {
    return DepthCardConfig(
      modelAssetPath: spec.modelPath,
      text: spec.titleText,
      theme: _themeFromKey(spec.themeKey),
      width: spec.width,
      height: spec.height,
      borderRadius: spec.borderRadius,
      parallaxDepth: spec.parallaxDepth,
      backgroundImage: (spec.backgroundAssetPath != null && spec.backgroundAssetPath!.trim().isNotEmpty)
          ? AssetImage(spec.backgroundAssetPath!)
          : null,
      onTap: onTap,
      slots: slots,
      overlayWidgets: spec.overlays.map(_overlayWidgetFromSpec).toList(),
      showInteractiveOverlay: spec.showInteractiveOverlay,

      // Keep as-is for now. Later you can define a JSON-safe ActionSpec DTO
      // and map it into your CardOverlayAction list in a separate mapper.
      overlayActions: overlayActions as dynamic,
    );
  }

  // ---------------------------------------------------------------------------
  // Theme mapping (backend sends "themeKey")
  // ---------------------------------------------------------------------------

  static DepthCardTheme _themeFromKey(String key) {
    switch (key) {
      case 'default':
        return const DepthCardTheme();

    // Add your catalog as you expand:
    // case 'indigoNeon':
    //   return const DepthCardTheme(...);

      default:
        return const DepthCardTheme();
    }
  }

  // ---------------------------------------------------------------------------
  // Overlay catalog mapping
  // ---------------------------------------------------------------------------

  static Widget _overlayWidgetFromSpec(DepthOverlaySpec o) {
    switch (o.kind) {
      case 'vignette':
        return _VignetteOverlay(
          opacity: _toDouble(o.props['opacity'], fallback: 0.18),
        );

      case 'softGlow':
        return _SoftGlowOverlay(
          opacity: _toDouble(o.props['opacity'], fallback: 0.12),
        );

    // You can safely add more overlay kinds later:
    // - "sparkle" (static light speckle)
    // - "scanlines"
    // - "noise" (subtle film grain)
    // Keep them cheap for scroll performance.

      default:
        return const SizedBox.shrink();
    }
  }

  static double _toDouble(dynamic v, {required double fallback}) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }
}

class _VignetteOverlay extends StatelessWidget {
  final double opacity;
  const _VignetteOverlay({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(opacity),
            ],
            radius: 0.95,
            center: Alignment.center,
          ),
        ),
      ),
    );
  }
}

class _SoftGlowOverlay extends StatelessWidget {
  final double opacity;
  const _SoftGlowOverlay({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(opacity),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}
