import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_difficulty.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_game_id.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_result.dart';
import 'package:trivia_tycoon/arcade/services/arcade_session_service.dart';

ArcadeResult _result({
  int score = 250,
  ArcadeGameId gameId = ArcadeGameId.quickMathRush,
  ArcadeDifficulty difficulty = ArcadeDifficulty.normal,
  Duration duration = Duration.zero,
}) =>
    ArcadeResult(
      gameId: gameId,
      difficulty: difficulty,
      score: score,
      duration: duration,
      metadata: const {'key': 'value'},
    );

void main() {
  const svc = ArcadeSessionService();

  // -------------------------------------------------------------------------
  // startSession()
  // -------------------------------------------------------------------------

  group('ArcadeSessionService.startSession()', () {
    test('returns a DateTime close to now', () {
      final before = DateTime.now();
      final started = svc.startSession();
      final after = DateTime.now();
      expect(started.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(started.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('two successive calls return ascending timestamps', () async {
      final first = svc.startSession();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = svc.startSession();
      expect(second.isAfter(first) || second.isAtSameMomentAs(first), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // endSession()
  // -------------------------------------------------------------------------

  group('ArcadeSessionService.endSession()', () {
    test('returns a non-negative Duration', () {
      final started = svc.startSession();
      final elapsed = svc.endSession(started);
      expect(elapsed.inMicroseconds, greaterThanOrEqualTo(0));
    });

    test('returns a Duration that grows with real wait time', () async {
      final started = svc.startSession();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final elapsed = svc.endSession(started);
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(15));
    });

    test('start → end → Duration is bounded by a reasonable upper limit', () async {
      final started = svc.startSession();
      final elapsed = svc.endSession(started);
      // Should complete in under 1 second in any test environment
      expect(elapsed.inSeconds, lessThan(5));
    });
  });

  // -------------------------------------------------------------------------
  // attachDuration()
  // -------------------------------------------------------------------------

  group('ArcadeSessionService.attachDuration()', () {
    test('replaces duration in the result', () {
      const dur = Duration(seconds: 45);
      final original = _result();
      final updated = svc.attachDuration(original, dur);
      expect(updated.duration, dur);
    });

    test('preserves gameId', () {
      const dur = Duration(seconds: 30);
      final original = _result(gameId: ArcadeGameId.memoryFlip);
      expect(svc.attachDuration(original, dur).gameId, ArcadeGameId.memoryFlip);
    });

    test('preserves difficulty', () {
      const dur = Duration(seconds: 30);
      final original = _result(difficulty: ArcadeDifficulty.hard);
      expect(svc.attachDuration(original, dur).difficulty, ArcadeDifficulty.hard);
    });

    test('preserves score', () {
      const dur = Duration(seconds: 30);
      final original = _result(score: 9999);
      expect(svc.attachDuration(original, dur).score, 9999);
    });

    test('preserves metadata', () {
      const dur = Duration(seconds: 30);
      final original = _result();
      final updated = svc.attachDuration(original, dur);
      expect(updated.metadata, original.metadata);
    });

    test('Duration.zero original is replaced correctly', () {
      const dur = Duration(minutes: 2);
      final original = _result(duration: Duration.zero);
      expect(svc.attachDuration(original, dur).duration, dur);
    });

    test('returned result is a new object (not identical)', () {
      const dur = Duration(seconds: 10);
      final original = _result();
      final updated = svc.attachDuration(original, dur);
      expect(identical(original, updated), isFalse);
    });
  });
}
