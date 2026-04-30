/// DTOs for the Unified Personalization + A/B Experiment endpoints.
///
/// API contract: docs/flutter_personalization_experiments_handoff_2026-04-30.md
/// Flutter is a pure renderer — no scoring or decision logic lives here.

// ── Player Mind Profile ───────────────────────────────────────────────────────

class PlayerMindProfileDto {
  final String playerId;
  final double confidenceLevel;
  final double riskTolerance;
  final String preferredPace;
  final String learningStyle;
  final String competitivePreference;
  final String socialPreference;
  final double churnRiskScore;
  final double frustrationRiskScore;
  final double rewardSensitivityScore;
  final double storeAffinityScore;
  final double notificationFatigueScore;
  final String archetype;
  final Map<String, double> categoryStrengths;
  final Map<String, double> categoryWeaknesses;
  final bool personalizationEnabled;
  final bool sidecarScoringEnabled;
  final String? lastCalculatedAt;

  const PlayerMindProfileDto({
    required this.playerId,
    this.confidenceLevel = 0.5,
    this.riskTolerance = 0.5,
    this.preferredPace = 'steady',
    this.learningStyle = 'visual',
    this.competitivePreference = 'solo',
    this.socialPreference = 'low',
    this.churnRiskScore = 0.0,
    this.frustrationRiskScore = 0.0,
    this.rewardSensitivityScore = 0.5,
    this.storeAffinityScore = 0.5,
    this.notificationFatigueScore = 0.0,
    this.archetype = 'steady_learner',
    this.categoryStrengths = const {},
    this.categoryWeaknesses = const {},
    this.personalizationEnabled = true,
    this.sidecarScoringEnabled = true,
    this.lastCalculatedAt,
  });

  factory PlayerMindProfileDto.fromJson(Map<String, dynamic> j) {
    double _d(String key, [double fallback = 0.0]) =>
        (j[key] as num?)?.toDouble() ?? fallback;
    Map<String, double> _dmap(String key) {
      final raw = j[key];
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0));
    }

    return PlayerMindProfileDto(
      playerId: j['playerId']?.toString() ?? '',
      confidenceLevel: _d('confidenceLevel', 0.5),
      riskTolerance: _d('riskTolerance', 0.5),
      preferredPace: j['preferredPace']?.toString() ?? 'steady',
      learningStyle: j['learningStyle']?.toString() ?? 'visual',
      competitivePreference: j['competitivePreference']?.toString() ?? 'solo',
      socialPreference: j['socialPreference']?.toString() ?? 'low',
      churnRiskScore: _d('churnRiskScore'),
      frustrationRiskScore: _d('frustrationRiskScore'),
      rewardSensitivityScore: _d('rewardSensitivityScore', 0.5),
      storeAffinityScore: _d('storeAffinityScore', 0.5),
      notificationFatigueScore: _d('notificationFatigueScore'),
      archetype: j['archetype']?.toString() ?? 'steady_learner',
      categoryStrengths: _dmap('categoryStrengths'),
      categoryWeaknesses: _dmap('categoryWeaknesses'),
      personalizationEnabled: j['personalizationEnabled'] as bool? ?? true,
      sidecarScoringEnabled: j['sidecarScoringEnabled'] as bool? ?? true,
      lastCalculatedAt: j['lastCalculatedAt']?.toString(),
    );
  }

  /// Shorthand checks used by UI gating logic.
  bool get shouldShowRetentionNudge => churnRiskScore >= 0.8;
  bool get shouldDisableHardMode => frustrationRiskScore >= 0.75;
  bool get shouldReducePushBadges => notificationFatigueScore >= 0.7;
}

// ── Coach Brief ───────────────────────────────────────────────────────────────

class CoachBriefDto {
  final String? id;
  final String title;
  final String message;
  final String recommendedAction;
  final String targetRoute;
  final String tone;

  const CoachBriefDto({
    this.id,
    required this.title,
    required this.message,
    this.recommendedAction = '',
    this.targetRoute = '',
    this.tone = 'encouraging',
  });

  factory CoachBriefDto.fromJson(Map<String, dynamic> j) => CoachBriefDto(
        id: j['id']?.toString(),
        title: j['title']?.toString() ?? '',
        message: j['message']?.toString() ?? '',
        recommendedAction: j['recommendedAction']?.toString() ?? '',
        targetRoute: j['targetRoute']?.toString() ?? '',
        tone: j['tone']?.toString() ?? 'encouraging',
      );
}

// ── Recommendation ────────────────────────────────────────────────────────────

class PlayerRecommendationDto {
  final String id;
  final String type;
  final String source;
  final int priority;
  final double score;
  final Map<String, dynamic> payload;
  final String? expiresAt;

  const PlayerRecommendationDto({
    required this.id,
    required this.type,
    this.source = 'sidecar',
    this.priority = 1,
    this.score = 0.0,
    this.payload = const {},
    this.expiresAt,
  });

  factory PlayerRecommendationDto.fromJson(Map<String, dynamic> j) =>
      PlayerRecommendationDto(
        id: j['id']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        source: j['source']?.toString() ?? 'sidecar',
        priority: (j['priority'] as num?)?.toInt() ?? 1,
        score: (j['score'] as num?)?.toDouble() ?? 0.0,
        payload: (j['payload'] as Map<String, dynamic>?) ?? {},
        expiresAt: j['expiresAt']?.toString(),
      );
}

// ── Home Personalization ──────────────────────────────────────────────────────

class PlayerHomePersonalizationDto {
  final String playerId;
  final String recommendedMode;
  final String recommendedCategory;
  final String recommendedDifficulty;
  final List<PlayerRecommendationDto> recommendations;
  final CoachBriefDto? coachBrief;

  const PlayerHomePersonalizationDto({
    required this.playerId,
    this.recommendedMode = 'solo',
    this.recommendedCategory = '',
    this.recommendedDifficulty = 'medium',
    this.recommendations = const [],
    this.coachBrief,
  });

  factory PlayerHomePersonalizationDto.fromJson(Map<String, dynamic> j) {
    final rawRecs = j['recommendations'];
    final recs = rawRecs is List
        ? rawRecs
            .whereType<Map<String, dynamic>>()
            .map(PlayerRecommendationDto.fromJson)
            .toList()
        : <PlayerRecommendationDto>[];

    final rawBrief = j['coachBrief'];
    final brief = rawBrief is Map<String, dynamic>
        ? CoachBriefDto.fromJson(rawBrief)
        : null;

    return PlayerHomePersonalizationDto(
      playerId: j['playerId']?.toString() ?? '',
      recommendedMode: j['recommendedMode']?.toString() ?? 'solo',
      recommendedCategory: j['recommendedCategory']?.toString() ?? '',
      recommendedDifficulty: j['recommendedDifficulty']?.toString() ?? 'medium',
      recommendations: recs,
      coachBrief: brief,
    );
  }

  /// Top 3 recommendations ordered by priority ASC (as per contract).
  List<PlayerRecommendationDto> get topRecommendations {
    final sorted = [...recommendations]..sort((a, b) => a.priority.compareTo(b.priority));
    return sorted.take(3).toList();
  }
}

// ── Experiments ───────────────────────────────────────────────────────────────

class ExperimentAssignmentDto {
  final String experimentKey;
  final String variantKey;
  final bool isControl;
  final Map<String, dynamic> config;

  const ExperimentAssignmentDto({
    required this.experimentKey,
    required this.variantKey,
    this.isControl = true,
    this.config = const {},
  });

  factory ExperimentAssignmentDto.fromJson(Map<String, dynamic> j) =>
      ExperimentAssignmentDto(
        experimentKey: j['experimentKey']?.toString() ?? '',
        variantKey: j['variantKey']?.toString() ?? 'control',
        isControl: j['isControl'] as bool? ?? true,
        config: (j['config'] as Map<String, dynamic>?) ?? {},
      );

  // Typed config accessors (see Part 6 of handoff doc)
  bool getBool(String key, {bool fallback = false}) =>
      config[key] is bool ? config[key] as bool : fallback;

  String getString(String key, {String fallback = ''}) =>
      config[key] is String ? config[key] as String : fallback;

  int getInt(String key, {int fallback = 0}) =>
      config[key] is int ? config[key] as int : fallback;
}

class PlayerExperimentsDto {
  final String playerId;
  final List<ExperimentAssignmentDto> assignments;

  const PlayerExperimentsDto({
    required this.playerId,
    this.assignments = const [],
  });

  factory PlayerExperimentsDto.fromJson(Map<String, dynamic> j) {
    final rawList = j['assignments'];
    final assignments = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(ExperimentAssignmentDto.fromJson)
            .toList()
        : <ExperimentAssignmentDto>[];
    return PlayerExperimentsDto(
      playerId: j['playerId']?.toString() ?? '',
      assignments: assignments,
    );
  }
}

class SingleExperimentResultDto {
  final bool enrolled;
  final String experimentKey;
  final ExperimentAssignmentDto? assignment;

  const SingleExperimentResultDto({
    required this.enrolled,
    required this.experimentKey,
    this.assignment,
  });

  factory SingleExperimentResultDto.fromJson(Map<String, dynamic> j) {
    final rawAssignment = j['assignment'];
    return SingleExperimentResultDto(
      enrolled: j['enrolled'] as bool? ?? false,
      experimentKey: j['experimentKey']?.toString() ?? '',
      assignment: rawAssignment is Map<String, dynamic>
          ? ExperimentAssignmentDto.fromJson(rawAssignment)
          : null,
    );
  }
}

// ── Behaviour Event ───────────────────────────────────────────────────────────

class BehaviourEventDto {
  final String eventType;
  final String eventSource;
  final String? category;
  final String? difficulty;
  final String? mode;
  final Map<String, dynamic> metadata;
  final String occurredAt;

  BehaviourEventDto({
    required this.eventType,
    this.eventSource = 'app',
    this.category,
    this.difficulty,
    this.mode,
    this.metadata = const {},
    String? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> toJson() => {
        'eventType': eventType,
        'eventSource': eventSource,
        if (category != null) 'category': category,
        if (difficulty != null) 'difficulty': difficulty,
        if (mode != null) 'mode': mode,
        if (metadata.isNotEmpty) 'metadata': metadata,
        'occurredAt': occurredAt,
      };
}
