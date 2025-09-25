class WsProtocol {
  // handshake / infra
  static const opHello = 'hello';
  static const opAck = 'ack';
  static const opPing = 'ping';
  static const opPong = 'pong';

  // room / lobby
  static const opJoinedRoom = 'room.joined';
  static const opPlayerJoined = 'room.player_joined';
  static const opPlayerLeft = 'room.player_left';
  static const opHostChanged = 'room.host_changed';

  // match
  static const opMatchStarted = 'match.started';
  static const opTurnStarted = 'match.turn_started';
  static const opTurnRevealed = 'match.turn_revealed';
  static const opAnswerAccepted = 'match.answer_accepted';
  static const opAnswerRejected = 'match.answer_rejected';
  static const opMatchEnded = 'match.ended';

  // server-level
  static const opServerNotice = 'server.notice';
  static const opKicked = 'server.kicked';
  static const opProtocolError = 'server.protocol_error';
}
