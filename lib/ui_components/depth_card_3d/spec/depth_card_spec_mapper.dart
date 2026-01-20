import 'package:flutter/material.dart';

import '../models/card_overlay_action.dart';
import '../models/depth_card_config.dart';
import '../models/depth_card_theme.dart';
import '../models/depth_card_themes.dart';
import '../models/depth_card_slots.dart';

import 'depth_card_spec.dart';

/// Single mapping layer: DepthCardSpec (JSON-safe) -> DepthCardConfig (UI-only).
///
/// Requirements satisfied:
/// - Backward compatibility: DepthCardConfig stays unchanged
/// - Supports multiple overlays simultaneously (Stack)
/// - Performance safety: overlays are lightweight + IgnorePointer
/// - ThemeKey mapping uses your actual DepthCardThemes catalog
class DepthCardSpecMapper {

  /// Map the JSON-safe spec into the UI config.
  ///
  /// - [fallbackWidth]/[fallbackHeight] provide defaults if spec omits them.
  /// - [onAction] lets you wire action intents without embedding logic into spec.
  static DepthCardConfig toConfig(
      DepthCardSpec spec, {
        required VoidCallback onTap,
        double fallbackWidth = double.infinity,
        double fallbackHeight = double.infinity,

        /// UI-only slots remain outside the data-only spec.
        DepthCardSlots slots = DepthCardSlots.empty,

        /// Optional action callback. If null, actions are not rendered.
        void Function(DepthCardActionSpec action)? onAction,
      }) {
    final theme = _themeFromKey(spec.themeKey);

    final overlayWidgets = spec.overlays
        .map(_overlayWidgetFromSpec) // returns Widget, never nullable
        .whereType<Widget>()
        .toList();

    final overlayActions = (onAction == null)
        ? null
        : spec.actions.map((a) => _toCardOverlayAction(a, onAction)).toList();

    return DepthCardConfig(
      modelAssetPath: spec.modelPath,
      theme: theme,
      text: spec.text,
      width: spec.width ?? fallbackWidth,
      height: spec.height ?? fallbackHeight,
      parallaxDepth: spec.parallaxDepth ?? 0.18,
      borderRadius: spec.borderRadius ?? 24,
      backgroundImage: _backgroundProvider(spec.backgroundAssetPath),
      onTap: onTap,
      overlayActions: overlayActions,
      overlayWidgets: overlayWidgets,
      showInteractiveOverlay: spec.showInteractiveOverlay,
      slots: slots, // spec is data-only; slots remain UI-only.
    );
  }

  // ---------------------------------------------------------------------------
  // Theme mapping (aligned with your catalog)
  // ---------------------------------------------------------------------------

  static DepthCardTheme _themeFromKey(String key) {
    final k = key.trim().toLowerCase();

    // Keep this stable; backend should send known keys.
    switch (k) {
      case 'indigo':
        return DepthCardThemes.indigo;
      case 'neon':
      case 'neon_pink':
      case 'neonpink':
        return DepthCardThemes.neonPink;
      case 'emerald':
      case 'green':
        return DepthCardThemes.emerald;
      case 'amber':
      case 'gold':
        return DepthCardThemes.amber;
      case 'midnight':
      case 'dark':
        return DepthCardThemes.midnight;

    // Existing catalog keys (based on your current DepthCardThemes)
      case 'light':
        return DepthCardThemes.light;
      case 'futuristic':
        return DepthCardThemes.futuristic;
      case 'fantasy':
        return DepthCardThemes.fantasy;
      case 'minimalist':
        return DepthCardThemes.minimalist;
      case 'oceanic':
        return DepthCardThemes.oceanic;
      case 'blue_steel':
      case 'bluesteel':
        return DepthCardThemes.blueSteel;

      default:
        return DepthCardThemes.indigo;
    }
  }

  // ---------------------------------------------------------------------------
  // Background provider
  // ---------------------------------------------------------------------------

  static ImageProvider? _backgroundProvider(String? backgroundAssetPath) {
    if (backgroundAssetPath == null) return null;
    final p = backgroundAssetPath.trim();
    if (p.isEmpty) return null;

    // Keep background as AssetImage for now.
    // If later you want file backgrounds, add a flag in the spec.
    return AssetImage(p);
  }

  // ---------------------------------------------------------------------------
  // Overlay mapping (multiple overlays supported)
  // ---------------------------------------------------------------------------

  static Widget? _overlayWidgetFromSpec(DepthOverlaySpec o) {
    final type = o.type.trim().toLowerCase();
    switch (type) {
      case 'vignette':
        return _VignetteOverlay(
          opacity: _dbl(o.props['opacity'], 0.18),
        );

      case 'softglow':
      case 'soft_glow':
        return _SoftGlowOverlay(
          intensity: _dbl(o.props['intensity'], 0.55),
        );

      case 'badge':
        return _CornerBadgeOverlay(
          slot: (o.props['slot'] ?? 'topRight').toString(),
          text: (o.props['text'] ?? '').toString(),
        );

      case 'chip':
        return _CornerChipOverlay(
          slot: (o.props['slot'] ?? 'bottomLeft').toString(),
          text: (o.props['text'] ?? '').toString(),
        );

    // Unknown overlays are ignored for forward compatibility.
      default:
        return null;
    }
  }

  static double _dbl(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  // ---------------------------------------------------------------------------
  // Action mapping (data -> CardOverlayAction)
  // ---------------------------------------------------------------------------

  static CardOverlayAction _toCardOverlayAction(
      DepthCardActionSpec a,
      void Function(DepthCardActionSpec action) onAction,
      ) {
    return CardOverlayAction(
      icon: _iconFromKey(a.icon),
      title: a.label,
      onTap: () => onAction(a),
      onPressed: () {  },
      tooltip: '',
    );
  }

  static IconData _iconFromKey(String? key) {
    final k = (key ?? '').trim().toLowerCase();
    switch (k) {
      case 'info':
      case 'info_outline':
        return Icons.info_outline_rounded;
      case 'check':
      case 'done':
        return Icons.check_rounded;
      case 'equip':
        return Icons.verified_rounded;
      case 'buy':
      case 'cart':
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'share':
        return Icons.share_rounded;
      case 'play':
        return Icons.play_arrow_rounded;
      case 'settings':
        return Icons.settings_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }
}

/// Used for file images without importing dart:io into the mapper file.
/// This keeps the mapper usable in more contexts.
///
/// If you prefer, replace with `FileImage(File(path))` and import dart:io.
class FileImageUriProvider extends ImageProvider<FileImageUriProvider> {
  final String filePath;
  const FileImageUriProvider(this.filePath);

  @override
  ImageStreamCompleter loadImage(FileImageUriProvider key, ImageDecoderCallback decode) {
    // This is intentionally not implemented to avoid custom IO plumbing here.
    // If you need file path backgrounds, use `FileImage(File(path))` instead.
    //
    // Kept as a placeholder to keep the mapper compile-safe without dart:io
    // depending on your layering. If your project allows dart:io here:
    // - remove this class
    // - use FileImage(File(path))
    throw UnsupportedError(
      'FileImageUriProvider is a placeholder. Replace _backgroundProvider() '
          'with FileImage(File(path)) if you want file-based backgrounds.',
    );
  }

  @override
  Future<FileImageUriProvider> obtainKey(ImageConfiguration configuration) async => this;

  @override
  bool operator ==(Object other) => other is FileImageUriProvider && other.filePath == filePath;

  @override
  int get hashCode => filePath.hashCode;
}

// ---------------------------------------------------------------------------
// Overlay Widgets (lightweight + IgnorePointer)
// ---------------------------------------------------------------------------

class _VignetteOverlay extends StatelessWidget {
  final double opacity;
  const _VignetteOverlay({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(opacity),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftGlowOverlay extends StatelessWidget {
  final double intensity;
  const _SoftGlowOverlay({required this.intensity});

  @override
  Widget build(BuildContext context) {
    final a = intensity.clamp(0.0, 1.0);
    return IgnorePointer(
      ignoring: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.10 * a),
              Colors.transparent,
              Colors.white.withOpacity(0.06 * a),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerBadgeOverlay extends StatelessWidget {
  final String slot;
  final String text;

  const _CornerBadgeOverlay({required this.slot, required this.text});

  @override
  Widget build(BuildContext context) {
    final pos = _slotToPosition(slot);
    if (pos == null || text.trim().isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: pos.top,
      right: pos.right,
      bottom: pos.bottom,
      left: pos.left,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF000000).withOpacity(0.35),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerChipOverlay extends StatelessWidget {
  final String slot;
  final String text;

  const _CornerChipOverlay({required this.slot, required this.text});

  @override
  Widget build(BuildContext context) {
    final pos = _slotToPosition(slot);
    if (pos == null || text.trim().isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: pos.top,
      right: pos.right,
      bottom: pos.bottom,
      left: pos.left,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFFFFFFF).withOpacity(0.16),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotPosition {
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  const _SlotPosition({this.top, this.right, this.bottom, this.left});
}

_SlotPosition? _slotToPosition(String slot) {
  const inset = 12.0;
  switch (slot.trim()) {
    case 'topLeft':
      return const _SlotPosition(top: inset, left: inset);
    case 'topRight':
      return const _SlotPosition(top: inset, right: inset);
    case 'bottomLeft':
      return const _SlotPosition(bottom: inset, left: inset);
    case 'bottomRight':
      return const _SlotPosition(bottom: inset, right: inset);
    default:
      return null;
  }
}
