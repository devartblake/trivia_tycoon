import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/multiplayer/data/dto/ws_envelope_dto.dart';

void main() {
  // ---------------------------------------------------------------------------
  // fromJson
  // ---------------------------------------------------------------------------

  group('WsEnvelopeDto.fromJson', () {
    test('parses happy-path envelope', () {
      final dto = WsEnvelopeDto.fromJson({
        'op': 'room.joined',
        'ts': 1700000000000,
        'data': {'roomId': 'r1'},
        'seq': 3,
        'reqId': 'abc',
      });
      expect(dto.op, 'room.joined');
      expect(dto.ts, 1700000000000);
      expect(dto.data, {'roomId': 'r1'});
      expect(dto.seq, 3);
      expect(dto.reqId, 'abc');
    });

    test('op defaults to empty string when absent', () {
      final dto = WsEnvelopeDto.fromJson({'ts': 1});
      expect(dto.op, '');
    });

    test('seq is null when absent', () {
      final dto = WsEnvelopeDto.fromJson({'op': 'x', 'ts': 1});
      expect(dto.seq, isNull);
    });

    test('reqId is null when absent', () {
      final dto = WsEnvelopeDto.fromJson({'op': 'x', 'ts': 1});
      expect(dto.reqId, isNull);
    });

    test('data is null when absent', () {
      final dto = WsEnvelopeDto.fromJson({'op': 'x', 'ts': 1});
      expect(dto.data, isNull);
    });

    test('data is null when payload is a non-Map scalar', () {
      final dto = WsEnvelopeDto.fromJson({'op': 'x', 'ts': 1, 'data': 'hello'});
      expect(dto.data, isNull);
    });

    group('type coercion', () {
      test('ts as String is parsed to int', () {
        final dto = WsEnvelopeDto.fromJson({'op': 'x', 'ts': '1700000000000'});
        expect(dto.ts, 1700000000000);
      });

      test('ts as double is truncated to int', () {
        final dto = WsEnvelopeDto.fromJson({'op': 'x', 'ts': 1700000000000.9});
        expect(dto.ts, 1700000000000);
      });

      test('seq as String is parsed to int', () {
        final dto = WsEnvelopeDto.fromJson({'op': 'x', 'ts': 1, 'seq': '5'});
        expect(dto.seq, 5);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // toJson / round-trip
  // ---------------------------------------------------------------------------

  group('WsEnvelopeDto.toJson', () {
    test('round-trip preserves all fields', () {
      final original = WsEnvelopeDto(
        op: 'match.started',
        ts: 1700000000000,
        data: {'matchId': 'm1'},
        seq: 7,
        reqId: 'req-123',
      );
      final restored = WsEnvelopeDto.fromJson(original.toJson());
      expect(restored.op, original.op);
      expect(restored.ts, original.ts);
      expect(restored.data, original.data);
      expect(restored.seq, original.seq);
      expect(restored.reqId, original.reqId);
    });

    test('null data is omitted from toJson map', () {
      final dto = WsEnvelopeDto(op: 'x', ts: 1);
      expect(dto.toJson().containsKey('data'), isFalse);
    });

    test('null seq is omitted from toJson map', () {
      final dto = WsEnvelopeDto(op: 'x', ts: 1);
      expect(dto.toJson().containsKey('seq'), isFalse);
    });

    test('null reqId is omitted from toJson map', () {
      final dto = WsEnvelopeDto(op: 'x', ts: 1);
      expect(dto.toJson().containsKey('reqId'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  group('WsEnvelopeDto.copyWith', () {
    final base = WsEnvelopeDto(
      op: 'a',
      ts: 100,
      data: {'k': 'v'},
      seq: 1,
      reqId: 'r',
    );

    test('updates op only, preserves other fields', () {
      final copy = base.copyWith(op: 'b');
      expect(copy.op, 'b');
      expect(copy.ts, 100);
      expect(copy.data, {'k': 'v'});
      expect(copy.seq, 1);
    });

    test('clearData sets data to null', () {
      expect(base.copyWith(clearData: true).data, isNull);
    });

    test('clearSeq sets seq to null', () {
      expect(base.copyWith(clearSeq: true).seq, isNull);
    });

    test('clearReqId sets reqId to null', () {
      expect(base.copyWith(clearReqId: true).reqId, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // equality / hashCode
  // ---------------------------------------------------------------------------

  group('WsEnvelopeDto equality', () {
    test('equal when all fields match', () {
      const a = WsEnvelopeDto(op: 'x', ts: 1);
      const b = WsEnvelopeDto(op: 'x', ts: 1);
      expect(a, b);
    });

    test('not equal when op differs', () {
      const a = WsEnvelopeDto(op: 'x', ts: 1);
      const b = WsEnvelopeDto(op: 'y', ts: 1);
      expect(a, isNot(b));
    });

    test('equal with matching data maps', () {
      final a = WsEnvelopeDto(op: 'x', ts: 1, data: {'k': 'v'});
      final b = WsEnvelopeDto(op: 'x', ts: 1, data: {'k': 'v'});
      expect(a, b);
    });

    test('hashCode consistent for equal values', () {
      const a = WsEnvelopeDto(op: 'x', ts: 1, seq: 3);
      const b = WsEnvelopeDto(op: 'x', ts: 1, seq: 3);
      expect(a.hashCode, b.hashCode);
    });
  });
}
