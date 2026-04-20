import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Used by queue handlers to mark a failed event as permanent (do not retry).
class NonRetryableEventException implements Exception {
  final String message;

  NonRetryableEventException([this.message = 'Non-retryable event failure']);

  @override
  String toString() => message;
}

/// Enhanced event queue service with intelligent retry logic and failure tracking
class EventQueueService {
  static const String _boxName = 'event_queue';
  static const String _metadataBoxName = 'event_queue_metadata';

  // Retry configuration
  static const int maxConsecutiveFailures = 5;
  static const Duration cooldownPeriod = Duration(hours: 1);
  static const Duration retryInterval = Duration(minutes: 5);
  static const int maxQueueSize = 50; // Maximum events to keep in queue

  // State tracking
  int _consecutiveFailures = 0;
  DateTime? _lastFailureTime;
  DateTime? _cooldownUntil;
  bool _isInCooldown = false;

  // Analytics callback
  Function(String event, Map<String, dynamic> data)? _analyticsCallback;

  EventQueueService();

  /// Initialize the service and load previous state
  Future<void> initialize({
    Function(String event, Map<String, dynamic> data)? analyticsCallback,
  }) async {
    _analyticsCallback = analyticsCallback;
    await _loadState();

    LogManager.info(
      'EventQueueService initialized - Consecutive failures: $_consecutiveFailures',
      source: 'EventQueueService',
    );

    // Check queue size on initialization
    await _enforceQueueSizeLimit();
  }

  /// Load previous failure state from storage
  Future<void> _loadState() async {
    try {
      final metadataBox = await Hive.openBox(_metadataBoxName);

      _consecutiveFailures =
          metadataBox.get('consecutive_failures', defaultValue: 0);
      final lastFailureStr = metadataBox.get('last_failure_time');
      final cooldownUntilStr = metadataBox.get('cooldown_until');

      if (lastFailureStr != null) {
        _lastFailureTime = DateTime.parse(lastFailureStr);
      }

      if (cooldownUntilStr != null) {
        _cooldownUntil = DateTime.parse(cooldownUntilStr);
        _isInCooldown = DateTime.now().isBefore(_cooldownUntil!);

        if (_isInCooldown) {
          final remaining = _cooldownUntil!.difference(DateTime.now());
          LogManager.warning(
            'Service in cooldown mode - ${remaining.inMinutes} minutes remaining',
            source: 'EventQueueService',
          );
        }
      }
    } catch (e) {
      LogManager.error(
        'Failed to load event queue state',
        source: 'EventQueueService',
        error: e,
      );
    }
  }

  /// Save current failure state to storage
  Future<void> _saveState() async {
    try {
      final metadataBox = await Hive.openBox(_metadataBoxName);

      await metadataBox.put('consecutive_failures', _consecutiveFailures);
      await metadataBox.put(
        'last_failure_time',
        _lastFailureTime?.toIso8601String(),
      );
      await metadataBox.put(
        'cooldown_until',
        _cooldownUntil?.toIso8601String(),
      );
    } catch (e) {
      LogManager.error(
        'Failed to save event queue state',
        source: 'EventQueueService',
        error: e,
      );
    }
  }

  /// Check if service is in cooldown mode
  bool get isInCooldown {
    if (_cooldownUntil == null) return false;

    final now = DateTime.now();
    if (now.isAfter(_cooldownUntil!)) {
      _isInCooldown = false;
      _cooldownUntil = null;
      _consecutiveFailures = 0;
      _saveState();

      LogManager.success(
        'Cooldown period ended - resuming normal operations',
        source: 'EventQueueService',
      );
    }

    return _isInCooldown;
  }

  /// Enforce queue size limit - delete oldest events if over limit
  Future<void> _enforceQueueSizeLimit() async {
    try {
      final box = await Hive.openBox(_boxName);

      if (box.length <= maxQueueSize) return;

      final excessCount = box.length - maxQueueSize;

      LogManager.warning(
        'Queue size (${box.length}) exceeds limit ($maxQueueSize). Removing $excessCount oldest events (FIFO).',
        source: 'EventQueueService',
      );

      // Get all entries sorted by timestamp (oldest first)
      final entries = box.toMap().entries.toList();
      entries.sort((a, b) {
        final aTime =
            DateTime.tryParse(a.value['timestamp'] ?? '') ?? DateTime.now();
        final bTime =
            DateTime.tryParse(b.value['timestamp'] ?? '') ?? DateTime.now();
        return aTime.compareTo(bTime);
      });

      // Delete oldest entries
      int deleted = 0;
      for (var i = 0; i < excessCount; i++) {
        await box.delete(entries[i].key);
        deleted++;
      }

      LogManager.info(
        'Deleted $deleted oldest events to maintain queue size limit',
        source: 'EventQueueService',
      );

      _notifyAnalytics('queue_size_limit_enforced', {
        'deleted_count': deleted,
        'remaining_count': box.length,
        'max_queue_size': maxQueueSize,
      });
    } catch (e) {
      LogManager.error(
        'Failed to enforce queue size limit',
        source: 'EventQueueService',
        error: e,
      );
    }
  }

  /// Enqueue a failed event for later retry
  Future<void> enqueueEvent(
      String endpoint, Map<String, dynamic> payload) async {
    if (isInCooldown) {
      LogManager.logWithCustomColor(
        'Cannot enqueue - service in cooldown mode',
        source: 'EventQueueService',
        color: LogColors.brightRed,
        bold: true,
      );
      return;
    }

    try {
      final box = await Hive.openBox(_boxName);

      // Enforce size limit before adding new event
      if (box.length >= maxQueueSize) {
        LogManager.warning(
          'Queue at max size ($maxQueueSize). Removing 10 oldest events (FIFO) before adding new event.',
          source: 'EventQueueService',
        );

        // Remove 10 oldest events
        final entries = box.toMap().entries.toList();
        entries.sort((a, b) {
          final aTime =
              DateTime.tryParse(a.value['timestamp'] ?? '') ?? DateTime.now();
          final bTime =
              DateTime.tryParse(b.value['timestamp'] ?? '') ?? DateTime.now();
          return aTime.compareTo(bTime);
        });

        int deleteCount = 10;
        for (var i = 0; i < deleteCount && i < entries.length; i++) {
          await box.delete(entries[i].key);
        }

        LogManager.info(
          'Deleted $deleteCount oldest events (FIFO) to make room',
          source: 'EventQueueService',
        );

        _notifyAnalytics('queue_fifo_cleanup', {
          'deleted_count': deleteCount,
          'reason': 'max_queue_size_reached',
        });
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();

      await box.put(id, {
        'endpoint': endpoint,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'last_retry': null,
      });

      // Notify analytics
      _notifyAnalytics('event_queued', {
        'endpoint': endpoint,
        'queue_size': box.length,
      });
    } catch (e) {
      LogManager.error(
        'Failed to enqueue event',
        source: 'EventQueueService',
        error: e,
      );
    }
  }

  /// Retry all pending events in the queue with failure tracking
  Future<void> retryQueuedEvents(
      Future<void> Function(String endpoint, Map<String, dynamic> payload)
          handler) async {
    if (isInCooldown) {
      final remaining = _cooldownUntil!.difference(DateTime.now());
      LogManager.warning(
        'Skipping retry - in cooldown mode (${remaining.inMinutes}m remaining)',
        source: 'EventQueueService',
      );
      return;
    }

    final box = await Hive.openBox(_boxName);
    final keys = box.keys.toList();

    if (keys.isEmpty) return;

    int successCount = 0;
    int failureCount = 0;
    int droppedCount = 0;

    for (final key in keys) {
      final event = box.get(key);
      if (event == null ||
          event['endpoint'] == null ||
          event['payload'] == null) {
        await box.delete(key);
        continue;
      }

      try {
        await handler(
          event['endpoint'],
          Map<String, dynamic>.from(event['payload']),
        );

        // Success - remove from queue
        await box.delete(key);
        successCount++;
        _consecutiveFailures = 0; // Reset on success
      } catch (e) {
        if (e is NonRetryableEventException) {
          await box.delete(key);
          droppedCount++;
          continue;
        }

        failureCount++;

        // Update retry metadata
        final retryCount = (event['retry_count'] ?? 0) + 1;
        await box.put(key, {
          ...event,
          'retry_count': retryCount,
          'last_retry': DateTime.now().toIso8601String(),
          'last_error': e.toString(),
        });
      }
    }

    // Handle consecutive failures
    if (failureCount > 0 && successCount == 0) {
      await _handleFailureCycle(failureCount);
    }

    // Report results
    _reportRetryCycle(successCount, failureCount, droppedCount, box.length);

    // Enforce queue size limit after retries
    await _enforceQueueSizeLimit();
  }

  /// Handle a complete failure cycle
  Future<void> _handleFailureCycle(int failureCount) async {
    _consecutiveFailures++;
    _lastFailureTime = DateTime.now();

    LogManager.warning(
      'Retry cycle failed - Consecutive failures: $_consecutiveFailures/$maxConsecutiveFailures',
      source: 'EventQueueService',
    );

    // Notify analytics of failure
    _notifyAnalytics('retry_cycle_failed', {
      'failure_count': failureCount,
      'consecutive_failures': _consecutiveFailures,
    });

    // Enter cooldown if threshold exceeded
    if (_consecutiveFailures >= maxConsecutiveFailures) {
      await _enterCooldownMode();
    }

    await _saveState();
  }

  /// Enter cooldown mode
  Future<void> _enterCooldownMode() async {
    _isInCooldown = true;
    _cooldownUntil = DateTime.now().add(cooldownPeriod);

    LogManager.critical(
      'ENTERING COOLDOWN MODE - Too many consecutive failures. '
      'Retries paused for ${cooldownPeriod.inMinutes} minutes',
      source: 'EventQueueService',
    );

    // Notify analytics
    _notifyAnalytics('cooldown_mode_entered', {
      'consecutive_failures': _consecutiveFailures,
      'cooldown_until': _cooldownUntil!.toIso8601String(),
      'cooldown_minutes': cooldownPeriod.inMinutes,
    });

    await _saveState();
  }

  /// Report retry cycle results
  void _reportRetryCycle(int successCount, int failureCount, int droppedCount,
      int remainingCount) {
    if (successCount > 0 || failureCount > 0 || droppedCount > 0) {
      LogManager.divider(label: 'RETRY CYCLE COMPLETE');
      LogManager.success('Succeeded: $successCount',
          source: 'EventQueueService');

      if (failureCount > 0) {
        LogManager.error('Failed: $failureCount', source: 'EventQueueService');
      }

      if (droppedCount > 0) {
        LogManager.warning('Dropped (non-retryable): $droppedCount',
            source: 'EventQueueService');
      }

      LogManager.info('Remaining in queue: $remainingCount',
          source: 'EventQueueService');
      LogManager.divider();
    }

    _notifyAnalytics('retry_cycle_complete', {
      'success_count': successCount,
      'failure_count': failureCount,
      'remaining_count': remainingCount,
      'dropped_count': droppedCount,
      'consecutive_failures': _consecutiveFailures,
    });
  }

  /// Notify analytics service of events
  void _notifyAnalytics(String event, Map<String, dynamic> data) {
    if (_analyticsCallback != null) {
      try {
        _analyticsCallback!(event, {
          ...data,
          'source': 'EventQueueService',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Don't let analytics failure affect queue operations
        LogManager.debug(
            '[EventQueueService] Analytics notification failed: $e');
      }
    }
  }

  /// Export failed events for server upload on app termination
  Future<Map<String, dynamic>> exportFailedEventsForUpload(
      String playerId) async {
    try {
      final box = await Hive.openBox(_boxName);
      final events = box.values
          .map((event) => {
                'endpoint': event['endpoint'],
                'payload': event['payload'],
                'timestamp': event['timestamp'],
                'retry_count': event['retry_count'] ?? 0,
                'last_retry': event['last_retry'],
                'last_error': event['last_error'],
              })
          .toList();

      final exportData = {
        'player_id': playerId,
        'export_timestamp': DateTime.now().toIso8601String(),
        'failed_events': events,
        'queue_metadata': {
          'consecutive_failures': _consecutiveFailures,
          'last_failure_time': _lastFailureTime?.toIso8601String(),
          'is_in_cooldown': _isInCooldown,
          'cooldown_until': _cooldownUntil?.toIso8601String(),
          'total_events': events.length,
          'max_queue_size': maxQueueSize,
        },
        'analytics_logs':
            LogManager.exportLogsAsJson(source: 'EventQueueService'),
      };

      LogManager.highlight(
        'Exported ${events.length} failed events for player: $playerId',
        source: 'EventQueueService',
      );

      return exportData;
    } catch (e) {
      LogManager.error(
        'Failed to export events',
        source: 'EventQueueService',
        error: e,
      );
      return {};
    }
  }

  /// Get current queue status
  Map<String, dynamic> getQueueStatus() {
    return {
      'is_in_cooldown': _isInCooldown,
      'consecutive_failures': _consecutiveFailures,
      'cooldown_until': _cooldownUntil?.toIso8601String(),
      'last_failure_time': _lastFailureTime?.toIso8601String(),
      'max_consecutive_failures': maxConsecutiveFailures,
      'cooldown_period_minutes': cooldownPeriod.inMinutes,
      'max_queue_size': maxQueueSize,
    };
  }

  /// Get pending events for debugging
  Future<List<Map<String, dynamic>>> getPendingEvents() async {
    final box = await Hive.openBox(_boxName);
    return box.values.cast<Map<String, dynamic>>().toList();
  }

  /// Clear all events from the queue
  Future<void> clearAll() async {
    final box = await Hive.openBox(_boxName);
    final count = box.length;
    await box.clear();

    _consecutiveFailures = 0;
    _lastFailureTime = null;
    _cooldownUntil = null;
    _isInCooldown = false;
    await _saveState();

    LogManager.warning(
      'Queue cleared - $count events removed',
      source: 'EventQueueService',
    );
  }

  /// Force exit cooldown mode (admin/debug only)
  Future<void> forceExitCooldown() async {
    _isInCooldown = false;
    _cooldownUntil = null;
    _consecutiveFailures = 0;
    await _saveState();

    LogManager.highlight(
      'Cooldown mode forcefully exited',
      source: 'EventQueueService',
    );
  }
}
