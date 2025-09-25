import 'dart:math';

/// Simple exponential backoff with jitter.
/// Usage:
///   final policy = ReconnectPolicy.initial();
///   final delay = policy.nextDelay(attempt); // attempt starts at 1
class ReconnectPolicy {
  final Duration initialDelay;
  final Duration maxDelay;
  final double multiplier; // e.g., 1.7
  final double jitter;     // 0.0..1.0
  final int maxAttempts;   // <=0 means unlimited

  const ReconnectPolicy({
    required this.initialDelay,
    required this.maxDelay,
    required this.multiplier,
    required this.jitter,
    required this.maxAttempts,
  });

  factory ReconnectPolicy.initial() => const ReconnectPolicy(
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 20),
    multiplier: 1.7,
    jitter: 0.25,
    maxAttempts: 10,
  );

  Duration nextDelay(int attempt) {
    assert(attempt >= 1);
    final base = initialDelay.inMilliseconds * pow(multiplier, attempt - 1);
    final capped = min(base.toDouble(), maxDelay.inMilliseconds.toDouble());
    final jitterMs = capped * (jitter * (Random().nextDouble() * 2 - 1)); // ±jitter
    final total = (capped + jitterMs).clamp(0, maxDelay.inMilliseconds.toDouble());
    return Duration(milliseconds: total.round());
  }

  bool canAttempt(int attempt) => maxAttempts <= 0 || attempt <= maxAttempts;
}
