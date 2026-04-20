import 'dart:convert';

/// JSON-safe, backend-ready spec for rendering a DepthCard.
///
/// Key goals:
/// - Pure data (no Widgets)
/// - Fully serializable (toJson/fromJson)
/// - Backward compatible: tolerant parsing + sensible defaults
/// - Supports "image-only now" but can be extended to 3D later without
///   touching UI code paths (DepthCardConfig stays UI-only).
class DepthCardSpec {
  /// Optional stable id for caching/dedupe (e.g. avatarId, missionId).
  final String id;

  /// Human text shown on the card.
  final String text;

  /// A theme key that maps to your DepthCardThemes catalog.
  /// Examples:
  /// - "light", "dark", "futuristic", "neon", "fantasy", "minimalist", "oceanic", "blueSteel"
  ///
  /// You can also accept legacy synonyms (handled in mapper).
  final String themeKey;

  /// Main visual asset reference.
  ///
  /// Supported patterns:
  /// - asset: "assets/images/avatars/a.png"
  /// - file:  "/data/user/0/.../a.png"
  ///
  /// For future:
  /// - 3D: "assets/3d/characters/x.glb" or absolute file path
  final String modelPath;

  /// Optional background image (asset or file). If not provided, the theme can handle it.
  final String? backgroundAssetPath;

  /// Optional card sizing hints (UI may override).
  final double? width;
  final double? height;

  /// UI-ish values but still JSON-safe; mapper applies defaults if null.
  final double? borderRadius;
  final double? parallaxDepth;

  /// Whether to show the glass interactive overlay.
  final bool showInteractiveOverlay;

  /// UI-only overlays (JSON-safe) that mapper can translate to actual widgets.
  /// Example:
  /// [
  ///   {"kind":"badge","props":{"slot":"topRight","text":"+50"}},
  ///   {"kind":"softGlow","props":{"intensity":0.6}}
  /// ]
  final List<DepthOverlaySpec> overlays;

  /// Optional actions that can be rendered as overlay actions (buttons).
  /// This is JSON-safe; UI decides how to display them.
  final List<DepthCardActionSpec> actions;

  const DepthCardSpec({
    required this.id,
    required this.text,
    required this.modelPath,
    required this.themeKey,
    this.backgroundAssetPath,
    this.width,
    this.height,
    this.borderRadius,
    this.parallaxDepth,
    this.showInteractiveOverlay = true,
    this.overlays = const [],
    this.actions = const [],
  });

  DepthCardSpec copyWith({
    String? id,
    String? text,
    String? themeKey,
    String? modelPath,
    String? backgroundAssetPath,
    double? width,
    double? height,
    double? borderRadius,
    double? parallaxDepth,
    bool? showInteractiveOverlay,
    List<DepthOverlaySpec>? overlays,
    List<DepthCardActionSpec>? actions,
  }) {
    return DepthCardSpec(
      id: id ?? this.id,
      text: text ?? this.text,
      themeKey: themeKey ?? this.themeKey,
      modelPath: modelPath ?? this.modelPath,
      backgroundAssetPath: backgroundAssetPath ?? this.backgroundAssetPath,
      width: width ?? this.width,
      height: height ?? this.height,
      borderRadius: borderRadius ?? this.borderRadius,
      parallaxDepth: parallaxDepth ?? this.parallaxDepth,
      showInteractiveOverlay:
          showInteractiveOverlay ?? this.showInteractiveOverlay,
      overlays: overlays ?? this.overlays,
      actions: actions ?? this.actions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'themeKey': themeKey,
        'modelPath': modelPath,
        if (backgroundAssetPath != null)
          'backgroundAssetPath': backgroundAssetPath,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (borderRadius != null) 'borderRadius': borderRadius,
        if (parallaxDepth != null) 'parallaxDepth': parallaxDepth,
        'showInteractiveOverlay': showInteractiveOverlay,
        'overlays': overlays.map((e) => e.toJson()).toList(),
        'actions': actions.map((e) => e.toJson()).toList(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Tolerant parsing: accepts legacy fields where possible.
  factory DepthCardSpec.fromJson(Map<String, dynamic> json) {
    final overlaysRaw = json['overlays'];
    final actionsRaw = json['actions'];

    return DepthCardSpec(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      themeKey: (json['themeKey'] ?? json['theme'] ?? 'futuristic').toString(),
      modelPath:
          (json['modelPath'] ?? json['src'] ?? json['model'] ?? '').toString(),
      backgroundAssetPath: json['backgroundAssetPath']?.toString(),
      width: _num(json['width']),
      height: _num(json['height']),
      borderRadius: _num(json['borderRadius']),
      parallaxDepth: _num(json['parallaxDepth']),
      showInteractiveOverlay: (json['showInteractiveOverlay'] is bool)
          ? json['showInteractiveOverlay'] as bool
          : true,
      overlays: overlaysRaw is List
          ? overlaysRaw
              .whereType<Map>()
              .map((m) =>
                  DepthOverlaySpec.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      actions: actionsRaw is List
          ? actionsRaw
              .whereType<Map>()
              .map((m) =>
                  DepthCardActionSpec.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
    );
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

/// JSON-safe overlay descriptor.
///
/// Each overlay is:
/// - kind: "softGlow", "vignette", "badge", "chip", etc.
/// - props: kind-specific properties (slot/text/intensity/colors etc.)
class DepthOverlaySpec {
  /// Overlay kind identifier.
  /// Examples:
  /// - "vignette"
  /// - "softGlow"
  /// - "badge"
  /// - "chip"
  final String type;

  /// Slot selector for overlays that should align to a corner.
  /// Supported: "topLeft", "topRight", "bottomLeft", "bottomRight", "center"
  final String? slot;

  /// Optional display text for overlays like badge/chip.
  final String? text;

  /// Arbitrary properties for tuning (opacity, etc.).
  final Map<String, dynamic> props;

  const DepthOverlaySpec({
    required this.type,
    this.slot,
    this.text,
    this.props = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        if (slot != null) 'slot': slot,
        if (text != null) 'text': text,
        'props': props,
      };

  factory DepthOverlaySpec.fromJson(Map<String, dynamic> json) {
    final rawProps = json['props'];
    return DepthOverlaySpec(
      type: (json['kind'] ?? json['type'] ?? '').toString(),
      slot: json['slot']?.toString(),
      text: json['text']?.toString(),
      props: json['props'] is Map
          ? Map<String, dynamic>.from(json['props'] as Map)
          : const {},
    );
  }
}

/// JSON-safe action descriptor.
///
/// Actions are intentionally data-only. The UI can map them to:
/// - buttons
/// - chips
/// - context menus
///
/// Examples:
/// {"id":"equip","label":"Equip","icon":"check","intent":"equip_avatar"}
/// {"id":"open","label":"Open","intent":"open_mission","payload":{"missionId":"m1"}}
class DepthCardActionSpec {
  /// Stable id for analytics and routing.
  final String id;

  /// "open", "equip", "buy", "info", "share", etc.
  final String type;

  /// Button label.
  final String label;

  /// Material icon key (mapper converts to IconData).
  /// Examples: "info", "check", "shopping_cart"
  final String? icon;

  /// Intent key for routing/handlers.
  final String intent;

  /// Optional extra data. Must remain JSON-safe.
  final Map<String, dynamic> payload;

  const DepthCardActionSpec({
    required this.id,
    required this.type,
    required this.label,
    required this.intent,
    this.icon,
    this.payload = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'intent': intent,
        if (icon != null) 'icon': icon,
        if (payload.isNotEmpty) 'payload': payload,
      };

  factory DepthCardActionSpec.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return DepthCardActionSpec(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      intent: (json['intent'] ?? '').toString(),
      icon: json['icon']?.toString(),
      payload:
          rawPayload is Map ? Map<String, dynamic>.from(rawPayload) : const {},
    );
  }
}
