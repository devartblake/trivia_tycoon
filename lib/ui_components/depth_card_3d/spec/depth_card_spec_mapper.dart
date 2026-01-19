import 'package:flutter/material.dart';

import '../models/depth_card_config.dart';
import '../models/depth_card_theme.dart';
import '../models/card_overlay_action.dart';
import '../spec/depth_card_spec.dart';

/// Action dispatcher for JSON-safe actions.
///
/// The mapper can create UI buttons, but the runtime app decides what the action does.
/// This keeps the spec JSON-safe and backend-friendly.
typedef DepthCardActionDispatcher = void Function(DepthCardActionSpec action);

/// Converts JSON-safe DepthCardSpec → UI-only DepthCardConfig.
///
/// RULES:
/// - DepthCardConfig is NOT modified
/// - Spec is backend-safe
/// - Mapper is the ONLY translation layer
class DepthCardSpecMapper {

  /// Map a spec to a UI config.
  ///
  /// Optional:
  /// - onTap: UI callback
  /// - slots: slot widgets for card corners/center
  /// - overlayActions: UI-only actions (legacy/manual)
  /// - actionDispatcher: converts spec.actions into UI actions
  static DepthCardConfig toConfig(
      DepthCardSpec spec, {
        VoidCallback? onTap,
        DepthCardSlots slots = DepthCardSlots.empty,

        /// Legacy/manual UI actions path (kept for compatibility).
        List<CardOverlayAction>? overlayActions,

        /// New path: map spec.actions -> CardOverlayAction buttons.
        DepthCardActionDispatcher? actionDispatcher,
      }) {
    final mappedActions = _mapSpecActions(spec.actions, dispatcher: actionDispatcher);

    return DepthCardConfig(
      modelAssetPath: spec.modelPath,
      text: spec.titleText,
      theme: _themeFromKey(spec.themeKey),
      width: spec.width,
      height: spec.height,
      borderRadius: spec.borderRadius,
      parallaxDepth: spec.parallaxDepth,
      showInteractiveOverlay: spec.showInteractiveOverlay,
      // Background image (asset-only for now, backend-safe)
      backgroundImage: (spec.backgroundAssetPath != null && spec.backgroundAssetPath!.isNotEmpty)
          ? AssetImage(spec.backgroundAssetPath!)
          : null,
      onTap: onTap,
      slots: slots,

      // Overlay widgets (mapped from JSON-safe overlay specs)
      overlayWidgets: spec.overlays.map(_overlayWidgetFromSpec).toList(growable: false),

      // Actions remain UI-driven for now
      overlayActions: overlayActions ?? mappedActions,
    );
  }

  // ---------------------------------------------------------------------------
  // Theme catalog
  // ---------------------------------------------------------------------------

  static DepthCardTheme _themeFromKey(String key) {
    switch (key) {
      case 'default':
        return const DepthCardTheme();

    // Future examples:
    // case 'indigoNeon':
    //   return DepthCardThemes.indigoNeon;

      default:
        return const DepthCardTheme();
    }
  }

  // ---------------------------------------------------------------------------
  // Action mapping (JSON-safe -> UI-only CardOverlayAction)
  // ---------------------------------------------------------------------------

  static List<CardOverlayAction>? _mapSpecActions(
      List<DepthCardActionSpec> actions, {
        required DepthCardActionDispatcher? dispatcher,
      }) {
    if (actions.isEmpty) return null;
    if (dispatcher == null) return null;

    return actions.map((a) {
      return CardOverlayAction(
        icon: _iconFromKey(a.iconKey),
        tooltip: a.label,
        onTap: () => dispatcher(a),
        onPressed: () {  },
      );
    }).toList();
  }

  static IconData _iconFromKey(String key) {
    // Keep this mapping stable. Backend sends strings, UI maps to IconData.
    switch (key) {
      case 'download':
        return Icons.download_rounded;
      case 'install':
        return Icons.file_download_rounded;
      case 'open':
        return Icons.open_in_new_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'play':
        return Icons.play_arrow_rounded;
      case 'profile':
        return Icons.person_rounded;
      case 'settings':
        return Icons.settings_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'delete':
        return Icons.delete_outline_rounded;

      default:
        return Icons.more_horiz_rounded;
    }
  }

  // ---------------------------------------------------------------------------
  // Overlay catalog (JSON-safe → Widget)
  // ---------------------------------------------------------------------------

  static Widget _overlayWidgetFromSpec(DepthOverlaySpec spec) {
    switch (spec.kind) {
      case 'vignette':
        return _VignetteOverlay(
          opacity: _toDouble(spec.props['opacity'], fallback: 0.18),
        );

      case 'softGlow':
        return _SoftGlowOverlay(
          opacity: _toDouble(spec.props['opacity'], fallback: 0.12),
        );

      default:
      // Unknown overlay → safe no-op
        return const SizedBox.shrink();
    }
  }

  static double _toDouble(dynamic v, {required double fallback}) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }
}

// ---------------------------------------------------------------------------
// Lightweight overlays (GPU-cheap, scroll-safe)
// ---------------------------------------------------------------------------
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
