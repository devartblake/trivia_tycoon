import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// A lightweight local queueing service for retrying failed API events.
class EventQueueService {
  static const String _boxName = 'event_queue';

  /// Enqueue a failed event for later retry.
  Future<void> enqueueEvent(String endpoint, Map<String, dynamic> payload) async {
    final box = await Hive.openBox(_boxName);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, {
      'endpoint': endpoint,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Retry all pending events in the queue.
  /// Accepts a handler callback to send the event. Successful events will be removed.
  Future<void> retryQueuedEvents(
      Future<void> Function(String endpoint, Map<String, dynamic> payload) handler) async {
    final box = await Hive.openBox(_boxName);
    final keys = box.keys;

    for (final key in keys) {
      final event = box.get(key);
      if (event == null || event['endpoint'] == null || event['payload'] == null) continue;

      try {
        await handler(event['endpoint'], Map<String, dynamic>.from(event['payload']));
        await box.delete(key); // Remove only if successful
      } catch (e) {
        // Leave it in the box for future retry
        debugPrint('[EventQueue] Retry failed for $key: $e');
      }
    }
  }

  /// Optional: Clear all events from the queue.
  Future<void> clearAll() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }

  /// Optional: Get a snapshot of pending events for debugging or display.
  Future<List<Map<String, dynamic>>> getPendingEvents() async {
    final box = await Hive.openBox(_boxName);
    return box.values.cast<Map<String, dynamic>>().toList();
  }
}
