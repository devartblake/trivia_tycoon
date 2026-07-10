import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/multiplayer/core/multiplayer_result.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _failure = MultiplayerFailure('test/error', 'something went wrong');

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Ok<T>
  // -------------------------------------------------------------------------

  group('Ok', () {
    test('stores value', () {
      expect(const Ok(42).value, 42);
    });

    test('isOk is true', () {
      expect(const Ok('hello').isOk, isTrue);
    });

    test('isErr is false', () {
      expect(const Ok('hello').isErr, isFalse);
    });

    test('match calls ok callback with value', () {
      final result = const Ok(7).match(
        ok: (v) => 'got $v',
        err: (_) => 'error',
      );
      expect(result, 'got 7');
    });

    test('getOrElse returns the value', () {
      expect(const Ok(99).getOrElse(0), 99);
    });
  });

  // -------------------------------------------------------------------------
  // Err<T>
  // -------------------------------------------------------------------------

  group('Err', () {
    test('stores failure', () {
      expect(const Err<int>(_failure).failure.code, 'test/error');
    });

    test('isOk is false', () {
      expect(const Err<int>(_failure).isOk, isFalse);
    });

    test('isErr is true', () {
      expect(const Err<int>(_failure).isErr, isTrue);
    });

    test('match calls err callback with failure', () {
      final result = const Err<int>(_failure).match(
        ok: (v) => 'value',
        err: (f) => 'error: ${f.code}',
      );
      expect(result, 'error: test/error');
    });

    test('getOrElse returns the fallback', () {
      expect(const Err<int>(_failure).getOrElse(42), 42);
    });
  });

  // -------------------------------------------------------------------------
  // MultiplayerFailure
  // -------------------------------------------------------------------------

  group('MultiplayerFailure', () {
    test('stores code and message', () {
      const f = MultiplayerFailure('http/401', 'Unauthorized');
      expect(f.code, 'http/401');
      expect(f.message, 'Unauthorized');
    });

    test('cause and stackTrace are null by default', () {
      const f = MultiplayerFailure('c', 'm');
      expect(f.cause, isNull);
      expect(f.stackTrace, isNull);
    });

    test('accepts optional cause', () {
      final ex = Exception('underlying');
      final f = MultiplayerFailure('code', 'msg', cause: ex);
      expect(f.cause, ex);
    });

    test('toString contains code and message', () {
      const f = MultiplayerFailure('ws/lost', 'disconnected');
      expect(f.toString(), contains('ws/lost'));
      expect(f.toString(), contains('disconnected'));
    });
  });

  // -------------------------------------------------------------------------
  // Type hierarchy
  // -------------------------------------------------------------------------

  group('MultiplayerResult type hierarchy', () {
    test('Ok is a MultiplayerResult', () {
      expect(const Ok(1), isA<MultiplayerResult<int>>());
    });

    test('Err is a MultiplayerResult', () {
      expect(const Err<int>(_failure), isA<MultiplayerResult<int>>());
    });
  });

  // -------------------------------------------------------------------------
  // match exhaustiveness — both branches exercised
  // -------------------------------------------------------------------------

  group('match exhaustiveness', () {
    test('ok branch is reached only for Ok', () {
      final results = <MultiplayerResult<int>>[
        const Ok(1),
        const Err(_failure),
      ];
      final branches = results
          .map((r) => r.match(ok: (_) => 'ok', err: (_) => 'err'))
          .toList();
      expect(branches, ['ok', 'err']);
    });
  });
}
