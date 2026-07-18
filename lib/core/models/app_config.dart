/// Backend-driven app configuration fetched from /api/v1/app/config on startup.
///
/// Features are available to everyone by default; access is only removed from
/// banned/suspended accounts (enforced backend-side). Crypto and the dev-tester
/// tools stay off by default until explicitly enabled by the backend/admin.
class FeatureFlags {
  final bool coreTriviaEnabled;
  final bool walletEnabled;
  final bool leaderboardEnabled;
  final bool storeEnabled;
  final bool realtimeMultiplayerEnabled;
  final bool matchmakingEnabled;
  final bool tournamentsEnabled;
  final bool cryptoEnabled;
  final bool socialEnabled;
  final bool skillTreeEnabled;
  final bool notificationsEnabled;
  final bool advancedSeasonsEnabled;
  final bool tomPersonalizationEnabled;
  final bool aiSidecarEnabled;
  final bool guildsEnabled;
  final bool territoryEnabled;
  final bool guardiansEnabled;
  final bool experimentsEnabled;
  final bool rewardReactorEnabled;
  final bool devTesterEnabled;

  const FeatureFlags({
    this.coreTriviaEnabled = true,
    this.walletEnabled = true,
    this.leaderboardEnabled = true,
    this.storeEnabled = true,
    this.realtimeMultiplayerEnabled = true,
    this.matchmakingEnabled = true,
    this.tournamentsEnabled = true,
    // Crypto stays gated until the feature is finished / admin-enabled.
    this.cryptoEnabled = false,
    // Everything below is available to all users; access is only removed
    // per-player via moderation (ban/suspend) enforced by the backend.
    this.socialEnabled = true,
    this.skillTreeEnabled = true,
    this.notificationsEnabled = true,
    this.advancedSeasonsEnabled = true,
    this.tomPersonalizationEnabled = true,
    this.aiSidecarEnabled = true,
    this.guildsEnabled = true,
    this.territoryEnabled = true,
    this.guardiansEnabled = true,
    this.experimentsEnabled = true,
    this.rewardReactorEnabled = true,
    // Dev-only tooling stays off in normal builds.
    this.devTesterEnabled = false,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    bool flag(String key, {bool fallback = false}) =>
        json[key] as bool? ?? fallback;
    return FeatureFlags(
      coreTriviaEnabled: flag('coreTriviaEnabled', fallback: true),
      walletEnabled: flag('walletEnabled', fallback: true),
      leaderboardEnabled: flag('leaderboardEnabled', fallback: true),
      storeEnabled: flag('storeEnabled', fallback: true),
      realtimeMultiplayerEnabled:
          flag('realtimeMultiplayerEnabled', fallback: true),
      matchmakingEnabled: flag('matchmakingEnabled', fallback: true),
      tournamentsEnabled: flag('tournamentsEnabled', fallback: true),
      // Crypto remains opt-in (backend defaults it off).
      cryptoEnabled: flag('cryptoEnabled'),
      socialEnabled: flag('socialEnabled', fallback: true),
      skillTreeEnabled: flag('skillTreeEnabled', fallback: true),
      notificationsEnabled: flag('notificationsEnabled', fallback: true),
      advancedSeasonsEnabled: flag('advancedSeasonsEnabled', fallback: true),
      tomPersonalizationEnabled:
          flag('tomPersonalizationEnabled', fallback: true),
      aiSidecarEnabled: flag('aiSidecarEnabled', fallback: true),
      guildsEnabled: flag('guildsEnabled', fallback: true),
      territoryEnabled: flag('territoryEnabled', fallback: true),
      guardiansEnabled: flag('guardiansEnabled', fallback: true),
      experimentsEnabled: flag('experimentsEnabled', fallback: true),
      rewardReactorEnabled: flag('rewardReactorEnabled', fallback: true),
      // Dev-only tooling stays off unless the backend explicitly enables it.
      devTesterEnabled: flag('devTesterEnabled'),
    );
  }

  /// Safe defaults for Alpha/Beta — only core features enabled.
  static const FeatureFlags defaultAlpha = FeatureFlags();
}

class AppConfig {
  final String environment;
  final String minimumClientVersion;
  final FeatureFlags features;

  const AppConfig({
    required this.environment,
    required this.minimumClientVersion,
    required this.features,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['features'];
    return AppConfig(
      environment: json['environment'] as String? ?? 'unknown',
      minimumClientVersion: json['minimumClientVersion'] as String? ?? '0.0.0',
      features: featuresJson is Map<String, dynamic>
          ? FeatureFlags.fromJson(featuresJson)
          : FeatureFlags.defaultAlpha,
    );
  }

  static const AppConfig defaultAlpha = AppConfig(
    environment: 'alpha',
    minimumClientVersion: '0.0.0',
    features: FeatureFlags.defaultAlpha,
  );
}
