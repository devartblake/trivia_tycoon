// Legacy -> V2 adapter.
// This file allows you to keep ALL current screens unchanged while
// migrating DepthCard internals to a JSON-safe schema.

import 'package:flutter/material.dart';

import 'card_overlay_action.dart';
import 'depth_card_config.dart';
import 'depth_card_config_v2.dart';

/// Extension to adapt your existing DepthCardConfig into V2.
extension DepthCardConfigLegacyAdapter on DepthCardConfig {
  DepthCardConfigV2 toV2({
    // Optional: pass an explicit render mode if you want to override.
    DepthCardRenderModeV2? modeOverride,
  }) {
    // Determine mode based on known fields; keep conservative defaults.
    final inferredMode = _inferMode();

    // Media path selection:
    // - Prefer modelAssetPath if present and file looks like 3D
    // - Else fall back to image asset (if you have a field like that)
    // Adjust these mappings based on your legacy config fields.
    final mediaRef = _legacyMediaRef();

    // Background mapping:
    final bgRef = _legacyBackgroundRef();

    // Theme:
    // Keep "themeId" as a stable identifier if you have one.
    // If you only have a theme object, you can map the id externally later.
    final themeId = _legacyThemeId();

    // Overlays:
    final overlays = _legacyOverlaysToV2();

    return DepthCardConfigV2(
      mode: modeOverride ?? inferredMode,
      media: mediaRef,
      background: bgRef,
      text: text ?? '',
      width: width,
      height: height,
      parallaxDepth: parallaxDepth ?? 0.2,
      themeId: themeId,
      // We deliberately do not serialize runtime theme objects here.
      // If you want, you can map selected primitives into themeOverrides.
      themeOverrides: _legacyThemeOverrides(),
      overlays: overlays,
      meta: const <String, dynamic>{},
    );
  }

  /// Infer render mode from legacy config.
  DepthCardRenderModeV2 _inferMode() {
    final p = modelAssetPath;
    if (p != null && _looks3D(p)) return DepthCardRenderModeV2.threeD;
    // If you also store a file path for 3D, add checks here.
    return DepthCardRenderModeV2.image;
  }

  DepthCardResourceRefV2 _legacyMediaRef() {
    final p3d = modelAssetPath;
    if (p3d != null && p3d.isNotEmpty) {
      // Legacy assumes assets for models
      return DepthCardResourceRefV2(
        source: DepthCardResourceSourceV2.asset,
        path: p3d,
      );
    }

    // If your legacy config includes image asset path, map it here.
    // Many of your screens pass backgroundImage as AssetImage; we can't serialize ImageProvider.
    // So we use `background` for that and keep `media` as a safe default.
    //
    // If you have a primary "imageAssetPath" field, prefer it here.
    final bg = backgroundImage;
    if (bg is AssetImage) {
      return DepthCardResourceRefV2(
        source: DepthCardResourceSourceV2.asset,
        path: bg.assetName,
      );
    }

    // Fallback: empty asset path (caller should handle gracefully)
    return const DepthCardResourceRefV2(
      source: DepthCardResourceSourceV2.asset,
      path: '',
    );
  }

  DepthCardResourceRefV2? _legacyBackgroundRef() {
    final bg = backgroundImage;
    if (bg is AssetImage) {
      return DepthCardResourceRefV2(
        source: DepthCardResourceSourceV2.asset,
        path: bg.assetName,
      );
    }
    // If you later support FileImage/NetworkImage, map to file/remote here.
    return null;
  }

  String? _legacyThemeId() {
    // If your legacy theme has an ID field, return it here.
    // Otherwise, keep null and let the widget use current defaults.
    final t = theme;
    // Example (adjust to your actual theme type):
    // if (t != null) return t.id;
    if (t == null) return null;
    return t.runtimeType.toString();
  }

  DepthCardThemeOverridesV2? _legacyThemeOverrides() {
    // Optional: extract a small subset of theme values into JSON-safe overrides.
    // Keep this conservative to preserve your exact styling.
    // If you’re not ready, return null.
    return null;
  }

  List<DepthCardOverlayV2> _legacyOverlaysToV2() {
    final actions = overlayActions ?? const <CardOverlayAction>[];

    // Map your existing overlay action list into a serializable overlay record.
    // This preserves behavior while allowing future backend-driven overlays.
    final out = <DepthCardOverlayV2>[];

    for (final a in actions) {
      out.add(_mapOverlayAction(a));
    }

    // You can also add derived overlays here (e.g. badge based on config flags).
    return out;
  }

  DepthCardOverlayV2 _mapOverlayAction(CardOverlayAction a) {
    // Because we don't know your exact CardOverlayAction fields,
    // we store the action as a data payload and let the widget layer interpret it.
    // This guarantees backward compatibility right now.
    //
    // Later, you can add typed mapping (e.g. button, chip, icon) without changing storage format.

    final payload = <String, dynamic>{};

    // Common safe fields (adjust if different in your code):
    payload['type'] = a.type?.toString() ?? 'unknown';
    payload['label'] = a.label;
    payload['icon'] = a.iconCodePoint; // if you store icons as int
    payload['semantic'] = a.semanticId; // optional if present

    // Any "onTap" callbacks are NOT serializable.
    // Those remain runtime wiring in the widget layer.

    return DepthCardOverlayV2.customKind(
      kind: 'actionsRow',
      slot: 'bottomBar',
      z: 0,
      enabled: true,
      data: payload,
    );
  }
}

bool _looks3D(String path) {
  final l = path.toLowerCase();
  return l.endsWith('.glb') || l.endsWith('.gltf') || l.endsWith('.obj');
}

/// If your CardOverlayAction does not have these fields, update the adapter mapping above.
/// These extensions are optional convenience and keep compile errors localized.
extension _CardOverlayActionSafeFields on CardOverlayAction {
  String? get label {
    try {
      // ignore: unnecessary_dynamic
      final dynamic self = this;
      return self.label?.toString();
    } catch (_) {
      return null;
    }
  }

  String? get type {
    try {
      // ignore: unnecessary_dynamic
      final dynamic self = this;
      return self.type?.toString();
    } catch (_) {
      return null;
    }
  }

  int? get iconCodePoint {
    try {
      // ignore: unnecessary_dynamic
      final dynamic self = this;
      final icon = self.icon;
      if (icon is IconData) return icon.codePoint;
      if (icon is int) return icon;
      return null;
    } catch (_) {
      return null;
    }
  }

  String? get semanticId {
    try {
      // ignore: unnecessary_dynamic
      final dynamic self = this;
      return self.semanticId?.toString();
    } catch (_) {
      return null;
    }
  }
}
