import 'package:flutter/material.dart';

/// Represents the state of the leaderboard filters.
///
/// Using an immutable class with a `copyWith` method is a best practice
/// for managing state in state management solutions like Riverpod.
@immutable
class AdminFilterState {
  final bool showVerified;
  final bool showPremium;
  final bool showBots;
  final bool showPowerUsers;
  final Set<String> deviceTypes;
  final String notificationMethod;
  final bool isLoading;

  const AdminFilterState({
    this.showVerified = false,
    this.showPremium = false,
    this.showBots = false,
    this.showPowerUsers = false,
    this.deviceTypes = const {},
    this.notificationMethod = 'all',
    this.isLoading = true,
  });

  /// Creates a copy of the current state with updated values.
  AdminFilterState copyWith({
    bool? showVerified,
    bool? showPremium,
    bool? showBots,
    bool? showPowerUsers,
    Set<String>? deviceTypes,
    String? notificationMethod,
    bool? isLoading,
  }) {
    return AdminFilterState(
      showVerified: showVerified ?? this.showVerified,
      showPremium: showPremium ?? this.showPremium,
      showBots: showBots ?? this.showBots,
      showPowerUsers: showPowerUsers ?? this.showPowerUsers,
      deviceTypes: deviceTypes ?? this.deviceTypes,
      notificationMethod: notificationMethod ?? this.notificationMethod,
      isLoading: isLoading ?? this.isLoading,
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