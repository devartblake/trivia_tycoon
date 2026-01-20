import 'dart:convert';

import '../../../ui_components/depth_card_3d/spec/depth_card_spec.dart';

/// JSON-safe mission card model.
/// Intended for backend-driven arcade missions.
///
/// Key goals:
/// - Fully serializable
/// - Can produce a DepthCardSpec for UI display (direct embed)
/// - Keeps your existing Mission UI decoupled from DepthCardConfig
class MissionCardSpec {
  final String missionId;
  final String title;
  final String? subtitle;

  /// Progress state
  final int progress;
  final int goal;

  /// Reward hinting (data-only)
  final int rewardXp;
  final int rewardCoins;

  /// Optional: a recommended visuals spec that the UI can map via DepthCardSpecMapper.
  /// This is where you can embed backend-driven visuals for the mission card.
  final DepthCardSpec? cardVisual;

  /// Optional: mission-specific actions (data-only). These can be wired into
  /// UI handlers (e.g., "Start", "Claim", "View").
  final List<MissionActionSpec> actions;

  const MissionCardSpec({
    required this.missionId,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.goal,
    this.rewardXp = 0,
    this.rewardCoins = 0,
    this.cardVisual,
    this.actions = const [],
  });

  double get progressRatio {
    if (goal <= 0) return 0;
    final r = progress / goal;
    if (r < 0) return 0;
    if (r > 1) return 1;
    return r;
  }

  bool get isComplete => progress >= goal;

  Map<String, dynamic> toJson() => {
    'missionId': missionId,
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'progress': progress,
    'goal': goal,
    'rewardXp': rewardXp,
    'rewardCoins': rewardCoins,
    if (cardVisual != null) 'cardVisual': cardVisual!.toJson(),
    'actions': actions.map((e) => e.toJson()).toList(),
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory MissionCardSpec.fromJson(Map<String, dynamic> json) {
    final actionsRaw = json['actions'];
    return MissionCardSpec(
      missionId: (json['missionId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: json['subtitle']?.toString(),
      progress: (json['progress'] is int)
          ? json['progress'] as int
          : int.tryParse('${json['progress']}') ?? 0,
      goal: (json['goal'] is int) ? json['goal'] as int : int.tryParse('${json['goal']}') ?? 0,
      rewardXp: (json['rewardXp'] is int)
          ? json['rewardXp'] as int
          : int.tryParse('${json['rewardXp']}') ?? 0,
      rewardCoins: _int(json['rewardCoins']) ?? 0,
      cardVisual: json['cardVisual'] is Map
          ? DepthCardSpec.fromJson(Map<String, dynamic>.from(json['cardVisual'] as Map))
          : null,
      actions: actionsRaw is List
          ? actionsRaw
          .whereType<Map>()
          .map((m) => MissionActionSpec.fromJson(Map<String, dynamic>.from(m)))
          .toList()
          : const [],
    );
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

/// Data-only action model for missions.
class MissionActionSpec {
  final String id;
  final String label;
  final String intent;
  final Map<String, dynamic> payload;

  const MissionActionSpec({
    required this.id,
    required this.label,
    required this.intent,
    this.payload = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'intent': intent,
    if (payload.isNotEmpty) 'payload': payload,
  };

  factory MissionActionSpec.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return MissionActionSpec(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      intent: (json['intent'] ?? '').toString(),
      payload: rawPayload is Map ? Map<String, dynamic>.from(rawPayload) : const {},
    );
  }
}
