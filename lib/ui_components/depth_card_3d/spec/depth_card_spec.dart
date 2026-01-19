import 'dart:convert';

/// JSON-safe rendering spec that your backend can return.
///
/// IMPORTANT:
/// - Data-only (no Widgets, no callbacks, no ImageProvider, no Flutter-only types).
/// - Convert to your existing UI-only DepthCardConfig via DepthCardSpecMapper.
///
/// Backward compatibility:
/// - This spec is versioned via [schemaVersion].
/// - fromJson tolerates both camelCase and snake_case keys.
///
/// Paths:
/// - `modelPath` can be an asset path ("assets/..."), local file path ("/data/..."),
///   or a remote URL ("https://...").
/// - `backgroundAssetPath` is an optional asset path string. If you later want remote
///   backgrounds, add a backgroundUrl field and resolve client-side.
class DepthCardSpec {
  /// Increment when you evolve the schema.
  /// Keep defaults compatible.
  final int schemaVersion;

  /// Unique identifier for the spec (useful for caching/dedup).
  final String id;

  /// Primary content path (3D model OR image).
  /// Can be asset/file/url.
  final String modelPath;

  /// Optional title text displayed at top (maps to DepthCardConfig.text).
  final String titleText;

  /// Theme key, not the theme object. Example: "default", "indigoNeon", etc.
  final String themeKey;

  /// Layout params
  final double width;
  final double height;
  final double borderRadius;

  /// Parallax intensity
  final double parallaxDepth;

  /// Optional background asset path (JSON-safe string).
  /// Example: "assets/images/backgrounds/geometry_background.jpg"
  final String? backgroundAssetPath;

  /// Feature flags
  final bool showInteractiveOverlay;

  /// Overlay spec list (JSON-safe recipes -> mapped to Widgets client-side).
  final List<DepthOverlaySpec> overlays;

  /// JSON-safe overlay actions (buttons) that can be rendered as UI actions.
  /// These are *data only*; the mapper can turn them into CardOverlayAction
  /// by using an action dispatcher callback (runtime).
  final List<DepthCardActionSpec> actions;

  const DepthCardSpec({
    this.schemaVersion = 1,
    required this.id,
    required this.modelPath,
    this.titleText = '',
    this.themeKey = 'default',
    this.backgroundAssetPath,
    this.width = 320,
    this.height = 220,
    this.borderRadius = 24,
    this.parallaxDepth = 0.25,
    this.showInteractiveOverlay = true,
    this.overlays = const [],
    this.actions = const [],
  });

  DepthCardSpec copyWith({
    int? schemaVersion,
    String? id,
    String? modelPath,
    String? titleText,
    String? themeKey,
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
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      modelPath: modelPath ?? this.modelPath,
      titleText: titleText ?? this.titleText,
      themeKey: themeKey ?? this.themeKey,
      backgroundAssetPath: backgroundAssetPath ?? this.backgroundAssetPath,
      width: width ?? this.width,
      height: height ?? this.height,
      borderRadius: borderRadius ?? this.borderRadius,
      parallaxDepth: parallaxDepth ?? this.parallaxDepth,
      showInteractiveOverlay: showInteractiveOverlay ?? this.showInteractiveOverlay,
      overlays: overlays ?? this.overlays,
      actions: actions ?? this.actions,
    );
  }

  Map<String, dynamic> toJson({bool snakeCase = false}) {
    if (!snakeCase) {
      return {
        'schemaVersion': schemaVersion,
        'id': id,
        'modelPath': modelPath,
        'titleText': titleText,
        'themeKey': themeKey,
        'backgroundAssetPath': backgroundAssetPath,
        'width': width,
        'height': height,
        'borderRadius': borderRadius,
        'parallaxDepth': parallaxDepth,
        'showInteractiveOverlay': showInteractiveOverlay,
        'overlays': overlays.map((e) => e.toJson()).toList(),
        'actions': actions.map((e) => e.toJson()).toList(),
      };
    }

    // Optional: if your backend prefers snake_case.
    return {
      'schema_version': schemaVersion,
      'id': id,
      'model_path': modelPath,
      'title_text': titleText,
      'theme_key': themeKey,
      'background_asset_path': backgroundAssetPath,
      'width': width,
      'height': height,
      'border_radius': borderRadius,
      'parallax_depth': parallaxDepth,
      'show_interactive_overlay': showInteractiveOverlay,
      'overlays': overlays.map((e) => e.toJson(snakeCase: true)).toList(),
      'actions': actions.map((e) => e.toJson()).toList(),
    };
  }

  factory DepthCardSpec.fromJson(Map<String, dynamic> json) {
    // Accept both camelCase and snake_case.
    dynamic read(String camel, String snake) => json.containsKey(camel) ? json[camel] : json[snake];

    final overlaysRaw = read('overlays', 'overlays');
    final overlays = (overlaysRaw is List)
        ? overlaysRaw
        .whereType<Map>()
        .map((e) => DepthOverlaySpec.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        : const <DepthOverlaySpec>[];

    return DepthCardSpec(
      schemaVersion: _toInt(read('schemaVersion', 'schema_version'), fallback: 1),
      id: (read('id', 'id') ?? '').toString(),
      modelPath: (read('modelPath', 'model_path') ?? '').toString(),
      titleText: (read('titleText', 'title_text') ?? '').toString(),
      themeKey: (read('themeKey', 'theme_key') ?? 'default').toString(),
      backgroundAssetPath: read('backgroundAssetPath', 'background_asset_path')?.toString(),
      width: _toDouble(read('width', 'width'), fallback: 320),
      height: _toDouble(read('height', 'height'), fallback: 220),
      borderRadius: _toDouble(read('borderRadius', 'border_radius'), fallback: 24),
      parallaxDepth: _toDouble(read('parallaxDepth', 'parallax_depth'), fallback: 0.25),
      showInteractiveOverlay: _toBool(read('showInteractiveOverlay', 'show_interactive_overlay'), fallback: true),
      overlays: (json['overlays'] is List)
          ? (json['overlays'] as List)
          .map((e) => DepthOverlaySpec.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
          : const [],
      actions: (json['actions'] is List)
          ? (json['actions'] as List)
          .map((e) => DepthCardActionSpec.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
          : const [],
    );
  }

  String toPrettyJson({bool snakeCase = false}) =>
      const JsonEncoder.withIndent('  ').convert(toJson(snakeCase: snakeCase));

  static double _toDouble(dynamic v, {required double fallback}) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }

  static int _toInt(dynamic v, {required int fallback}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static bool _toBool(dynamic v, {required bool fallback}) {
    if (v is bool) return v;
    final s = '$v'.toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }
}

/// A JSON-safe overlay definition.
/// These are "recipes" the client maps to actual overlay widgets.
///
/// Example:
/// { "kind":"vignette", "props": { "opacity": 0.18 } }
/// { "kind":"softGlow", "props": { "opacity": 0.12 } }
class DepthOverlaySpec {
  /// Overlay “type” (client-defined catalog).
  final String kind;

  /// JSON-safe props bag (numbers, strings, bools, arrays, maps).
  final Map<String, dynamic> props;

  const DepthOverlaySpec({
    required this.kind,
    this.props = const {},
  });

  Map<String, dynamic> toJson({bool snakeCase = false}) {
    // Here snakeCase isn't critical; kept for symmetry.
    return {
      'kind': kind,
      'props': props,
    };
  }

  factory DepthOverlaySpec.fromJson(Map<String, dynamic> json) {
    return DepthOverlaySpec(
      kind: (json['kind'] ?? '').toString(),
      props: json['props'] is Map ? Map<String, dynamic>.from(json['props'] as Map) : const {},
    );
  }
}

/// Stable action kinds the backend can send later.
/// Keep these keys stable; treat them like an API contract.
enum DepthCardActionKind {
  /// Navigate (internal route) or open external URL.
  openUrl,

  /// Open a profile (userId should be in payload).
  openProfile,

  /// Open a modal/details sheet.
  showDetails,

  /// Avatar package install / download.
  installPackage,

  /// Mission/bonus claim.
  claimReward,

  /// Fallback for custom server behaviors.
  custom,
}

/// JSON-safe action spec.
/// UI is not embedded here; mapper converts this into CardOverlayAction.
class DepthCardActionSpec {
  /// Unique action id (useful for analytics/event queue).
  final String id;

  /// Tooltip/label for UI button.
  final String label;

  /// Icon key (mapped in mapper; backend sends string).
  /// Example: "info", "download", "open", "gift"
  final String iconKey;

  /// What the action means.
  final DepthCardActionKind kind;

  /// Arbitrary JSON payload for action execution.
  /// Example:
  /// - { "url": "https://..." }
  /// - { "route": "/profile/123" }
  /// - { "userId": "abc" }
  /// - { "packageId": "animals", "version": "1.0.0" }
  final Map<String, dynamic> payload;

  /// Optional style key for future (e.g. "primary", "danger").
  /// For now it is not used by UI.
  final String? styleKey;

  const DepthCardActionSpec({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.kind,
    this.payload = const {},
    this.styleKey,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'iconKey': iconKey,
    'kind': kind.name,
    'payload': payload,
    'styleKey': styleKey,
  };

  factory DepthCardActionSpec.fromJson(Map<String, dynamic> json) {
    final kindStr = (json['kind'] ?? 'custom').toString();
    final kind = DepthCardActionKind.values.firstWhere(
          (k) => k.name == kindStr,
      orElse: () => DepthCardActionKind.custom,
    );

    return DepthCardActionSpec(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      iconKey: (json['iconKey'] ?? 'info').toString(),
      kind: kind,
      payload: json['payload'] is Map ? Map<String, dynamic>.from(json['payload'] as Map) : const {},
      styleKey: json['styleKey']?.toString(),
    );
  }
}