import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:trivia_tycoon/game/multiplayer/data/dto/ws_envelope_dto.dart';
import 'package:trivia_tycoon/game/multiplayer/data/mappers/event_mapper.dart';
import 'package:trivia_tycoon/game/multiplayer/data/sources/ws_protocol.dart';
import 'package:trivia_tycoon/game/multiplayer/data/sources/ws_socket.dart';
import 'package:trivia_tycoon/game/multiplayer/data/sources/ws_reliability.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_event.dart';

class WsClient {
  final EventMapper _mapper;
  final ReconnectPolicy _policy;
  final bool autoReconnect;

  WebSocketChannel? _socket;
  StreamSubscription? _socketSub;

  final _eventCtrl = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventCtrl.stream;

  final _rawCtrl = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get debugRaw => _rawCtrl.stream;

  int _lastRttMs = 0;
  int get lastRttMs => _lastRttMs;

  bool _connected = false;
  Timer? _heartbeat;
  int? _lastPingSentAt;

  // For reconnects
  Uri? _lastUri;
  String? _lastToken;
  int _attempt = 0; // increments on failures

  WsClient({
    EventMapper? mapper,
    ReconnectPolicy? policy,
    this.autoReconnect = true,
  })  : _mapper = mapper ?? const EventMapper(),
        _policy = policy ?? ReconnectPolicy.initial();

  Future<bool> connect({required Uri uri, String? token}) async {
    _lastUri = uri;
    _lastToken = token;
    return _openSocket(uri, token);
  }

  Future<void> disconnect() async {
    autoReconnect ? _stopAutoReconnect() : null;
    await _closeSocket();
  }

  Future<void> send(Map<String, dynamic> json) async {
    final s = _socket;
    if (s == null) return;
    try {
      s.sink.add(jsonEncode(json));
    } catch (e) {
      _emit(ProtocolError('send_failed: $e'));
    }
  }

  // ------------ internals ------------

  Future<bool> _openSocket(Uri uri, String? token) async {
    try {
      final headers = <String, dynamic>{};
      Uri finalUri = uri;

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        if (uri.scheme.startsWith('ws') && (uri.queryParameters['token'] == null)) {
          final qp = Map<String, String>.from(uri.queryParameters)..['token'] = token;
          finalUri = uri.replace(queryParameters: qp);
        }
      }

      _socket = socketConnect(finalUri, headers: headers);
      _socketSub = _socket!.stream.listen(
        _onFrame,
        onError: (e, st) {
          _emit(ProtocolError('socket_error: $e'));
          _handleSocketClosed();
        },
        onDone: () {
          _emit(ServerNotice(code: 'closed', message: 'Connection closed'));
          _handleSocketClosed();
        },
        cancelOnError: true,
      );

      _connected = true;
      _attempt = 0; // reset attempts on success
      _startHeartbeat();
      return true;
    } catch (e) {
      _emit(ProtocolError('connect_failed: $e'));
      _handleSocketClosed();
      return false;
    }
  }

  Future<void> _closeSocket() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    _lastPingSentAt = null;

    await _socketSub?.cancel();
    _socketSub = null;
    await _socket?.sink.close();
    _socket = null;

    _connected = false;
  }

  void _onFrame(dynamic frame) {
    try {
      final map = switch (frame) {
        final String s => jsonDecode(s) as Map<String, dynamic>,
        final List<int> bytes => jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
        final Map<String, dynamic> m => m,
        _ => throw StateError('Unsupported WS frame type: ${frame.runtimeType}'),
      };

      _rawCtrl.add(map);

      final op = map['op']?.toString() ?? '';
      if (op == WsProtocol.opPong && _lastPingSentAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        _lastRttMs = now - _lastPingSentAt!;
        _lastPingSentAt = null;
      }

      final env = WsEnvelopeDto.fromJson(map);
      final evt = _mapper.fromEnvelope(env);
      if (evt != null) _emit(evt);
    } catch (e) {
      _emit(ProtocolError('frame_parse_failed: $e'));
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) => _sendPing());
    _sendPing();
  }

  void _sendPing() {
    if (_socket == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastPingSentAt = now;
    send({'op': WsProtocol.opPing, 'ts': now});
  }

  void _emit(GameEvent event) {
    if (!_eventCtrl.isClosed) _eventCtrl.add(event);
  }

  // ------------ reconnect handling ------------

  void _handleSocketClosed() {
    _connected = false;
    _heartbeat?.cancel();
    _heartbeat = null;
    _lastPingSentAt = null;

    if (!autoReconnect) return;
    if (_lastUri == null) return;

    _attempt += 1;
    if (!_policy.canAttempt(_attempt)) {
      _emit(ServerNotice(code: 'reconnect_stopped', message: 'Max attempts reached'));
      return;
    }

    final delay = _policy.nextDelay(_attempt);
    _emit(ServerNotice(
      code: 'reconnect_scheduled',
      message: 'Reconnecting in ${delay.inMilliseconds} ms (attempt $_attempt)',
    ));

    Timer(delay, () {
      if (_connected) return; // already reconnected elsewhere
      _openSocket(_lastUri!, _lastToken);
    });
  }

  void _stopAutoReconnect() {
    _attempt = 0;
  }

  void dispose() {
    _heartbeat?.cancel();
    _eventCtrl.close();
    _rawCtrl.close();
    _socketSub?.cancel();
    _socket?.sink.close();
  }
}
