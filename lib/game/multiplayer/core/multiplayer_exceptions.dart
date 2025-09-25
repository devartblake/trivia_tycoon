/// Base class for multiplayer-related errors.
sealed class MultiplayerException implements Exception {
  final String message;
  final int? status; // for HTTP codes
  const MultiplayerException(this.message, {this.status});

  @override
  String toString() => '${runtimeType}(status: $status, message: $message)';
}

/// Thrown when the WebSocket disconnects unexpectedly.
class WsDisconnected extends MultiplayerException {
  const WsDisconnected([String msg = 'WebSocket disconnected']) : super(msg);
}

/// Generic HTTP failure with status & body.
class HttpFailure extends MultiplayerException {
  final String? body;
  const HttpFailure({required int status, String message = 'HTTP failure', this.body})
      : super(message, status: status);
}

/// Protocol-level error (unexpected op, parse error).
class ProtocolFailure extends MultiplayerException {
  const ProtocolFailure(String message) : super(message);
}

/// User not authorized/forbidden.
class NotAuthorized extends MultiplayerException {
  const NotAuthorized([String msg = 'Not authorized']) : super(msg, status: 401);
}

/// Room is full.
class RoomFull extends MultiplayerException {
  const RoomFull([String msg = 'Room is full']) : super(msg);
}

/// Request validation / bad input.
class BadRequest extends MultiplayerException {
  const BadRequest([String msg = 'Bad request']) : super(msg, status: 400);
}
