/// Backend-driven app configuration fetched from /api/v1/app/config on startup.
///
/// Safe defaults keep all non-core features disabled so the app is always in a
/// known state even when the backend is unreachable or returns a partial response.
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
    this.realtimeMultiplayerEnabled = false,
    this.matchmakingEnabled = false,
    this.tournamentsEnabled = false,
    this.cryptoEnabled = false,
    // Social (Friends/Parties) ships enabled; it is only turned off
    // per-player via moderation (ban) driven by the backend config.
    this.socialEnabled = true,
    this.skillTreeEnabled = false,
    this.notificationsEnabled = false,
    this.advancedSeasonsEnabled = false,
    this.tomPersonalizationEnabled = false,
    this.aiSidecarEnabled = false,
    this.guildsEnabled = false,
    this.territoryEnabled = false,
    this.guardiansEnabled = false,
    this.experimentsEnabled = false,
    this.rewardReactorEnabled = true,
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
      realtimeMultiplayerEnabled: flag('realtimeMultiplayerEnabled'),
      matchmakingEnabled: flag('matchmakingEnabled'),
      tournamentsEnabled: flag('tournamentsEnabled'),
      cryptoEnabled: flag('cryptoEnabled'),
      socialEnabled: flag('socialEnabled', fallback: true),
      skillTreeEnabled: flag('skillTreeEnabled'),
      notificationsEnabled: flag('notificationsEnabled'),
      advancedSeasonsEnabled: flag('advancedSeasonsEnabled'),
      tomPersonalizationEnabled: flag('tomPersonalizationEnabled'),
      aiSidecarEnabled: flag('aiSidecarEnabled'),
      guildsEnabled: flag('guildsEnabled'),
      territoryEnabled: flag('territoryEnabled'),
      guardiansEnabled: flag('guardiansEnabled'),
      experimentsEnabled: flag('experimentsEnabled'),
      rewardReactorEnabled: flag('rewardReactorEnabled', fallback: true),
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
