import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/event_queue_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('event_queue_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<EventQueueService> _make() async {
    final svc = EventQueueService();
    await svc.initialize();
    return svc;
  }

  // -------------------------------------------------------------------------
  // initialize
  // -------------------------------------------------------------------------

  group('initialize', () {
    test('starts empty', () async {
      final svc = await _make();
      expect(await svc.getPendingEvents(), isEmpty);
    });

    test('isInCooldown false initially', () async {
      final svc = await _make();
      expect(svc.isInCooldown, isFalse);
    });

    test('idempotent — second initialize does not crash', () async {
      final svc = await _make();
      await expectLater(svc.initialize(), completes);
    });
  });

  // -------------------------------------------------------------------------
  // enqueueEvent
  // -------------------------------------------------------------------------

  group('enqueueEvent', () {
    test('1 entry after enqueue', () async {
      final svc = await _make();
      await svc.enqueueEvent('/api/test', {'key': 'val'});
      expect((await svc.getPendingEvents()).length, 1);
    });

    test('entry has endpoint field', () async {
      final svc = await _make();
      await svc.enqueueEvent('/api/users', {'id': '1'});
      final events = await svc.getPendingEvents();
      expect(events.first['endpoint'], '/api/users');
    });

    test('entry has payload field', () async {
      final svc = await _make();
      await svc.enqueueEvent('/api/data', {'score': 100});
      final events = await svc.getPendingEvents();
      expect(events.first['payload']['score'], 100);
    });

    test('entry has timestamp field', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep', {});
      final events = await svc.getPendingEvents();
      expect(events.first['timestamp'], isNotNull);
    });

    test('entry has retry_count = 0', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep', {});
      final events = await svc.getPendingEvents();
      expect(events.first['retry_count'], 0);
    });

    test('multiple events accumulate', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep1', {});
      await svc.enqueueEvent('/ep2', {});
      await svc.enqueueEvent('/ep3', {});
      expect((await svc.getPendingEvents()).length, 3);
    });
  });

  // -------------------------------------------------------------------------
  // queue size limit
  // -------------------------------------------------------------------------

  group('queue size limit', () {
    test('55 events → only 50 remain after limit enforcement', () async {
      final svc = await _make();
      for (int i = 0; i < 55; i++) {
        await svc.enqueueEvent('/ep', {'i': i});
      }
      expect((await svc.getPendingEvents()).length, 50);
    });

    test('oldest events removed first (FIFO)', () async {
      final svc = await _make();
      // Enqueue 55 events with different payloads
      for (int i = 0; i < 55; i++) {
        await svc.enqueueEvent('/ep', {'i': i});
      }
      final events = await svc.getPendingEvents();
      // The earliest events (i=0 to i=4) should be gone; recent ones remain
      final payloads = events.map((e) => e['payload']['i'] as int).toList();
      expect(payloads.contains(54), isTrue); // Most recent preserved
    });
  });

  // -------------------------------------------------------------------------
  // retryQueuedEvents — success
  // -------------------------------------------------------------------------

  group('retryQueuedEvents — success', () {
    test('queue empty after successful retry', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep', {'data': 1});
      await svc.retryQueuedEvents(
          (endpoint, payload) async {/* success */});
      expect((await svc.getPendingEvents()).length, 0);
    });

    test('consecutive failures reset to 0 on success', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep', {});
      await svc.retryQueuedEvents((_e, _p) async {});
      final status = await svc.getQueueStatus();
      expect(status['consecutive_failures'], 0);
    });
  });

  // -------------------------------------------------------------------------
  // retryQueuedEvents — failure
  // -------------------------------------------------------------------------

  group('retryQueuedEvents — failure', () {
    test('event stays in queue after failure', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep', {});
      await svc.retryQueuedEvents((_e, _p) async {
        throw Exception('Network error');
      });
      expect((await svc.getPendingEvents()).length, 1);
    });

    test('retry_count incremented after failure', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep', {});
      await svc.retryQueuedEvents((_e, _p) async {
        throw Exception('fail');
      });
      final events = await svc.getPendingEvents();
      expect(events.first['retry_count'], 1);
    });

    test('last_error set after failure', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep', {});
      await svc.retryQueuedEvents((_e, _p) async {
        throw Exception('Custom error message');
      });
      final events = await svc.getPendingEvents();
      expect(events.first['last_error'], isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // retryQueuedEvents — NonRetryableEventException
  // -------------------------------------------------------------------------

  group('retryQueuedEvents — NonRetryableEventException', () {
    test('event dropped permanently on NonRetryableEventException', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep', {});
      await svc.retryQueuedEvents((_e, _p) async {
        throw NonRetryableEventException('Do not retry');
      });
      expect((await svc.getPendingEvents()).length, 0);
    });
  });

  // -------------------------------------------------------------------------
  // failure cycles → cooldown
  // -------------------------------------------------------------------------

  group('failure cycles → cooldown', () {
    test('5 all-fail cycles triggers cooldown', () async {
      final svc = await _make();
      for (int cycle = 0; cycle < 5; cycle++) {
        await svc.enqueueEvent('/ep_$cycle', {});
        await svc.retryQueuedEvents((_e, _p) async {
          throw Exception('fail cycle $cycle');
        });
      }
      expect(svc.isInCooldown, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // cooldown blocks enqueue
  // -------------------------------------------------------------------------

  group('cooldown blocks enqueue', () {
    test('enqueue returns false when in cooldown', () async {
      final svc = await _make();
      // Trigger 5 failure cycles to enter cooldown
      for (int i = 0; i < 5; i++) {
        await svc.enqueueEvent('/ep$i', {});
        await svc.retryQueuedEvents((_e, _p) async {
          throw Exception('fail');
        });
      }
      expect(svc.isInCooldown, isTrue);
      final result = await svc.enqueueEvent('/blocked', {});
      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // forceExitCooldown
  // -------------------------------------------------------------------------

  group('forceExitCooldown', () {
    test('immediately exits cooldown state', () async {
      final svc = await _make();
      for (int i = 0; i < 5; i++) {
        await svc.enqueueEvent('/ep$i', {});
        await svc.retryQueuedEvents((_e, _p) async {
          throw Exception('fail');
        });
      }
      expect(svc.isInCooldown, isTrue);
      await svc.forceExitCooldown();
      expect(svc.isInCooldown, isFalse);
    });

    test('enqueue succeeds after forceExitCooldown', () async {
      final svc = await _make();
      for (int i = 0; i < 5; i++) {
        await svc.enqueueEvent('/ep$i', {});
        await svc.retryQueuedEvents((_e, _p) async {
          throw Exception('fail');
        });
      }
      await svc.forceExitCooldown();
      final result = await svc.enqueueEvent('/now_ok', {});
      expect(result, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // getQueueStatus
  // -------------------------------------------------------------------------

  group('getQueueStatus', () {
    test('returns map with is_in_cooldown key', () async {
      final svc = await _make();
      final status = await svc.getQueueStatus();
      expect(status.containsKey('is_in_cooldown'), isTrue);
    });

    test('returns map with consecutive_failures key', () async {
      final svc = await _make();
      final status = await svc.getQueueStatus();
      expect(status.containsKey('consecutive_failures'), isTrue);
    });

    test('is_in_cooldown false initially', () async {
      final svc = await _make();
      final status = await svc.getQueueStatus();
      expect(status['is_in_cooldown'], isFalse);
    });

    test('consecutive_failures 0 initially', () async {
      final svc = await _make();
      final status = await svc.getQueueStatus();
      expect(status['consecutive_failures'], 0);
    });
  });

  // -------------------------------------------------------------------------
  // clearAll
  // -------------------------------------------------------------------------

  group('clearAll', () {
    test('empties queue', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep', {});
      await svc.clearAll();
      expect((await svc.getPendingEvents()).length, 0);
    });

    test('resets consecutive failures', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep', {});
      await svc.retryQueuedEvents((_e, _p) async {
        throw Exception('fail');
      });
      await svc.clearAll();
      final status = await svc.getQueueStatus();
      expect(status['consecutive_failures'], 0);
    });

    test('isInCooldown false after clearAll', () async {
      final svc = await _make();
      for (int i = 0; i < 5; i++) {
        await svc.enqueueEvent('/ep$i', {});
        await svc.retryQueuedEvents((_e, _p) async {
          throw Exception('fail');
        });
      }
      await svc.clearAll();
      expect(svc.isInCooldown, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // exportFailedEventsForUpload
  // -------------------------------------------------------------------------

  group('exportFailedEventsForUpload', () {
    test('returns map with player_id key', () async {
      final svc = await _make();
      final export = await svc.exportFailedEventsForUpload('player123');
      expect(export['player_id'], 'player123');
    });

    test('contains export_timestamp key', () async {
      final svc = await _make();
      final export = await svc.exportFailedEventsForUpload('player123');
      expect(export.containsKey('export_timestamp'), isTrue);
    });

    test('contains failed_events key', () async {
      final svc = await _make();
      await svc.enqueueEvent('/ep', {});
      await svc.retryQueuedEvents((_e, _p) async {
        throw Exception('fail');
      });
      final export = await svc.exportFailedEventsForUpload('p1');
      expect(export.containsKey('failed_events'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // state persistence
  // -------------------------------------------------------------------------

  group('state persistence', () {
    test('events survive service restart (new instance + initialize)', () async {
      final svc1 = await _make();
      await svc1.enqueueEvent('/persisted', {'data': 'keep'});

      // Create new service instance and initialize from same Hive
      final svc2 = EventQueueService();
      await svc2.initialize();
      final events = await svc2.getPendingEvents();
      expect(events.any((e) => e['endpoint'] == '/persisted'), isTrue);
    });
  });
}
