import 'package:flutter/material.dart';

/// Represents the state of the admin filters
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
  final String? dateRange;
  final int? minScore;
  final int? maxScore;
  final bool isLoading;

  const AdminFilterState({
    this.showVerified = false,
    this.showPremium = false,
    this.showBots = false,
    this.showPowerUsers = false,
    this.deviceTypes = const {},
    this.notificationMethod = 'all',
    this.dateRange = '7days',
    this.minScore = 0,
    this.maxScore = 1000,
    this.isLoading = true,
  });

  /// Creates a copy of the current state with updated values
  AdminFilterState copyWith({
    bool? showVerified,
    bool? showPremium,
    bool? showBots,
    bool? showPowerUsers,
    Set<String>? deviceTypes,
    String? notificationMethod,
    String? dateRange,
    int? minScore,
    int? maxScore,
    bool? isLoading,
  }) {
    return AdminFilterState(
      showVerified: showVerified ?? this.showVerified,
      showPremium: showPremium ?? this.showPremium,
      showBots: showBots ?? this.showBots,
      showPowerUsers: showPowerUsers ?? this.showPowerUsers,
      deviceTypes: deviceTypes ?? this.deviceTypes,
      notificationMethod: notificationMethod ?? this.notificationMethod,
      dateRange: dateRange ?? this.dateRange,
      minScore: minScore ?? this.minScore,
      maxScore: maxScore ?? this.maxScore,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Check if any filters are active (non-default)
  bool get hasActiveFilters {
    return showVerified ||
        showPremium ||
        showBots ||
        showPowerUsers ||
        deviceTypes.isNotEmpty ||
        notificationMethod != 'all' ||
        dateRange != '7days' ||
        minScore != 0 ||
        maxScore != 1000;
  }

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (showVerified) count++;
    if (showPremium) count++;
    if (showBots) count++;
    if (showPowerUsers) count++;
    if (deviceTypes.isNotEmpty) count++;
    if (notificationMethod != 'all') count++;
    if (dateRange != '7days') count++;
    if (minScore != 0 || maxScore != 1000) count++;
    return count;
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
    'showVerified': showVerified,
    'showPremium': showPremium,
    'showBots': showBots,
    'showPowerUsers': showPowerUsers,
    'deviceTypes': deviceTypes.toList(),
    'notificationMethod': notificationMethod,
    'dateRange': dateRange,
    'minScore': minScore,
    'maxScore': maxScore,
  };

  /// Deserialize from JSON
  factory AdminFilterState.fromJson(Map<String, dynamic> json) {
    return AdminFilterState(
      showVerified: json['showVerified'] ?? false,
      showPremium: json['showPremium'] ?? false,
      showBots: json['showBots'] ?? false,
      showPowerUsers: json['showPowerUsers'] ?? false,
      deviceTypes: Set<String>.from(json['deviceTypes'] ?? []),
      notificationMethod: json['notificationMethod'] ?? 'all',
      dateRange: json['dateRange'] ?? '7days',
      minScore: json['minScore'] ?? 0,
      maxScore: json['maxScore'] ?? 1000,
      isLoading: false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AdminFilterState &&
        other.showVerified == showVerified &&
        other.showPremium == showPremium &&
        other.showBots == showBots &&
        other.showPowerUsers == showPowerUsers &&
        other.deviceTypes == deviceTypes &&
        other.notificationMethod == notificationMethod &&
        other.dateRange == dateRange &&
        other.minScore == minScore &&
        other.maxScore == maxScore &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return Object.hash(
      showVerified,
      showPremium,
      showBots,
      showPowerUsers,
      deviceTypes,
      notificationMethod,
      dateRange,
      minScore,
      maxScore,
      isLoading,
    );
  }

  @override
  String toString() {
    return 'AdminFilterState(showVerified: $showVerified, showPremium: $showPremium, '
        'showBots: $showBots, showPowerUsers: $showPowerUsers, '
        'deviceTypes: $deviceTypes, notificationMethod: $notificationMethod, '
        'dateRange: $dateRange, minScore: $minScore, maxScore: $maxScore, '
        'isLoading: $isLoading)';
  }
}
