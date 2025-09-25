import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_event.dart';
import 'package:trivia_tycoon/game/multiplayer/data/dto/ws_envelope_dto.dart';
import 'package:trivia_tycoon/game/multiplayer/data/sources/ws_protocol.dart';

/// Translates raw WS envelopes (from FastAPI) into domain-level [GameEvent]s.
/// Keep this file focused on parsing and op-name routing only. Business logic
/// belongs in controllers/services.
class EventMapper {
  const EventMapper();

  /// Primary entry: convert a strongly-typed envelope DTO into a [GameEvent].
  /// Returns `null` if the op is informational-only or unrecognized.
  GameEvent? fromEnvelope(WsEnvelopeDto env) {
    final data = env.data ?? const <String, dynamic>{};
    switch (env.op) {
    // ---- Room / Lobby ----
      case WsProtocol.opJoinedRoom:
        return JoinedRoom(
          _asString(data['roomId']),
          roomName: _asString(data['roomName']),
        );

      case WsProtocol.opPlayerJoined:
        return PlayerJoined(
          roomId: _asString(data['roomId']),
          playerId: _asString(data['playerId']),
          playerName: _asString(data['playerName']),
          isHost: _asBool(data['isHost']) ?? false,
        );

      case WsProtocol.opPlayerLeft:
        return PlayerLeft(
          roomId: _asString(data['roomId']),
          playerId: _asString(data['playerId']),
        );

      case WsProtocol.opHostChanged:
        return HostChanged(
          roomId: _asString(data['roomId']),
          newHostPlayerId: _asString(data['newHostPlayerId']),
        );

    // ---- Match lifecycle ----
      case WsProtocol.opMatchStarted:
        return MatchStarted(
          matchId: _asString(data['matchId']),
          roomId: _asString(data['roomId']),
        );

      case WsProtocol.opTurnStarted:
        return TurnStarted(
          matchId: _asString(data['matchId']),
          questionId: _asString(data['questionId']),
          durationMs: _asInt(data['durationMs']),
        );

      case WsProtocol.opTurnRevealed:
        return TurnRevealed(
          matchId: _asString(data['matchId']),
          questionId: _asString(data['questionId']),
          correctAnswerId: _asString(data['correctAnswerId']),
          playerCorrectMap: _asStringBoolMap(data['playerCorrectMap']),
        );

      case WsProtocol.opAnswerAccepted:
        return AnswerAccepted(
          matchId: _asString(data['matchId']),
          questionId: _asString(data['questionId']),
          playerId: _asString(data['playerId']),
          answerId: _asString(data['answerId']),
        );

      case WsProtocol.opAnswerRejected:
        return AnswerRejected(
          matchId: _asString(data['matchId']),
          questionId: _asString(data['questionId']),
          playerId: _asString(data['playerId']),
          reason: _asString(data['reason']),
        );

      case WsProtocol.opMatchEnded:
        return MatchEnded(
          matchId: _asString(data['matchId']),
          roomId: _asString(data['roomId']),
        );

    // ---- Server-level notices & errors ----
      case WsProtocol.opServerNotice:
        return ServerNotice(
          code: _asString(data['code']),
          message: _asString(data['message']),
        );

      case WsProtocol.opKicked:
        return Kicked(reason: _asString(data['reason']));

      case WsProtocol.opProtocolError:
        return ProtocolError(_asString(data['message']));

    // Often these are handshake/infra and not surfaced to UI:
      case WsProtocol.opHello:
      case WsProtocol.opAck:
      case WsProtocol.opPong:
        return null;

      default:
      // Unknown op: keep resilient and surface as a ProtocolError for logging.
        return ProtocolError('Unknown op: ${env.op}');
    }
  }

  /// Convenience for raw map payloads (if you read directly from WebSocket).
  GameEvent? fromMap(Map<String, dynamic> json) {
    final env = WsEnvelopeDto.fromJson(json);
    return fromEnvelope(env);
  }
}

// ----------------- helpers -----------------

String _asString(Object? v) => (v ?? '').toString();

bool? _asBool(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return null;
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

Map<String, bool> _asStringBoolMap(Object? v) {
  if (v is Map) {
    final out = <String, bool>{};
    v.forEach((k, val) {
      final key = _asString(k);
      final b = _asBool(val) ?? false;
      out[key] = b;
    });
    return out;
  }
  return const {};
}
