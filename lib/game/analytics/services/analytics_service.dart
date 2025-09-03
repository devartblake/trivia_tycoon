import 'dart:async';

import 'package:trivia_tycoon/core/services/event_queue_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/engagement_entry.dart';
import '../models/mission_analytics_entry.dart';
import '../models/retention_entry.dart';

/// Handles fetching analytics data from the API or local storage.
class AnalyticsService {
  final ApiService apiService;
  final EventQueueService eventQueueService;
  Timer? _retryTimer;

  AnalyticsService(this.apiService, this.eventQueueService);

  /// Initializes retry logic once at startup
  Future<void> initialize() async {
    await retryQueuedEvents();
    _startRetryLoop();
  }

  /// Logs a custom analytic event (debug only for now)
  Future<void> logEvent(String name, Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint("📊 Analytics Event: $name → $data");
    }
    // Optionally send to API:
    // await apiService.post('/analytics/events', {'event': name, 'payload': data});
  }

  /// Tracks basic startup analytics (can be expanded)
  Future<void> trackStartup() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Simulate a startup log, could use actual API call here
    await apiService.sendEvent('startup_event', {
      'timestamp': DateTime.now().toIso8601String(),
    });
    final payload = {'timestamp': DateTime.now().toIso8601String()};
    await _sendWithRetry('/analytics/startup_event', payload);
    if (kDebugMode) debugPrint('[📊 Analytics] App startup tracked.');
  }

  /// Tracks app session start with extended metadata
  Future<void> trackAppSession({
    required String userId,
    required String platform,
    required String appVersion,
  }) async {
    final sessionId = const Uuid().v4();
    final deviceId = const Uuid().v5(Uuid.NAMESPACE_URL, userId);
    final timestamp = DateTime.now().toUtc().toIso8601String();

    final payload = {
      'session_id': sessionId,
      'device_id': deviceId,
      'user_id': userId,
      'timestamp': timestamp,
      'platform': platform,
      'app_version': appVersion,
    };

    await apiService.post('/analytics/session_start', data: payload);
  }

  /// Generic wrapper for API events with retry fallback
  Future<void> _sendWithRetry(String endpoint, Map<String, dynamic> data) async {
    try {
      await apiService.post(endpoint, data: data);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to send event to $endpoint, queuing: $e');
      await eventQueueService.enqueueEvent(endpoint, data);
    }
  }

  /// Manually trigger event queue retry
  Future<void> retryQueuedEvents() async {
    try {
      await eventQueueService.retryQueuedEvents((endpoint, payload) async {
        await apiService.post(endpoint, data: payload);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Event queue retry failed: $e');
    }
  }

  /// Starts a periodic background timer to retry failed events
  void _startRetryLoop() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(minutes: 5), (_) => retryQueuedEvents());
  }

  /// Stops retry timer when no longer needed (optional)
  void dispose() {
    _retryTimer?.cancel();
  }

  /// Fetches mock mission analytics data
  Future<List<MissionAnalyticsEntry>> fetchMissionAnalytics() async {
    final jsonData = await apiService.getMockData('mock_mission_analytics.json');
    return (jsonData as List<dynamic>)
        .map((e) => MissionAnalyticsEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches mock user engagement analytics data
  Future<List<EngagementEntry>> fetchEngagementAnalytics() async {
    final jsonData = await apiService.getMockData('mock_engagement_analytics.json');
    return (jsonData as List<dynamic>)
        .map((e) => EngagementEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches mock user retention analytics data
  Future<List<RetentionEntry>> fetchRetentionAnalytics() async {
    final jsonData = await apiService.getMockData('mock_retention_analytics.json');
    return (jsonData as List<dynamic>)
        .map((e) => RetentionEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
 // TODO: Would like to wire this into a centralized logging system or explore persistence for offline tracking?
