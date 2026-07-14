import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/data/dto/turn_dto.dart';

void main() {
  // -------------------------------------------------------------------------
  // fromJson
  // -------------------------------------------------------------------------

  group('TurnDto.fromJson', () {
    test('parses all fields from int values', () {
      final dto = TurnDto.fromJson({
        'questionId': 'q42',
        'startAtMs': 1000000,
        'endAtMs': 1030000,
      });
      expect(dto.questionId, 'q42');
      expect(dto.startAtMs, 1000000);
      expect(dto.endAtMs, 1030000);
    });

    test('coerces string startAtMs via int.tryParse', () {
      final dto = TurnDto.fromJson({
        'questionId': 'q1',
        'startAtMs': '2000',
        'endAtMs': 3000,
      });
      expect(dto.startAtMs, 2000);
    });

    test('coerces string endAtMs via int.tryParse', () {
      final dto = TurnDto.fromJson({
        'questionId': 'q1',
        'startAtMs': 1000,
        'endAtMs': '4000',
      });
      expect(dto.endAtMs, 4000);
    });

    test('defaults startAtMs to 0 on missing key', () {
      final dto = TurnDto.fromJson({'questionId': 'q1', 'endAtMs': 1000});
      expect(dto.startAtMs, 0);
    });

    test('defaults endAtMs to 0 on missing key', () {
      final dto = TurnDto.fromJson({'questionId': 'q1', 'startAtMs': 1000});
      expect(dto.endAtMs, 0);
    });

    test('defaults questionId to empty string when missing', () {
      final dto = TurnDto.fromJson({'startAtMs': 0, 'endAtMs': 0});
      expect(dto.questionId, '');
    });

    test('coerces non-string questionId via toString', () {
      final dto =
          TurnDto.fromJson({'questionId': 99, 'startAtMs': 0, 'endAtMs': 0});
      expect(dto.questionId, '99');
    });
  });

  // -------------------------------------------------------------------------
  // toJson
  // -------------------------------------------------------------------------

  group('TurnDto.toJson', () {
    test('serialises all fields', () {
      const dto = TurnDto(questionId: 'q1', startAtMs: 1000, endAtMs: 2000);
      final json = dto.toJson();
      expect(json['questionId'], 'q1');
      expect(json['startAtMs'], 1000);
      expect(json['endAtMs'], 2000);
    });

    test('contains exactly three keys', () {
      const dto = TurnDto(questionId: 'q', startAtMs: 0, endAtMs: 0);
      expect(dto.toJson().keys.toSet(), {'questionId', 'startAtMs', 'endAtMs'});
    });
  });

  // -------------------------------------------------------------------------
  // Round-trip
  // -------------------------------------------------------------------------

  group('TurnDto round-trip', () {
    test('fromJson → toJson → fromJson preserves all values', () {
      final original = TurnDto.fromJson({
        'questionId': 'q-round',
        'startAtMs': 1700000000000,
        'endAtMs': 1700000030000,
      });
      final restored = TurnDto.fromJson(original.toJson());
      expect(restored.questionId, original.questionId);
      expect(restored.startAtMs, original.startAtMs);
      expect(restored.endAtMs, original.endAtMs);
    });
  });
}
