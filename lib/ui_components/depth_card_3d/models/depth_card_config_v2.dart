// V2 JSON-safe configuration for DepthCard.
// - Fully serializable: safe to persist locally and/or drive from backend.
// - Backward compatible: do not remove your legacy config; instead adapt it into V2.
// - Flutter-friendly: uses primitives (int/double/String/bool/List/Map).
//
// Notes:
// - Colors are ARGB ints (0xAARRGGBB).
// - Gradients are lists of ARGB ints + optional stops.
// - Media/background are "refs" that can represent asset/file/remote.
// - Overlays are typed, but also allow custom payloads for future extension.

import 'dart:convert';

/// Version for schema evolution.
/// Increase when you add breaking changes to the JSON schema.
class DepthCardSchema {
  static const int currentVersion = 2;
}

/// How the card should render internally.
enum DepthCardRenderModeV2 {
  image,
  threeD,
}

/// Where a referenced resource comes from.
enum DepthCardResourceSourceV2 {
  asset,
  file,
  remote,
}

/// Optional: used to describe a path/uri reference (asset path, absolute file path, or URL).
class DepthCardResourceRefV2 {
  final DepthCardResourceSourceV2 source;

  /// For asset: "assets/images/..."
  /// For file: absolute file path
  /// For remote: "https://..."
  final String path;

  const DepthCardResourceRefV2({
    required this.source,
    required this.path,
  });

  Map<String, dynamic> toJson() => {
        'source': source.name,
        'path': path,
      };

  factory DepthCardResourceRefV2.fromJson(Map<String, dynamic> json) {
    final src = (json['source'] ?? 'asset').toString();
    return DepthCardResourceRefV2(
      source: DepthCardResourceSourceV2.values.firstWhere(
        (e) => e.name == src,
        orElse: () => DepthCardResourceSourceV2.asset,
      ),
      path: (json['path'] ?? '').toString(),
    );
  }
}

/// Serializable gradient.
class DepthCardGradientV2 {
  /// ARGB ints (0xAARRGGBB)
  final List<int> colors;

  /// Optional gradient stops; if provided, must match colors length.
  final List<double>? stops;

  const DepthCardGradientV2({
    required this.colors,
    this.stops,
  });

  Map<String, dynamic> toJson() => {
        'colors': colors,
        if (stops != null) 'stops': stops,
      };

  factory DepthCardGradientV2.fromJson(Map<String, dynamic> json) {
    final rawColors = json['colors'];
    final colors = (rawColors is List)
        ? rawColors.map((e) => _parseInt(e)).whereType<int>().toList()
        : <int>[];

    final rawStops = json['stops'];
    final stops = (rawStops is List)
        ? rawStops.map((e) => _parseDouble(e)).whereType<double>().toList()
        : null;

    return DepthCardGradientV2(colors: colors, stops: stops);
  }
}

/// Small theme overrides that are safe to serialize.
/// Keep this minimal. Your existing theme objects can remain runtime-only.
/// If you already have `DepthCardTheme` types, map them to/from these primitives later.
class DepthCardThemeOverridesV2 {
  /// Card corner radius
  final double? borderRadius;

  /// Optional: solid background color behind content (ARGB)
  final int? backgroundColor;

  /// Optional: border color (ARGB)
  final int? borderColor;

  /// Optional: border width
  final double? borderWidth;

  /// Optional: title/text color (ARGB)
  final int? textColor;

  /// Optional: accent gradient (for highlights)
  final DepthCardGradientV2? accentGradient;

  const DepthCardThemeOverridesV2({
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.textColor,
    this.accentGradient,
  });

  Map<String, dynamic> toJson() => {
        if (borderRadius != null) 'borderRadius': borderRadius,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        if (borderColor != null) 'borderColor': borderColor,
        if (borderWidth != null) 'borderWidth': borderWidth,
        if (textColor != null) 'textColor': textColor,
        if (accentGradient != null) 'accentGradient': accentGradient!.toJson(),
      };

  factory DepthCardThemeOverridesV2.fromJson(Map<String, dynamic> json) {
    return DepthCardThemeOverridesV2(
      borderRadius: _parseDouble(json['borderRadius']),
      backgroundColor: _parseInt(json['backgroundColor']),
      borderColor: _parseInt(json['borderColor']),
      borderWidth: _parseDouble(json['borderWidth']),
      textColor: _parseInt(json['textColor']),
      accentGradient: (json['accentGradient'] is Map)
          ? DepthCardGradientV2.fromJson(
              Map<String, dynamic>.from(json['accentGradient'] as Map),
            )
          : null,
    );
  }
}

/// Overlay type identifiers.
/// You can extend this list over time.
/// Also supported: custom overlays using `kind = "custom:xyz"` via [DepthCardOverlayV2.customKind].
enum DepthCardOverlayKindV2 {
  badge,
  progressBar,
  progressRing,
  actionsRow,
  labelChip,
  // keep expanding without breaking older JSON
}

/// Overlay payload base.
/// Each overlay is fully serializable and can be rendered by your DepthCard.
/// Rendering is done by the widget; this is data only.
class DepthCardOverlayV2 {
  /// Either one of [DepthCardOverlayKindV2] names OR a custom kind string (e.g. "custom:missionClaim")
  final String kind;

  /// Placement channel; use consistent slots to avoid collisions and reduce layout churn.
  /// Examples: "topLeft", "topRight", "bottomLeft", "bottomRight", "bottomBar", "center"
  final String slot;

  /// Optional z-order within the slot (higher draws on top).
  final int z;

  /// Whether overlay is visible.
  final bool enabled;

  /// Typed payload (must be JSON-safe).
  /// The widget layer interprets this based on [kind].
  final Map<String, dynamic> data;

  const DepthCardOverlayV2({
    required this.kind,
    required this.slot,
    this.z = 0,
    this.enabled = true,
    this.data = const <String, dynamic>{},
  });

  /// Convenience for custom overlay kinds.
  static DepthCardOverlayV2 customKind({
    required String kind,
    required String slot,
    int z = 0,
    bool enabled = true,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) {
    return DepthCardOverlayV2(
      kind: kind,
      slot: slot,
      z: z,
      enabled: enabled,
      data: data,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'slot': slot,
        'z': z,
        'enabled': enabled,
        'data': data,
      };

  factory DepthCardOverlayV2.fromJson(Map<String, dynamic> json) {
    return DepthCardOverlayV2(
      kind: (json['kind'] ?? '').toString(),
      slot: (json['slot'] ?? 'topRight').toString(),
      z: _parseInt(json['z']) ?? 0,
      enabled: (json['enabled'] ?? true) == true,
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const <String, dynamic>{},
    );
  }
}

/// V2 DepthCard config.
/// This is what can be stored in cache and later served by backend.
class DepthCardConfigV2 {
  /// Schema version for forward/backward parsing tolerance.
  final int schemaVersion;

  /// Rendering mode. DepthCard can decide internally how to render.
  final DepthCardRenderModeV2 mode;

  /// Primary media ref.
  /// - image mode: points to image
  /// - 3D mode: points to model
  final DepthCardResourceRefV2 media;

  /// Optional background behind the card.
  final DepthCardResourceRefV2? background;

  /// Display text. Keep as content; runtime can still replace it.
  final String text;

  /// Size hints; the widget can ignore these if constrained by layout.
  final double? width;
  final double? height;

  /// Parallax intensity (0..1 typical).
  final double parallaxDepth;

  /// Theme preset id (maps to your existing theme registry).
  final String? themeId;

  /// Optional theme overrides, JSON-safe.
  final DepthCardThemeOverridesV2? themeOverrides;

  /// Overlays to render. Multiple overlays allowed.
  final List<DepthCardOverlayV2> overlays;

  /// Optional metadata for analytics/debugging/routing.
  final Map<String, dynamic> meta;

  const DepthCardConfigV2({
    this.schemaVersion = DepthCardSchema.currentVersion,
    required this.mode,
    required this.media,
    this.background,
    this.text = '',
    this.width,
    this.height,
    this.parallaxDepth = 0.2,
    this.themeId,
    this.themeOverrides,
    this.overlays = const <DepthCardOverlayV2>[],
    this.meta = const <String, dynamic>{},
  });

  DepthCardConfigV2 copyWith({
    int? schemaVersion,
    DepthCardRenderModeV2? mode,
    DepthCardResourceRefV2? media,
    DepthCardResourceRefV2? background,
    String? text,
    double? width,
    double? height,
    double? parallaxDepth,
    String? themeId,
    DepthCardThemeOverridesV2? themeOverrides,
    List<DepthCardOverlayV2>? overlays,
    Map<String, dynamic>? meta,
  }) {
    return DepthCardConfigV2(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      mode: mode ?? this.mode,
      media: media ?? this.media,
      background: background ?? this.background,
      text: text ?? this.text,
      width: width ?? this.width,
      height: height ?? this.height,
      parallaxDepth: parallaxDepth ?? this.parallaxDepth,
      themeId: themeId ?? this.themeId,
      themeOverrides: themeOverrides ?? this.themeOverrides,
      overlays: overlays ?? this.overlays,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'mode': mode.name,
        'media': media.toJson(),
        if (background != null) 'background': background!.toJson(),
        'text': text,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        'parallaxDepth': parallaxDepth,
        if (themeId != null) 'themeId': themeId,
        if (themeOverrides != null) 'themeOverrides': themeOverrides!.toJson(),
        'overlays': overlays.map((e) => e.toJson()).toList(),
        if (meta.isNotEmpty) 'meta': meta,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory DepthCardConfigV2.fromJson(Map<String, dynamic> json) {
    final version = _parseInt(json['schemaVersion']) ?? 1;
    final modeStr = (json['mode'] ?? 'image').toString();

    // Tolerant parsing: unknown modes default to image.
    final mode = DepthCardRenderModeV2.values.firstWhere(
      (e) => e.name == modeStr,
      orElse: () => DepthCardRenderModeV2.image,
    );

    // Required media ref.
    final media = (json['media'] is Map)
        ? DepthCardResourceRefV2.fromJson(
            Map<String, dynamic>.from(json['media'] as Map))
        : const DepthCardResourceRefV2(
            source: DepthCardResourceSourceV2.asset, path: '');

    final background = (json['background'] is Map)
        ? DepthCardResourceRefV2.fromJson(
            Map<String, dynamic>.from(json['background'] as Map))
        : null;

    final overlaysRaw = json['overlays'];
    final overlays = <DepthCardOverlayV2>[];
    if (overlaysRaw is List) {
      for (final item in overlaysRaw) {
        if (item is Map) {
          overlays.add(
              DepthCardOverlayV2.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};

    // You can add version migration logic here if you later change schema.
    // For now, V1->V2 tolerant parsing is enough.
    return DepthCardConfigV2(
      schemaVersion: version,
      mode: mode,
      media: media,
      background: background,
      text: (json['text'] ?? '').toString(),
      width: _parseDouble(json['width']),
      height: _parseDouble(json['height']),
      parallaxDepth: _parseDouble(json['parallaxDepth']) ?? 0.2,
      themeId: json['themeId']?.toString(),
      themeOverrides: (json['themeOverrides'] is Map)
          ? DepthCardThemeOverridesV2.fromJson(
              Map<String, dynamic>.from(json['themeOverrides'] as Map))
          : null,
      overlays: overlays,
      meta: meta,
    );
  }
}

/// ------------
/// Parsing helpers (safe, tolerant)
/// ------------

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  // Supports hex like "0xFF00FF00"
  if (s.startsWith('0x') || s.startsWith('0X')) {
    return int.tryParse(s.substring(2), radix: 16);
  }
  return int.tryParse(s);
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
