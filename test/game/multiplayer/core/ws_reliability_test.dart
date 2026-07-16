import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/data/sources/ws_reliability.dart';

void main() {
  group('ReconnectPolicy.initial()', () {
    test('creates expected defaults', () {
      final p = ReconnectPolicy.initial();
      expect(p.initialDelay, const Duration(milliseconds: 500));
      expect(p.maxDelay, const Duration(seconds: 20));
      expect(p.multiplier, 1.7);
      expect(p.jitter, 0.25);
      expect(p.maxAttempts, 10);
    });
  });

  group('ReconnectPolicy.canAttempt', () {
    test('attempt 1 is allowed', () {
      expect(ReconnectPolicy.initial().canAttempt(1), isTrue);
    });

    test('attempt == maxAttempts is allowed', () {
      expect(ReconnectPolicy.initial().canAttempt(10), isTrue);
    });

    test('attempt > maxAttempts is not allowed', () {
      expect(ReconnectPolicy.initial().canAttempt(11), isFalse);
    });

    test('unlimited when maxAttempts == 0', () {
      const policy = ReconnectPolicy(
        initialDelay: Duration(milliseconds: 100),
        maxDelay: Duration(seconds: 5),
        multiplier: 2.0,
        jitter: 0.0,
        maxAttempts: 0,
      );
      expect(policy.canAttempt(9999), isTrue);
    });

    test('unlimited when maxAttempts < 0', () {
      const policy = ReconnectPolicy(
        initialDelay: Duration(milliseconds: 100),
        maxDelay: Duration(seconds: 5),
        multiplier: 2.0,
        jitter: 0.0,
        maxAttempts: -1,
      );
      expect(policy.canAttempt(1000), isTrue);
    });
  });

  group('ReconnectPolicy.nextDelay', () {
    const noJitter = ReconnectPolicy(
      initialDelay: Duration(milliseconds: 500),
      maxDelay: Duration(seconds: 20),
      multiplier: 2.0,
      jitter: 0.0,
      maxAttempts: 10,
    );

    test('attempt 1 returns initialDelay (multiplier=2, jitter=0)', () {
      expect(noJitter.nextDelay(1).inMilliseconds, 500);
    });

    test('attempt 2 doubles the delay (multiplier=2, jitter=0)', () {
      expect(noJitter.nextDelay(2).inMilliseconds, 1000);
    });

    test('attempt 3 quadruples initial delay (multiplier=2, jitter=0)', () {
      expect(noJitter.nextDelay(3).inMilliseconds, 2000);
    });

    test('delay is capped at maxDelay', () {
      expect(noJitter.nextDelay(10),
          lessThanOrEqualTo(const Duration(seconds: 20)));
    });

    test('delay is never negative across all attempts', () {
      for (var i = 1; i <= 10; i++) {
        expect(noJitter.nextDelay(i).inMilliseconds, greaterThanOrEqualTo(0));
      }
    });

    test('delay with jitter stays within [0, maxDelay]', () {
      final policy = ReconnectPolicy.initial();
      for (var i = 1; i <= 10; i++) {
        final delay = policy.nextDelay(i);
        expect(delay.inMilliseconds, greaterThanOrEqualTo(0));
        expect(delay, lessThanOrEqualTo(const Duration(seconds: 20)));
      }
    });

    test('delays grow as attempt number increases (no jitter)', () {
      final d1 = noJitter.nextDelay(1);
      final d2 = noJitter.nextDelay(2);
      final d3 = noJitter.nextDelay(3);
      expect(d2, greaterThan(d1));
      expect(d3, greaterThan(d2));
    });
  });
}
