/// Base class for multiplayer-related errors.
sealed class MultiplayerException implements Exception {
  final String message;
  final int? status; // for HTTP codes
  const MultiplayerException(this.message, {this.status});

  @override
  String toString() => '$runtimeType(status: $status, message: $message)';
}

/// Thrown when the WebSocket disconnects unexpectedly.
class WsDisconnected extends MultiplayerException {
  const WsDisconnected([super.msg = 'WebSocket disconnected']);
}

/// Generic HTTP failure with status & body.
class HttpFailure extends MultiplayerException {
  final String? body;
  const HttpFailure(
      {required int status, String message = 'HTTP failure', this.body})
      : super(message, status: status);
}

/// Protocol-level error (unexpected op, parse error).
class ProtocolFailure extends MultiplayerException {
  const ProtocolFailure(super.message);
}

/// User not authorized/forbidden.
class NotAuthorized extends MultiplayerException {
  const NotAuthorized([super.msg = 'Not authorized']) : super(status: 401);
}

/// Room is full.
class RoomFull extends MultiplayerException {
  const RoomFull([super.msg = 'Room is full']);
}

/// Request validation / bad input.
class BadRequest extends MultiplayerException {
  const BadRequest([super.msg = 'Bad request']) : super(status: 400);
}
