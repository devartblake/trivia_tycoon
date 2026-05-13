import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/state_persistence_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('state_persistence_service_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<StatePersistenceService> _makeInitialized() async {
    final service = StatePersistenceService();
    await service.initialize();
    return service;
  }

  // -------------------------------------------------------------------------
  // initialize
  // -------------------------------------------------------------------------

  group('StatePersistenceService — initialize', () {
    test('initializes without error on a fresh box', () async {
      final service = StatePersistenceService();
      await expectLater(service.initialize(), completes);
    });

    test('second initialize call is a no-op', () async {
      final service = StatePersistenceService();
      await service.initialize();
      // Should not throw or open a second box.
      await expectLater(service.initialize(), completes);
    });

    test('getLastSaveTime returns null on fresh box', () async {
      final service = await _makeInitialized();
      expect(service.getLastSaveTime(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // saveAll + getters
  // -------------------------------------------------------------------------

  group('StatePersistenceService — saveAll / getters', () {
    test('saves and retrieves game state', () async {
      final service = await _makeInitialized();
      await service.saveAll(gameState: {'score': 42, 'level': 3});

      final state = await service.getGameState();
      expect(state, {'score': 42, 'level': 3});
    });

    test('saves and retrieves user session', () async {
      final service = await _makeInitialized();
      await service.saveAll(userSession: {'userId': 'u1', 'token': 'tok'});

      final session = await service.getUserSession();
      expect(session, {'userId': 'u1', 'token': 'tok'});
    });

    test('saves and retrieves WebSocket state', () async {
      final service = await _makeInitialized();
      await service.saveAll(wsState: {'connected': true, 'channel': 'main'});

      final ws = await service.getWebSocketState();
      expect(ws, {'connected': true, 'channel': 'main'});
    });

    test('saves and retrieves pending actions', () async {
      final service = await _makeInitialized();
      final actions = [
        {'type': 'submit_score', 'score': 100},
        {'type': 'send_message', 'text': 'hello'},
      ];
      await service.saveAll(pendingActions: actions);

      final retrieved = await service.getPendingActions();
      expect(retrieved.length, 2);
      expect(retrieved[0]['type'], 'submit_score');
      expect(retrieved[1]['text'], 'hello');
    });

    test('saves multiple keys in a single call', () async {
      final service = await _makeInitialized();
      await service.saveAll(
        gameState: {'q': 5},
        userSession: {'uid': 'me'},
        wsState: {'connected': false},
        pendingActions: [
          {'type': 'retry'},
        ],
      );

      expect(await service.getGameState(), {'q': 5});
      expect(await service.getUserSession(), {'uid': 'me'});
      expect(await service.getWebSocketState(), {'connected': false});
      expect((await service.getPendingActions()).length, 1);
    });

    test('null arguments do not overwrite existing data', () async {
      final service = await _makeInitialized();
      await service.saveAll(gameState: {'score': 7});
      // saveAll with null gameState — existing value should stay
      await service.saveAll(userSession: {'uid': 'x'});

      expect(await service.getGameState(), {'score': 7});
    });

    test('empty map argument does not overwrite existing data', () async {
      final service = await _makeInitialized();
      await service.saveAll(gameState: {'score': 10});
      // Empty map — should not overwrite
      await service.saveAll(gameState: {});

      expect(await service.getGameState(), {'score': 10});
    });
  });

  // -------------------------------------------------------------------------
  // getters return null / empty when nothing saved
  // -------------------------------------------------------------------------

  group('StatePersistenceService — getters return empty defaults', () {
    test('getGameState returns null when not saved', () async {
      final service = await _makeInitialized();
      expect(await service.getGameState(), isNull);
    });

    test('getUserSession returns null when not saved', () async {
      final service = await _makeInitialized();
      expect(await service.getUserSession(), isNull);
    });

    test('getWebSocketState returns null when not saved', () async {
      final service = await _makeInitialized();
      expect(await service.getWebSocketState(), isNull);
    });

    test('getPendingActions returns empty list when not saved', () async {
      final service = await _makeInitialized();
      expect(await service.getPendingActions(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // getLastSaveTime
  // -------------------------------------------------------------------------

  group('StatePersistenceService — getLastSaveTime', () {
    test('returns null before any successful save', () async {
      final service = await _makeInitialized();
      expect(service.getLastSaveTime(), isNull);
    });

    test('returns a valid DateTime after saveAll with data', () async {
      final service = await _makeInitialized();
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      await service.saveAll(gameState: {'x': 1});
      final after = DateTime.now().add(const Duration(seconds: 1));

      final saved = service.getLastSaveTime();
      expect(saved, isNotNull);
      expect(saved!.isAfter(before), isTrue);
      expect(saved.isBefore(after), isTrue);
    });

    test('updates timestamp on each save', () async {
      final service = await _makeInitialized();
      await service.saveAll(gameState: {'x': 1});
      final first = service.getLastSaveTime();

      await Future.delayed(const Duration(milliseconds: 10));
      await service.saveAll(gameState: {'x': 2});
      final second = service.getLastSaveTime();

      expect(second!.isAfter(first!), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // clearPendingActions
  // -------------------------------------------------------------------------

  group('StatePersistenceService — clearPendingActions', () {
    test('removes pending actions while preserving other data', () async {
      final service = await _makeInitialized();
      await service.saveAll(
        gameState: {'score': 50},
        pendingActions: [
          {'type': 'ping'},
        ],
      );

      await service.clearPendingActions();

      expect(await service.getPendingActions(), isEmpty);
      expect(await service.getGameState(), {'score': 50});
    });

    test('clearPendingActions on empty store does not throw', () async {
      final service = await _makeInitialized();
      await expectLater(service.clearPendingActions(), completes);
    });
  });

  // -------------------------------------------------------------------------
  // clearTemporaryData
  // -------------------------------------------------------------------------

  group('StatePersistenceService — clearTemporaryData', () {
    test('removes game state but preserves user session and pending actions',
        () async {
      final service = await _makeInitialized();
      await service.saveAll(
        gameState: {'score': 99},
        userSession: {'uid': 'u1'},
        pendingActions: [
          {'type': 'retry'},
        ],
      );

      await service.clearTemporaryData();

      expect(await service.getGameState(), isNull);
      expect(await service.getUserSession(), {'uid': 'u1'});
      expect((await service.getPendingActions()).length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // clearAll
  // -------------------------------------------------------------------------

  group('StatePersistenceService — clearAll', () {
    test('removes all saved data', () async {
      final service = await _makeInitialized();
      await service.saveAll(
        gameState: {'score': 5},
        userSession: {'uid': 'u2'},
        wsState: {'connected': true},
        pendingActions: [
          {'type': 'x'},
        ],
      );

      await service.clearAll();

      expect(await service.getGameState(), isNull);
      expect(await service.getUserSession(), isNull);
      expect(await service.getWebSocketState(), isNull);
      expect(await service.getPendingActions(), isEmpty);
      // Last save time also gone
      expect(service.getLastSaveTime(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // hasRecoverableData — crash detection
  // -------------------------------------------------------------------------

  group('StatePersistenceService — hasRecoverableData', () {
    test('returns false on fresh box (no crash, no data)', () async {
      // Fresh box: crash flag = false (default) → true after init,
      // but no game/session/pending data → returns false.
      final service = await _makeInitialized();
      expect(await service.hasRecoverableData(), isFalse);
    });

    test('returns false after a normal saveAll (crash flag cleared)', () async {
      final service = await _makeInitialized();
      await service.saveAll(gameState: {'score': 1});
      // saveAll calls _markSaveComplete which sets crash flag to false.
      expect(await service.hasRecoverableData(), isFalse);
    });

    test('returns true when crash flag is set and game state exists', () async {
      // Simulate a previous-session crash: open the box directly and set
      // crash_recovery_flag = true plus some game data.
      final box = await Hive.openBox('app_persistence');
      await box.put('crash_recovery_flag', true);
      await box.put('game_state', {'score': 42});

      // Create a service that re-opens the same (already open) box.
      final service = StatePersistenceService();
      await service.initialize();
      // _checkForCrash reads crash flag = true, then sets it to true (idempotent).

      expect(await service.hasRecoverableData(), isTrue);
    });

    test(
        'returns true when crash flag is set and pending actions exist',
        () async {
      final box = await Hive.openBox('app_persistence');
      await box.put('crash_recovery_flag', true);
      await box.put('pending_actions', [
        {'type': 'submit'},
      ]);

      final service = StatePersistenceService();
      await service.initialize();

      expect(await service.hasRecoverableData(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // getRecoverySummary
  // -------------------------------------------------------------------------

  group('StatePersistenceService — getRecoverySummary', () {
    test('returns correct keys in summary', () async {
      final service = await _makeInitialized();
      await service.saveAll(
        gameState: {'score': 10},
        pendingActions: [
          {'type': 'a'},
          {'type': 'b'},
        ],
      );

      final summary = await service.getRecoverySummary();

      expect(summary['has_game_state'], isTrue);
      expect(summary['game_state'], isNotNull);
      expect(summary['has_user_session'], isFalse);
      expect(summary['pending_actions_count'], 2);
      // last_save should be present after saveAll
      expect(summary['last_save'], isNotNull);
    });

    test('returns empty summary fields when no data exists', () async {
      final service = await _makeInitialized();
      final summary = await service.getRecoverySummary();

      expect(summary['has_game_state'], isFalse);
      expect(summary['has_user_session'], isFalse);
      expect(summary['pending_actions_count'], 0);
      expect(summary['last_save'], isNull);
    });
  });

  // -------------------------------------------------------------------------
  // markRecoveryHandled
  // -------------------------------------------------------------------------

  group('StatePersistenceService — markRecoveryHandled', () {
    test('clears crash flag so hasRecoverableData returns false', () async {
      final box = await Hive.openBox('app_persistence');
      await box.put('crash_recovery_flag', true);
      await box.put('game_state', {'score': 99});

      final service = StatePersistenceService();
      await service.initialize();
      expect(await service.hasRecoverableData(), isTrue);

      await service.markRecoveryHandled();
      expect(await service.hasRecoverableData(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // saveAll before initialize (not initialized guard)
  // -------------------------------------------------------------------------

  group('StatePersistenceService — uninitialized guard', () {
    test('saveAll before initialize does nothing without throwing', () async {
      final service = StatePersistenceService();
      await expectLater(
        service.saveAll(gameState: {'score': 1}),
        completes,
      );
    });
  });
}
