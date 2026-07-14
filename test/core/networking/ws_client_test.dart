import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/networking/ws_client.dart';
import 'package:synaptix/core/networking/ws_protocol.dart';
import 'package:synaptix/core/networking/ws_reliability.dart';

void main() {
  // -------------------------------------------------------------------------
  // WsState enum
  // -------------------------------------------------------------------------

  group('WsState enum', () {
    test('has exactly 4 values', () {
      expect(WsState.values.length, 4);
    });

    test('contains disconnected, connecting, connected, reconnecting', () {
      expect(
          WsState.values,
          containsAll([
            WsState.disconnected,
            WsState.connecting,
            WsState.connected,
            WsState.reconnecting,
          ]));
    });

    test('all values are distinct', () {
      expect(WsState.values.toSet().length, WsState.values.length);
    });
  });

  // -------------------------------------------------------------------------
  // WsEnvelope
  // -------------------------------------------------------------------------

  group('WsEnvelope', () {
    test('stores op, ts, and optional fields', () {
      final env = WsEnvelope(op: 'hello', ts: 1000, seq: 1);
      expect(env.op, 'hello');
      expect(env.ts, 1000);
      expect(env.seq, 1);
    });

    test('seq and data are null by default', () {
      final env = WsEnvelope(op: 'ping', ts: 2000);
      expect(env.seq, isNull);
      expect(env.data, isNull);
    });

    test('toJson includes op and ts', () {
      final env = WsEnvelope(op: 'test', ts: 999);
      final json = env.toJson();
      expect(json['op'], 'test');
      expect(json['ts'], 999);
    });

    test('toJson excludes seq when null', () {
      final env = WsEnvelope(op: 'test', ts: 0);
      final json = env.toJson();
      expect(json.containsKey('seq'), isFalse);
    });

    test('toJson includes seq when non-null', () {
      final env = WsEnvelope(op: 'test', ts: 0, seq: 42);
      final json = env.toJson();
      expect(json['seq'], 42);
    });

    test('toJson excludes data when null', () {
      final env = WsEnvelope(op: 'test', ts: 0);
      final json = env.toJson();
      expect(json.containsKey('data'), isFalse);
    });

    test('toJson includes data when non-null', () {
      final env = WsEnvelope(op: 'test', ts: 0, data: {'key': 'val'});
      final json = env.toJson();
      expect(json['data'], {'key': 'val'});
    });

    test('fromJson round-trip preserves all fields', () {
      final original =
          WsEnvelope(op: 'match.turn', ts: 12345, seq: 7, data: {'move': 'A'});
      final restored = WsEnvelope.fromJson(original.toJson());
      expect(restored.op, 'match.turn');
      expect(restored.ts, 12345);
      expect(restored.seq, 7);
      expect(restored.data?['move'], 'A');
    });

    test('fromJson with null seq produces null seq', () {
      final env = WsEnvelope.fromJson({'op': 'ack', 'ts': 0});
      expect(env.seq, isNull);
    });

    test('fromJson with null data produces null data', () {
      final env = WsEnvelope.fromJson({'op': 'ack', 'ts': 0});
      expect(env.data, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // WsClient construction and initial state
  // -------------------------------------------------------------------------

  group('WsClient construction', () {
    late WsClient client;

    setUp(() {
      client = WsClient(url: 'ws://localhost:9999');
    });

    tearDown(() {
      client.disconnect();
    });

    test('initial state is disconnected', () {
      expect(client.state, WsState.disconnected);
    });

    test('isConnected is false initially', () {
      expect(client.isConnected, isFalse);
    });

    test('construction with callbacks does not throw', () {
      expect(
        () => WsClient(
          url: 'ws://localhost:9999',
          onMessage: (_) {},
          onStateChange: (_) {},
          onError: (_) {},
        ),
        returnsNormally,
      );
    });

    test('messageStream is a Stream', () {
      expect(client.messageStream, isA<Stream>());
    });

    test('stateStream is a Stream', () {
      expect(client.stateStream, isA<Stream>());
    });
  });

  // -------------------------------------------------------------------------
  // WsClient.send while disconnected
  // -------------------------------------------------------------------------

  group('WsClient.send while disconnected', () {
    test('calls onError when not connected', () {
      String? receivedError;
      final client = WsClient(
        url: 'ws://localhost:9999',
        onError: (e) => receivedError = e,
      );

      client.send(WsEnvelope(op: 'test', ts: 0));
      addTearDown(client.disconnect);

      expect(receivedError, isNotNull);
      expect(receivedError, contains('Not connected'));
    });

    test('send does not throw even without onError callback', () {
      final client = WsClient(url: 'ws://localhost:9999');
      addTearDown(client.disconnect);
      expect(
        () => client.send(WsEnvelope(op: 'test', ts: 0)),
        returnsNormally,
      );
    });
  });

  // -------------------------------------------------------------------------
  // WsClient.disconnect
  // -------------------------------------------------------------------------

  group('WsClient.disconnect', () {
    test('disconnect on disconnected client does not throw', () {
      final client = WsClient(url: 'ws://localhost:9999');
      expect(() => client.disconnect(), returnsNormally);
    });
  });

  // -------------------------------------------------------------------------
  // WsReliability
  // -------------------------------------------------------------------------

  group('WsReliability', () {
    late WsReliability reliability;

    setUp(() {
      reliability = WsReliability();
    });

    tearDown(() {
      reliability.dispose();
    });

    test('pendingCount is 0 initially', () {
      expect(reliability.pendingCount, 0);
    });

    test('handleMessage returns true for message without seq', () {
      final env = WsEnvelope(op: 'msg', ts: 0);
      expect(reliability.handleMessage(env), isTrue);
    });

    test('handleMessage returns true for first occurrence of a seq', () {
      final env = WsEnvelope(op: 'msg', ts: 0, seq: 1);
      expect(reliability.handleMessage(env), isTrue);
    });

    test('handleMessage returns false for duplicate seq', () {
      final env = WsEnvelope(op: 'msg', ts: 0, seq: 42);
      reliability.handleMessage(env);
      expect(reliability.handleMessage(env), isFalse);
    });

    test('handleMessage accepts different seqs as distinct', () {
      final env1 = WsEnvelope(op: 'msg', ts: 0, seq: 1);
      final env2 = WsEnvelope(op: 'msg', ts: 0, seq: 2);
      expect(reliability.handleMessage(env1), isTrue);
      expect(reliability.handleMessage(env2), isTrue);
    });

    test('sendWithAck increments pendingCount', () {
      final env = WsEnvelope(op: 'test', ts: 0);
      reliability.sendWithAck(env, (_) {});
      expect(reliability.pendingCount, 1);
    });

    test('handleAck removes pending message', () {
      late String capturedMsgId;
      final env = WsEnvelope(op: 'test', ts: 0);
      reliability.sendWithAck(env, (msg) {
        capturedMsgId = msg.data?['msgId'] as String;
      });
      reliability.handleAck(capturedMsgId);
      expect(reliability.pendingCount, 0);
    });

    test('handleAck for unknown id does not throw', () {
      expect(() => reliability.handleAck('nonexistent-id'), returnsNormally);
    });

    test('reset clears pending messages', () {
      final env = WsEnvelope(op: 'test', ts: 0);
      reliability.sendWithAck(env, (_) {});
      reliability.reset();
      expect(reliability.pendingCount, 0);
    });

    test('reset clears received sequence numbers (re-accepts same seq)', () {
      final env = WsEnvelope(op: 'msg', ts: 0, seq: 99);
      reliability.handleMessage(env);
      reliability.reset();
      // After reset, same seq should be accepted again
      expect(reliability.handleMessage(env), isTrue);
    });

    test('dispose does not throw', () {
      final r = WsReliability();
      expect(() => r.dispose(), returnsNormally);
    });

    test('sendWithAck adds msgId to message data', () {
      final env = WsEnvelope(op: 'cmd', ts: 0, data: {'action': 'jump'});
      WsEnvelope? sent;
      reliability.sendWithAck(env, (msg) => sent = msg);

      expect(sent, isNotNull);
      expect(sent!.data?.containsKey('msgId'), isTrue);
      expect(sent!.data?['action'], 'jump'); // original data preserved
    });
  });
}
