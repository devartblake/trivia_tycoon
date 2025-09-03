class LeaderboardFilterSettings {
  final bool showVerifiedOnly;
  final bool showPremiumOnly;
  final bool showPowerUsersOnly;
  final bool excludeBots;
  final String? deviceType;
  final String? notificationPreference;

  LeaderboardFilterSettings({
    this.showVerifiedOnly = false,
    this.showPremiumOnly = false,
    this.showPowerUsersOnly = false,
    this.excludeBots = false,
    this.deviceType,
    this.notificationPreference,
  });

  Map<String, dynamic> toJson() => {
    'showVerifiedOnly': showVerifiedOnly,
    'showPremiumOnly': showPremiumOnly,
    'showPowerUsersOnly': showPowerUsersOnly,
    'excludeBots': excludeBots,
    'deviceType': deviceType,
    'notificationPreference': notificationPreference,
  };

  factory LeaderboardFilterSettings.fromJson(Map<String, dynamic> json) {
    return LeaderboardFilterSettings(
      showVerifiedOnly: json['showVerifiedOnly'] ?? false,
      showPremiumOnly: json['showPremiumOnly'] ?? false,
      showPowerUsersOnly: json['showPowerUsersOnly'] ?? false,
      excludeBots: json['excludeBots'] ?? false,
      deviceType: json['deviceType'],
      notificationPreference: json['notificationPreference'],
    );
  }

  LeaderboardFilterSettings copyWith({
    bool? showVerifiedOnly,
    bool? showPremiumOnly,
    bool? showPowerUsersOnly,
    bool? excludeBots,
    String? deviceType,
    String? notificationPreference,
  }) {
    return LeaderboardFilterSettings(
      showVerifiedOnly: showVerifiedOnly ?? this.showVerifiedOnly,
      showPremiumOnly: showPremiumOnly ?? this.showPremiumOnly,
      showPowerUsersOnly: showPowerUsersOnly ?? this.showPowerUsersOnly,
      excludeBots: excludeBots ?? this.excludeBots,
      deviceType: deviceType ?? this.deviceType,
      notificationPreference: notificationPreference ?? this.notificationPreference,
    );
  }
}
