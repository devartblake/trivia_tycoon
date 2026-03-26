import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/multiplayer/data/repositories/multiplayer_repository_impl.dart';
import 'package:trivia_tycoon/game/multiplayer/data/sources/ws_client.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_event.dart';

// ---------------------------------------------------------------------------
// Fake WsClient — captures sent messages without a real WebSocket
// ---------------------------------------------------------------------------

class _FakeWsClient extends WsClient {
  final List<Map<String, dynamic>> sent = [];
  final _evtCtrl = StreamController<GameEvent>.broadcast();

  _FakeWsClient() : super(autoReconnect: false);

  @override
  Future<void> send(Map<String, dynamic> json) async {
    sent.add(Map<String, dynamic>.from(json));
  }

  @override
  Stream<GameEvent> get events => _evtCtrl.stream;

  void dispose() {
    _evtCtrl.close();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeWsClient fakeWs;
  late MultiplayerRepositoryImpl repo;

  setUp(() {
    fakeWs = _FakeWsClient();
    repo = MultiplayerRepositoryImpl(wsClient: fakeWs);
  });

  tearDown(() => fakeWs.dispose());

  group('MultiplayerRepositoryImpl — WS message shapes', () {
    test('quickMatch sends correct type', () async {
      await repo.quickMatch();

      expect(fakeWs.sent, hasLength(1));
      expect(fakeWs.sent.first['type'], 'quick_match');
      expect(fakeWs.sent.first['timestamp'], isA<int>());
    });

    test('createRoom sends room name', () async {
      await repo.createRoom('Trivia Night');

      expect(fakeWs.sent, hasLength(1));
      expect(fakeWs.sent.first['type'], 'create_room');
      expect(fakeWs.sent.first['name'], 'Trivia Night');
    });

    test('joinRoom sends room id', () async {
      await repo.joinRoom('room-xyz');

      expect(fakeWs.sent, hasLength(1));
      expect(fakeWs.sent.first['type'], 'join_room');
      expect(fakeWs.sent.first['room_id'], 'room-xyz');
    });

    test('leaveRoom sends correct type', () async {
      await repo.leaveRoom();

      expect(fakeWs.sent, hasLength(1));
      expect(fakeWs.sent.first['type'], 'leave_room');
    });

    test('submitAnswer sends all required fields', () async {
      await repo.submitAnswer('match-1', 'q-42', 'ans-B');

      expect(fakeWs.sent, hasLength(1));
      final msg = fakeWs.sent.first;
      expect(msg['type'], 'submit_answer');
      expect(msg['match_id'], 'match-1');
      expect(msg['question_id'], 'q-42');
      expect(msg['answer_id'], 'ans-B');
      expect(msg['timestamp'], isA<int>());
    });

    test('listRooms sends list_rooms message and returns empty list', () async {
      final rooms = await repo.listRooms();

      expect(fakeWs.sent, hasLength(1));
      expect(fakeWs.sent.first['type'], 'list_rooms');
      // Room list arrives async via GameEvent stream; sync return is empty
      expect(rooms, isEmpty);
    });
  });

  group('MultiplayerRepositoryImpl — return values', () {
    test('quickMatch returns true', () async {
      expect(await repo.quickMatch(), isTrue);
    });

    test('createRoom returns true', () async {
      expect(await repo.createRoom('Room A'), isTrue);
    });

    test('joinRoom returns true', () async {
      expect(await repo.joinRoom('room-1'), isTrue);
    });

    test('currentMatch returns null (tracked via stream)', () async {
      expect(await repo.currentMatch(), isNull);
    });

    test('currentRoom returns null (tracked via stream)', () async {
      expect(await repo.currentRoom(), isNull);
    });

    test('events() returns ws client events stream', () {
      expect(repo.events(), same(fakeWs.events));
    });
  });
}