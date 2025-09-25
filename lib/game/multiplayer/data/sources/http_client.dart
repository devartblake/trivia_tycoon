import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:trivia_tycoon/game/multiplayer/core/multiplayer_config.dart';
import 'package:trivia_tycoon/game/multiplayer/core/multiplayer_constants.dart';
import 'package:trivia_tycoon/game/multiplayer/core/multiplayer_exceptions.dart';
import 'package:trivia_tycoon/game/multiplayer/core/multiplayer_logger.dart';

/// Thin HTTP client for multiplayer REST endpoints.
/// Handles auth header, timeouts, and simple JSON encode/decode.
class MultiplayerHttpClient {
  final MultiplayerConfig _config;
  final MultiplayerLogger _log;

  /// Provide a token getter so auth can refresh out-of-band if needed.
  final Future<String?> Function()? _tokenProvider;

  const MultiplayerHttpClient({
    required MultiplayerConfig config,
    MultiplayerLogger? logger,
    Future<String?> Function()? tokenProvider,
  })  : _config = config,
        _log = logger ?? const MultiplayerLogger(enabled: false),
        _tokenProvider = tokenProvider;

  // ------------------------ Public API ------------------------

  /// List available rooms (optionally include filters later).
  Future<List<Map<String, dynamic>>> fetchRooms() async {
    final uri = _config.httpBase.resolve(MultiplayerConstants.roomsPath);
    final resp = await _get(uri);
    final body = _decodeJson(resp.body);
    if (body is List) {
      return body.cast<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
    // You may also map to RoomDto here if you want to return DTOs
  }

  /// Create a room; returns response JSON.
  Future<Map<String, dynamic>> createRoom(String name, {int? capacity}) async {
    final uri = _config.httpBase.resolve(MultiplayerConstants.roomsPath);
    final payload = {
      'name': name,
      if (capacity != null) 'capacity': capacity,
    };
    final resp = await _post(uri, payload);
    return _decodeJson(resp.body) as Map<String, dynamic>;
  }

  /// Join a room by id; returns response JSON.
  Future<Map<String, dynamic>> joinRoom(String roomId) async {
    final uri = _config.httpBase.resolve('${MultiplayerConstants.roomsPath}/$roomId/join');
    final resp = await _post(uri, const {});
    return _decodeJson(resp.body) as Map<String, dynamic>;
  }

  /// Leave current room; if backend requires roomId, add argument.
  Future<void> leaveRoom({String? roomId}) async {
    final path = roomId == null
        ? '${MultiplayerConstants.roomsPath}/leave'
        : '${MultiplayerConstants.roomsPath}/$roomId/leave';
    final uri = _config.httpBase.resolve(path);
    await _post(uri, const {});
  }

  /// Get current match info.
  Future<Map<String, dynamic>?> fetchMatch(String matchId) async {
    final uri = _config.httpBase.resolve('${MultiplayerConstants.matchesPath}/$matchId');
    final resp = await _get(uri);
    if (resp.statusCode == 404) return null;
    return _decodeJson(resp.body) as Map<String, dynamic>;
  }

  /// Submit an answer for a question.
  Future<void> submitAnswer({
    required String matchId,
    required String questionId,
    required String answerId,
  }) async {
    final uri = _config.httpBase.resolve(MultiplayerConstants.answersPath);
    final payload = {
      'matchId': matchId,
      'questionId': questionId,
      'answerId': answerId,
    };
    await _post(uri, payload);
  }

  // ------------------------ Low-level helpers ------------------------

  Future<http.Response> _get(Uri uri) async {
    _log.d('GET $uri');
    final headers = await _headers();
    final resp = await http.get(uri, headers: headers).timeout(_config.httpTimeout);
    _validate(resp, 'GET', uri);
    return resp;
  }

  Future<http.Response> _post(Uri uri, Map<String, dynamic> jsonBody) async {
    _log.d('POST $uri body=$jsonBody');
    final headers = await _headers();
    final resp = await http
        .post(uri, headers: headers, body: json.encode(jsonBody))
        .timeout(_config.httpTimeout);
    _validate(resp, 'POST', uri, sentBody: jsonBody);
    return resp;
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      MultiplayerConstants.hdrContentType: MultiplayerConstants.contentTypeJson,
    };
    final token = await _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers[MultiplayerConstants.hdrAuthorization] = 'Bearer $token';
    }
    return headers;
  }

  void _validate(http.Response resp, String verb, Uri uri, {Map<String, dynamic>? sentBody}) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;

    _log.w('$verb $uri failed (${resp.statusCode}): ${resp.body}');
    if (resp.statusCode == 400) {
      throw BadRequest('Bad request: ${resp.body}');
    }
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw NotAuthorized('Auth failed (${resp.statusCode})');
    }
    if (resp.statusCode == 409) {
      throw RoomFull('Room full or conflict: ${resp.body}');
    }
    throw HttpFailure(status: resp.statusCode, message: 'HTTP ${resp.statusCode}', body: resp.body);
  }

  dynamic _decodeJson(String body) {
    try {
      return json.decode(body);
    } catch (e) {
      _log.e('JSON decode failed', e);
      throw ProtocolFailure('Invalid JSON response');
    }
  }
}
