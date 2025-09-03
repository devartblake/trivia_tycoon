class AdminFilterState {
  final bool showVerified;
  final bool showPremium;
  final bool showBots;
  final bool showPowerUsers;
  final Set<String> deviceTypes;
  final String notificationMethod;

  AdminFilterState({
    this.showVerified = false,
    this.showPremium = false,
    this.showBots = false,
    this.showPowerUsers = false,
    this.deviceTypes = const {},
    this.notificationMethod = 'all',
  });

  AdminFilterState copyWith({
    bool? showVerified,
    bool? showPremium,
    bool? showBots,
    bool? showPowerUsers,
    Set<String>? deviceTypes,
    String? notificationMethod,
  }) {
    return AdminFilterState(
      showVerified: showVerified ?? this.showVerified,
      showPremium: showPremium ?? this.showPremium,
      showBots: showBots ?? this.showBots,
      showPowerUsers: showPowerUsers ?? this.showPowerUsers,
      deviceTypes: deviceTypes ?? this.deviceTypes,
      notificationMethod: notificationMethod ?? this.notificationMethod,
    );
  }

  Map<String, dynamic> toJson() => {
    'showVerified': showVerified,
    'showPremium': showPremium,
    'showBots': showBots,
    'showPowerUsers': showPowerUsers,
    'deviceTypes': deviceTypes.toList(), // Store as List
    'notificationMethod': notificationMethod,
  };

  factory AdminFilterState.fromJson(Map<String, dynamic> json) {
    return AdminFilterState(
      showVerified: json['showVerified'] ?? false,
      showPremium: json['showPremium'] ?? false,
      showBots: json['showBots'] ?? false,
      showPowerUsers: json['showPowerUsers'] ?? false,
      deviceTypes: Set<String>.from(json['deviceTypes'] ?? []),
      notificationMethod: json['notificationMethod'] ?? 'all',
    );
  }
}