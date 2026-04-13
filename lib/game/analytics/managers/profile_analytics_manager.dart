import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/manager/log_manager.dart';

/// Model for profile analytics events
class ProfileAnalyticsEvent {
  final String eventId;
  final String action; // 'create', 'switch', 'delete', 'edit'
  final String profileId;
  final String? profileName;
  final String? fromProfileId;
  final DateTime timestamp;
  final Map<String, dynamic> additionalData;

  ProfileAnalyticsEvent({
    required this.eventId,
    required this.action,
    required this.profileId,
    this.profileName,
    this.fromProfileId,
    required this.timestamp,
    this.additionalData = const {},
  });

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'action': action,
    'profile_id': profileId,
    if (profileName != null) 'profile_name': profileName,
    if (fromProfileId != null) 'from_profile_id': fromProfileId,
    'timestamp': timestamp.toIso8601String(),
    ...additionalData,
  };
}

/// Provider for the ProfileAnalyticsManager
final profileAnalyticsManagerProvider =
AsyncNotifierProvider<ProfileAnalyticsManager, List<ProfileAnalyticsEvent>>(
      () => ProfileAnalyticsManager(),
);

/// Manager for handling profile-related analytics without breaking core functionality
class ProfileAnalyticsManager extends AsyncNotifier<List<ProfileAnalyticsEvent>> {
  final List<ProfileAnalyticsEvent> _pendingEvents = [];

  @override
  Future<List<ProfileAnalyticsEvent>> build() async {
    // Initialize with empty list - events are tracked as they happen
    return [];
  }

  /// Track profile creation with safe analytics
  Future<void> trackProfileCreated({
    required String profileId,
    required String profileName,
    required String ageGroup,
    String? avatar,
  }) async {
    final event = ProfileAnalyticsEvent(
      eventId: DateTime.now().millisecondsSinceEpoch.toString(),
      action: 'create',
      profileId: profileId,
      profileName: profileName,
      timestamp: DateTime.now(),
      additionalData: {
        'age_group': ageGroup,
        'has_avatar': avatar != null,
        'avatar_path': avatar,
      },
    );

    await _trackEvent(event);
    LogManager.logProfileCreated(profileName, profileId);
  }

  /// Track profile switching with safe analytics
  Future<void> trackProfileSwitch({
    required String fromProfileId,
    required String toProfileId,
    required String toProfileName,
    String? fromProfileName,
  }) async {
    final event = ProfileAnalyticsEvent(
      eventId: DateTime.now().millisecondsSinceEpoch.toString(),
      action: 'switch',
      profileId: toProfileId,
      profileName: toProfileName,
      fromProfileId: fromProfileId,
      timestamp: DateTime.now(),
      additionalData: {
        if (fromProfileName != null) 'from_profile_name': fromProfileName,
      },
    );

    await _trackEvent(event);
    LogManager.logProfileSwitched(fromProfileName ?? 'Unknown', toProfileName);
  }

  /// Track profile deletion with safe analytics
  Future<void> trackProfileDeleted({
    required String profileId,
    required String profileName,
  }) async {
    final event = ProfileAnalyticsEvent(
      eventId: DateTime.now().millisecondsSinceEpoch.toString(),
      action: 'delete',
      profileId: profileId,
      profileName: profileName,
      timestamp: DateTime.now(),
    );

    await _trackEvent(event);
    LogManager.logProfileDeleted(profileName, profileId);
  }

  /// Track profile editing with safe analytics
  Future<void> trackProfileEdited({
    required String profileId,
    required String profileName,
    Map<String, dynamic>? changes,
  }) async {
    final event = ProfileAnalyticsEvent(
      eventId: DateTime.now().millisecondsSinceEpoch.toString(),
      action: 'edit',
      profileId: profileId,
      profileName: profileName,
      timestamp: DateTime.now(),
      additionalData: {
        if (changes != null) 'changes': changes,
      },
    );

    await _trackEvent(event);
    LogManager.info("Profile edited: '$profileName' (ID: $profileId)", source: 'ProfileManager');
  }

  /// Internal method to safely track events
  Future<void> _trackEvent(ProfileAnalyticsEvent event) async {
    try {
      // Cast existing state and add new event
      final existingEvents = state.valueOrNull ?? <ProfileAnalyticsEvent>[];
      final currentEvents = [...existingEvents, event];
      state = AsyncData(currentEvents);

      // ... rest of the method
    } catch (e) {
      LogManager.logProfileError('analytics_tracking', e.toString());
      _pendingEvents.add(event);
    }
  }

  /// Retry sending pending events when analytics becomes available
  Future<void> retryPendingEvents() async {
    if (_pendingEvents.isEmpty) return;

    try {
      // For now, just log that we have pending events
      // This can be expanded later when analytics integration is ready
      LogManager.info(
        'Found ${_pendingEvents.length} pending profile analytics events',
        source: 'ProfileAnalyticsManager',
      );

      // Events remain queued; wire up analytics service here when backend is available

    } catch (e) {
      LogManager.logProfileError('pending_analytics_retry', e.toString());
    }
  }

  /// Get profile analytics summary
  Map<String, dynamic> getAnalyticsSummary() {
    final events = state.valueOrNull ?? [];
    final eventsByAction = <String, int>{};

    for (final event in events) {
      eventsByAction[event.action] = (eventsByAction[event.action] ?? 0) + 1;
    }

    return {
      'total_events': events.length,
      'pending_events': _pendingEvents.length,
      'events_by_action': eventsByAction,
      'last_event_time': events.isNotEmpty
          ? events.last.timestamp.toIso8601String()
          : null,
    };
  }

  /// Get recent profile analytics events
  List<ProfileAnalyticsEvent> getRecentEvents({int limit = 10}) {
    final events = state.valueOrNull ?? [];
    return events.reversed.take(limit).toList();
  }

  /// Clear analytics history (for privacy/debugging)
  Future<void> clearAnalyticsHistory() async {
    try {
      state = const AsyncData([]);
      _pendingEvents.clear();
      LogManager.info('Profile analytics history cleared', source: 'ProfileAnalyticsManager');
    } catch (e) {
      LogManager.logProfileError('clear_analytics', e.toString());
    }
  }
}
