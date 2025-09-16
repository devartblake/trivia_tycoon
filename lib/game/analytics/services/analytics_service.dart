import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/event_queue_service.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/api_service.dart';
import '../models/engagement_entry.dart';
import '../models/mission_analytics_entry.dart';
import '../models/retention_entry.dart';

/// Handles fetching analytics data from the API with offline persistence and centralized logging.
class AnalyticsService {
  final ApiService apiService;
  final EventQueueService eventQueueService;
  Timer? _retryTimer;

  // Offline persistence boxes
  Box? _offlineEventsBox;
  Box? _sessionDataBox; // Added for enhanced session tracking

  // Connectivity monitoring
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOnline = false;
  String? _currentSessionId;

  // Enhanced state tracking
  DateTime? _sessionStartTime;
  bool _isPaused = false;
  Map<String, dynamic> _sessionMetrics = {};

  AnalyticsService(this.apiService, this.eventQueueService);

  /// Initializes the enhanced analytics service with persistence and connectivity monitoring
  Future<void> initialize() async {
    LogManager.log('Initializing AnalyticsService', level: LogLevel.info, source: 'AnalyticsService');

    try {
      // Initialize Hive box for offline events
      _offlineEventsBox = await Hive.openBox('offline_analytics_events');
      _sessionDataBox = await Hive.openBox('analytics_session_data'); // Enhanced session storage
      LogManager.log('Offline events box opened successfully', level: LogLevel.debug, source: 'AnalyticsService');

      // Set up connectivity monitoring
      await _initializeConnectivity();

      // Generate session ID and start session tracking
      await _startNewSession();

      // Start existing retry logic
      await retryQueuedEvents();
      _startRetryLoop();

      LogManager.log('AnalyticsService initialized successfully', level: LogLevel.info, source: 'AnalyticsService');
    } catch (e) {
      LogManager.log('Failed to initialize AnalyticsService: $e', level: LogLevel.error, source: 'AnalyticsService');
      rethrow;
    }
  }

  /// Start a new analytics session with enhanced tracking
  Future<void> _startNewSession() async {
    _currentSessionId = const Uuid().v4();
    _sessionStartTime = DateTime.now();
    _sessionMetrics = {
      'sessionId': _currentSessionId,
      'startTime': _sessionStartTime!.toIso8601String(),
      'eventsCount': 0,
      'screenViews': 0,
      'userActions': 0,
    };

    // Store session data for recovery
    await _sessionDataBox?.put('current_session', _sessionMetrics);

    LogManager.log('New analytics session started: $_currentSessionId',
        level: LogLevel.info, source: 'AnalyticsService');
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    try {
      // Check initial connectivity
      final connectivityResults = await Connectivity().checkConnectivity();
      _isOnline = _hasInternetConnectivity(connectivityResults);

      LogManager.log('Initial connectivity status: ${_isOnline ? 'online' : 'offline'}',
          level: LogLevel.debug, source: 'AnalyticsService');

      // Listen for connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = _hasInternetConnectivity(results);

        if (!wasOnline && _isOnline) {
          LogManager.log('Network restored - syncing offline events', level: LogLevel.info, source: 'AnalyticsService');
          _syncOfflineEvents();
        } else if (wasOnline && !_isOnline) {
          LogManager.log('Network lost - switching to offline mode', level: LogLevel.warning, source: 'AnalyticsService');
        }
      });
    } catch (e) {
      LogManager.log('Failed to initialize connectivity monitoring: $e', level: LogLevel.error, source: 'AnalyticsService');
    }
  }

  /// Check if any of the connectivity results indicate internet access
  bool _hasInternetConnectivity(List<ConnectivityResult> results) {
    return results.any((result) =>
    result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn
    );
  }

  /// Enhanced event logging with offline support
  Future<void> logEvent(String name, Map<String, dynamic> data) async {
    // Skip logging if paused
    if (_isPaused) {
      LogManager.log('Analytics paused - skipping event: $name',
          level: LogLevel.debug, source: 'AnalyticsService');
      return;
    }

    final enhancedData = {
      ...data,
      'event_id': const Uuid().v4(),
      'timestamp': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      'session_id': _currentSessionId,
    };

    // Update session metrics
    _sessionMetrics['eventsCount'] = (_sessionMetrics['eventsCount'] ?? 0) + 1;
    if (name == 'screen_view') {
      _sessionMetrics['screenViews'] = (_sessionMetrics['screenViews'] ?? 0) + 1;
    }
    if (name.contains('user_action') || name.contains('click') || name.contains('tap')) {
      _sessionMetrics['userActions'] = (_sessionMetrics['userActions'] ?? 0) + 1;
    }

    LogManager.log('Event logged: $name', level: LogLevel.info, source: 'AnalyticsService');

    if (_isOnline) {
      await _sendWithRetry('/analytics/events', {
        'event': name,
        'payload': enhancedData,
      });
    } else {
      await _storeOfflineEvent(name, enhancedData);
    }
  }

  /// Store event for offline sync
  Future<void> _storeOfflineEvent(String eventName, Map<String, dynamic> data) async {
    try {
      // Check if box is initialized
      if (_offlineEventsBox == null) {
        LogManager.log('Offline events box not initialized yet - skipping offline storage',
            level: LogLevel.warning, source: 'AnalyticsService');
        return;
      }

      final offlineEvent = {
        'event_name': eventName,
        'data': data,
        'stored_at': DateTime.now().toIso8601String(),
      };

      final key = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}';
      await _offlineEventsBox!.put(key, offlineEvent);

      LogManager.log('Event stored offline: $eventName', level: LogLevel.info, source: 'AnalyticsService');
    } catch (e) {
      LogManager.log('Failed to store offline event: $e', level: LogLevel.error, source: 'AnalyticsService');
    }
  }

  /// Sync offline events when network is restored
  Future<void> _syncOfflineEvents() async {
    try {
      if (_offlineEventsBox == null) {
        LogManager.log('Offline events box not initialized - skipping sync',
            level: LogLevel.warning, source: 'AnalyticsService');
        return;
      }

      final offlineEvents = _offlineEventsBox!.values.toList();

      if (offlineEvents.isEmpty) return;

      LogManager.log('Syncing ${offlineEvents.length} offline events', level: LogLevel.info, source: 'AnalyticsService');

      for (final event in offlineEvents) {
        final eventData = Map<String, dynamic>.from(event);
        await _sendWithRetry('/analytics/events', {
          'event': eventData['event_name'],
          'payload': eventData['data'],
        });
      }

      // Clear synced events
      await _offlineEventsBox!.clear();
      LogManager.log('Offline events synced successfully', level: LogLevel.info, source: 'AnalyticsService');

    } catch (e) {
      LogManager.log('Failed to sync offline events: $e', level: LogLevel.error, source: 'AnalyticsService');
    }
  }

  /// Enhanced startup tracking
  Future<void> trackStartup() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final payload = {
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.0.0', // Get from package info
        'platform': defaultTargetPlatform.name,
        'session_id': _currentSessionId,
      };

      await _sendWithRetry('/analytics/startup_event', payload);
      LogManager.log('App startup tracked', level: LogLevel.info, source: 'AnalyticsService');

    } catch (e) {
      LogManager.log('Startup tracking failed: $e', level: LogLevel.error, source: 'AnalyticsService');
    }
  }

  /// Enhanced session tracking
  Future<void> trackAppSession({
    required String userId,
    required String platform,
    required String appVersion,
  }) async {
    final sessionId = _currentSessionId ?? const Uuid().v4();
    final deviceId = const Uuid().v5(Uuid.NAMESPACE_URL, userId);
    final timestamp = DateTime.now().toUtc().toIso8601String();

    final payload = {
      'session_id': sessionId,
      'device_id': deviceId,
      'user_id': userId,
      'timestamp': timestamp,
      'platform': platform,
      'app_version': appVersion,
      'connectivity_status': _isOnline ? 'online' : 'offline',
    };

    LogManager.log('Session tracked for user: $userId', level: LogLevel.info, source: 'AnalyticsService');

    if (_isOnline) {
      await _sendWithRetry('/analytics/session_start', payload);
    } else {
      await _storeOfflineEvent('session_start', payload);
    }
  }

  /// Enhanced retry wrapper with better logging
  Future<void> _sendWithRetry(String endpoint, Map<String, dynamic> data) async {
    try {
      await apiService.post(endpoint, data: data);
      LogManager.log('Event sent successfully to $endpoint', level: LogLevel.debug, source: 'AnalyticsService');
    } catch (e) {
      LogManager.log('Failed to send event to $endpoint, queuing for retry',
          level: LogLevel.warning, source: 'AnalyticsService');
      await eventQueueService.enqueueEvent(endpoint, data);
    }
  }

  /// Enhanced retry for queued events
  Future<void> retryQueuedEvents() async {
    try {
      await eventQueueService.retryQueuedEvents((endpoint, payload) async {
        await apiService.post(endpoint, data: payload);
      });
      LogManager.log('Event queue retry completed', level: LogLevel.debug, source: 'AnalyticsService');
    } catch (e) {
      LogManager.log('Event queue retry failed: $e', level: LogLevel.error, source: 'AnalyticsService');
    }
  }

  /// Start enhanced retry loop
  void _startRetryLoop() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!_isPaused) {
        LogManager.log('Running periodic retry and sync', level: LogLevel.debug, source: 'AnalyticsService');
        retryQueuedEvents();
        if (_isOnline) {
          _syncOfflineEvents();
        }
      }
    });
  }

  /// End current session and send session summary
  Future<void> _endCurrentSession() async {
    if (_currentSessionId == null || _sessionStartTime == null) return;

    try {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      final sessionSummary = {
        ..._sessionMetrics,
        'endTime': DateTime.now().toIso8601String(),
        'duration': sessionDuration.inSeconds,
        'durationMinutes': sessionDuration.inMinutes,
      };

      // Send session end event
      await logEvent('session_end', sessionSummary);

      // Store session summary for later analysis
      await _sessionDataBox?.put('last_session_${_currentSessionId}', sessionSummary);

      LogManager.log('Session ended: $_currentSessionId (${sessionDuration.inMinutes} minutes)',
          level: LogLevel.info, source: 'AnalyticsService');
    } catch (e) {
      LogManager.log('Failed to end session: $e', level: LogLevel.error, source: 'AnalyticsService');
    }
  }

  /// Get offline events count (for debugging)
  int getOfflineEventsCount() {
    return _offlineEventsBox?.length ?? 0;
  }

  /// Export offline events for debugging
  Future<String> exportOfflineEventsAsJson() async {
    if (_offlineEventsBox == null) return '{"events": [], "message": "Box not initialized"}';

    final events = _offlineEventsBox!.values.toList();
    return jsonEncode({
      'exported_at': DateTime.now().toIso8601String(),
      'total_events': events.length,
      'events': events,
    });
  }

  /// Get analytics logs from LogManager (filtered by source)
  List<LogEntry> getAnalyticsLogs() {
    return LogManager.getLogs(source: 'AnalyticsService');
  }

  /// Export analytics logs as JSON
  String exportAnalyticsLogsAsJson() {
    final logs = getAnalyticsLogs();
    return jsonEncode({
      'exported_at': DateTime.now().toIso8601String(),
      'total_logs': logs.length,
      'logs': logs.map((log) => {
        'timestamp': log.timestamp.toIso8601String(),
        'level': log.level.name,
        'message': log.message,
        'source': log.source,
      }).toList(),
    });
  }

  /// Clean up resources
  void dispose() {
    _retryTimer?.cancel();
    _connectivitySubscription.cancel();
    LogManager.log('AnalyticsService disposed', level: LogLevel.info, source: 'AnalyticsService');
  }

  // Your existing analytics fetch methods remain the same...
  Future<List<MissionAnalyticsEntry>> fetchMissionAnalytics() async {
    final jsonData = await apiService.getMockData('mock_mission_analytics.json');
    return (jsonData as List<dynamic>)
        .map((e) => MissionAnalyticsEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<EngagementEntry>> fetchEngagementAnalytics() async {
    final jsonData = await apiService.getMockData('mock_engagement_analytics.json');
    return (jsonData as List<dynamic>)
        .map((e) => EngagementEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RetentionEntry>> fetchRetentionAnalytics() async {
    final jsonData = await apiService.getMockData('mock_retention_analytics.json');
    return (jsonData as List<dynamic>)
        .map((e) => RetentionEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ------------------------- LIFECYCLE METHODS -------------------------

  /// Track specific event with data
  Future<void> trackEvent(String eventName, Map<String, dynamic> data) async {
    await logEvent(eventName, data);
  }

  /// LIFECYCLE METHOD: Flush all pending events immediately
  /// Called when app goes to background or is about to be terminated
  Future<void> flushEvents() async {
    try {
      LogManager.log('Flushing all pending analytics events', level: LogLevel.info, source: 'AnalyticsService');

      // End current session
      await _endCurrentSession();

      // Flush offline events if online
      if (_isOnline) {
        await _syncOfflineEvents();
      }

      // Flush queued events
      await retryQueuedEvents();

      // Save current session state
      await _saveAnalyticsState();

      LogManager.log('All analytics events flushed successfully', level: LogLevel.info, source: 'AnalyticsService');
    } catch (e) {
      LogManager.log('Error flushing analytics events: $e', level: LogLevel.error, source: 'AnalyticsService');
    }
  }

  /// Flush pending events without waiting for full retry cycle
  Future<void> flushPendingEvents() async {
    try {
      if (_isOnline && !_isPaused) {
        await _syncOfflineEvents();
        await retryQueuedEvents();
      }
      LogManager.log('Pending events flushed', level: LogLevel.debug, source: 'AnalyticsService');
    } catch (e) {
      LogManager.log('Error flushing pending events: $e', level: LogLevel.warning, source: 'AnalyticsService');
    }
  }

  /// LIFECYCLE METHOD: Pause analytics collection (for battery saving)
  /// Called when app goes to background
  void pauseCollection() {
    try {
      _isPaused = true;
      _retryTimer?.cancel();
      LogManager.log('Analytics collection paused', level: LogLevel.info, source: 'AnalyticsService');
    } catch (e) {
      LogManager.log('Error pausing analytics collection: $e', level: LogLevel.warning, source: 'AnalyticsService');
    }
  }

  /// LIFECYCLE METHOD: Resume analytics collection
  /// Called when app resumes from background
  void resumeCollection() {
    try {
      _isPaused = false;
      _startRetryLoop();
      LogManager.log('Analytics collection resumed', level: LogLevel.info, source: 'AnalyticsService');
    } catch (e) {
      LogManager.log('Error resuming analytics collection: $e', level: LogLevel.warning, source: 'AnalyticsService');
    }
  }

  /// Save current analytics state to storage
  Future<void> _saveAnalyticsState() async {
    try {
      final analyticsState = {
        'currentSessionId': _currentSessionId,
        'sessionStartTime': _sessionStartTime?.toIso8601String(),
        'sessionMetrics': _sessionMetrics,
        'isPaused': _isPaused,
        'isOnline': _isOnline,
        'savedAt': DateTime.now().toIso8601String(),
      };

      await _sessionDataBox?.put('analytics_state', analyticsState);
      LogManager.log('Analytics state saved', level: LogLevel.debug, source: 'AnalyticsService');
    } catch (e) {
      LogManager.log('Failed to save analytics state: $e', level: LogLevel.warning, source: 'AnalyticsService');
    }
  }

  /// Track app lifecycle events
  Future<void> trackLifecycleEvent(String event, {Map<String, dynamic>? additionalData}) async {
    final data = {
      'lifecycle_event': event,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': _currentSessionId,
      'session_duration': _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inSeconds
          : 0,
      ...?additionalData,
    };

    await logEvent('app_lifecycle', data);
  }

  /// Track user engagement metrics
  Future<void> trackEngagement({
    required String action,
    String? screen,
    int? duration,
    Map<String, dynamic>? properties,
  }) async {
    final data = {
      'action': action,
      if (screen != null) 'screen': screen,
      if (duration != null) 'duration_ms': duration,
      'session_id': _currentSessionId,
      ...?properties,
    };

    await logEvent('user_engagement', data);
  }

  /// Track performance metrics
  Future<void> trackPerformance({
    required String metric,
    required double value,
    String? unit,
    Map<String, dynamic>? context,
  }) async {
    final data = {
      'metric': metric,
      'value': value,
      if (unit != null) 'unit': unit,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': _currentSessionId,
      ...?context,
    };

    await logEvent('performance_metric', data);
  }

  /// Get analytics health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'is_online': _isOnline,
      'is_paused': _isPaused,
      'offline_events_count': getOfflineEventsCount(),
      'current_session_id': _currentSessionId,
      'session_duration_minutes': _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inMinutes
          : 0,
      'retry_timer_active': _retryTimer?.isActive ?? false,
      'box_initialized': _offlineEventsBox != null,
      'session_metrics': _sessionMetrics,
    };
  }

  /// Get session analytics summary
  Future<Map<String, dynamic>> getSessionSummary() async {
    final currentSession = Map<String, dynamic>.from(_sessionMetrics);
    if (_sessionStartTime != null) {
      currentSession['currentDuration'] = DateTime.now().difference(_sessionStartTime!).inMinutes;
    }

    return {
      'currentSession': currentSession,
      'healthStatus': getHealthStatus(),
    };
  }
}
