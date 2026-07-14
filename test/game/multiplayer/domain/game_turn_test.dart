import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/domain/entities/game_turn.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _t0 = DateTime.utc(2026, 1, 1, 12, 0, 0);
final _t30 = DateTime.utc(2026, 1, 1, 12, 0, 30);
final _t60 = DateTime.utc(2026, 1, 1, 12, 1, 0);

GameTurn _turn({
  String questionId = 'q1',
  DateTime? startAt,
  DateTime? endAt,
  int? remainingMs,
}) =>
    GameTurn(
      questionId: questionId,
      startAt: startAt ?? _t0,
      endAt: endAt ?? _t30,
      remainingMs: remainingMs,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // duration getter
  // -------------------------------------------------------------------------

  group('GameTurn.duration', () {
    test('returns difference between endAt and startAt', () {
      final turn = _turn(startAt: _t0, endAt: _t30);
      expect(turn.duration, const Duration(seconds: 30));
    });

    test('60-second turn returns 60 s duration', () {
      final turn = _turn(startAt: _t0, endAt: _t60);
      expect(turn.duration, const Duration(minutes: 1));
    });

    test('returns zero when startAt equals endAt', () {
      final turn = _turn(startAt: _t0, endAt: _t0);
      expect(turn.duration, Duration.zero);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  group('GameTurn.copyWith', () {
    test('returns identical turn when no arguments given', () {
      final t = _turn(remainingMs: 5000);
      final copy = t.copyWith();
      expect(copy.questionId, t.questionId);
      expect(copy.startAt, t.startAt);
      expect(copy.endAt, t.endAt);
      expect(copy.remainingMs, t.remainingMs);
    });

    test('replaces questionId', () {
      expect(_turn().copyWith(questionId: 'q99').questionId, 'q99');
    });

    test('replaces startAt', () {
      expect(_turn().copyWith(startAt: _t60).startAt, _t60);
    });

    test('replaces endAt', () {
      expect(_turn().copyWith(endAt: _t60).endAt, _t60);
    });

    test('replaces remainingMs', () {
      expect(_turn().copyWith(remainingMs: 1500).remainingMs, 1500);
    });

    test('clearRemaining sets remainingMs to null', () {
      final t = _turn(remainingMs: 5000);
      expect(t.copyWith(clearRemaining: true).remainingMs, isNull);
    });

    test('remainingMs argument ignored when clearRemaining is true', () {
      final t = _turn(remainingMs: 5000);
      expect(t.copyWith(remainingMs: 999, clearRemaining: true).remainingMs,
          isNull);
    });

    test('null remainingMs stays null without clearRemaining', () {
      expect(_turn().copyWith().remainingMs, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Equality and hashCode
  // -------------------------------------------------------------------------

  group('GameTurn equality', () {
    test('equal turns compare as equal', () {
      final a = _turn(questionId: 'q1', remainingMs: 100);
      final b = _turn(questionId: 'q1', remainingMs: 100);
      expect(a, b);
    });

    test('different questionId → not equal', () {
      expect(_turn(questionId: 'q1'), isNot(_turn(questionId: 'q2')));
    });

    test('different startAt → not equal', () {
      expect(_turn(startAt: _t0), isNot(_turn(startAt: _t30)));
    });

    test('different remainingMs → not equal', () {
      expect(_turn(remainingMs: 100), isNot(_turn(remainingMs: 200)));
    });

    test('null vs non-null remainingMs → not equal', () {
      expect(_turn(), isNot(_turn(remainingMs: 100)));
    });

    test('equal turns have same hashCode', () {
      expect(_turn().hashCode, _turn().hashCode);
    });

    test('different turns generally have different hashCodes', () {
      expect(
        _turn(questionId: 'q1').hashCode,
        isNot(_turn(questionId: 'q2').hashCode),
      );
    });
  });

  // -------------------------------------------------------------------------
  // toString
  // -------------------------------------------------------------------------

  group('GameTurn.toString', () {
    test('contains questionId', () {
      expect(_turn(questionId: 'q-42').toString(), contains('q-42'));
    });

    test('contains remainingMs when present', () {
      expect(_turn(remainingMs: 3000).toString(), contains('3000'));
    });
  });
}
