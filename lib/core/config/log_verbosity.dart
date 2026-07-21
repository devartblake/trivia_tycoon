/// Runtime switches for chatty, high-frequency logging that is useful when
/// debugging a subsystem but pure noise otherwise.
///
/// These gate only *informational* per-event / lifecycle logs — warnings and
/// errors are never suppressed by these flags. Everything defaults to `false`
/// so the console stays quiet in normal runs; flip a flag from a debug menu, a
/// test, or wire it to remote config (see `ConfigService.loadConfig`).
class LogVerbosity {
  LogVerbosity._();

  /// Verbose `AnalyticsService` + `EventQueueService` chatter (per-event queueing,
  /// retry-cycle reports, cooldown transitions, lifecycle init logs).
  static bool analytics = false;
}
