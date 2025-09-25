/// Multiplayer connection status and diagnostics.
///
/// Represents the client’s connection lifecycle to the multiplayer backend.
/// Keep this state **UI-agnostic** so it can be consumed by controllers, services,
/// and widgets alike.
class MultiplayerState {
  /// True when the socket/session is open and authenticated (if applicable).
  final bool connected;

  /// Last measured round-trip latency in milliseconds (best-effort).
  final int latencyMs;

  /// Non-null if the controller/service wants the UI to surface an error.
  final String? error;

  const MultiplayerState({
    required this.connected,
    this.latencyMs = 0,
    this.error,
  });

  /// Disconnected baseline state.
  const MultiplayerState.disconnected()
      : connected = false,
        latencyMs = 0,
        error = null;

  /// While initiating a connection.
  const MultiplayerState.connecting()
      : connected = false,
        latencyMs = 0,
        error = null;

  /// Connected with an optional latency snapshot.
  const MultiplayerState.connected({int latencyMs = 0})
      : connected = true,
        latencyMs = latencyMs,
        error = null;

  /// Error state (disconnected).
  const MultiplayerState.error(String message)
      : connected = false,
        latencyMs = 0,
        error = message;

  MultiplayerState copyWith({
    bool? connected,
    int? latencyMs,
    String? error,         // pass explicit null to clear
    bool clearError = false,
  }) {
    return MultiplayerState(
      connected: connected ?? this.connected,
      latencyMs: latencyMs ?? this.latencyMs,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  String toString() =>
      'MultiplayerState(connected: $connected, latencyMs: $latencyMs, error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MultiplayerState &&
              runtimeType == other.runtimeType &&
              connected == other.connected &&
              latencyMs == other.latencyMs &&
              error == other.error;

  @override
  int get hashCode => Object.hash(connected, latencyMs, error);
}
