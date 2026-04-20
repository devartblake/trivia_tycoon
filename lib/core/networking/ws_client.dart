import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'ws_protocol.dart';
import 'ws_reliability.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// WebSocket client with automatic reconnection and message reliability
///
/// Features:
/// - Automatic reconnection with exponential backoff
/// - Message acknowledgments
/// - Sequence number tracking
/// - Connection state management
/// - Heartbeat/ping-pong
class WsClient {
  final String url;
  final WsReliability _reliability;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  // Connection state
  WsState _state = WsState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Callbacks
  final void Function(WsEnvelope message)? onMessage;
  final void Function(WsState state)? onStateChange;
  final void Function(String error)? onError;

  // Stream controllers
  final _messageController = StreamController<WsEnvelope>.broadcast();
  final _stateController = StreamController<WsState>.broadcast();

  WsClient({
    required this.url,
    this.onMessage,
    this.onStateChange,
    this.onError,
  }) : _reliability = WsReliability();

  /// Current connection state
  WsState get state => _state;

  /// Stream of incoming messages
  Stream<WsEnvelope> get messageStream => _messageController.stream;

  /// Stream of connection state changes
  Stream<WsState> get stateStream => _stateController.stream;

  /// Whether client is connected
  bool get isConnected => _state == WsState.connected;

  // ========================================
  // Connection Management
  // ========================================

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_state == WsState.connected || _state == WsState.connecting) {
      LogManager.debug('[WsClient] Already connected or connecting');
      return;
    }

    _setState(WsState.connecting);
    _reconnectAttempts = 0;
    await _doConnect();
  }

  /// Internal connection logic
  Future<void> _doConnect() async {
    try {
      LogManager.debug('[WsClient] Connecting to $url...');

      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Wait for connection to be established
      await _channel!.ready;

      LogManager.debug('[WsClient] ✅ Connected');
      _setState(WsState.connected);
      _reconnectAttempts = 0;

      // Start listening to messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      // Start heartbeat
      _startHeartbeat();

      // Send hello message
      send(WsEnvelope(
        op: 'hello',
        ts: DateTime.now().millisecondsSinceEpoch,
        data: {'clientVersion': '1.0.0'},
      ));
    } catch (e) {
      LogManager.debug('[WsClient] Connection error: $e');
      _handleError(e);
    }
  }

  /// Disconnect from server
  Future<void> disconnect() async {
    LogManager.debug('[WsClient] Disconnecting...');

    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();

    await _subscription?.cancel();
    await _channel?.sink.close();

    _channel = null;
    _subscription = null;

    _setState(WsState.disconnected);
    _reliability.reset();
  }

  /// Reconnect to server
  Future<void> reconnect() async {
    await disconnect();
    await connect();
  }

  // ========================================
  // Message Sending
  // ========================================

  /// Send a message to the server
  void send(WsEnvelope message, {bool requireAck = false}) {
    if (!isConnected) {
      LogManager.debug('[WsClient] Cannot send - not connected');
      onError?.call('Not connected');
      return;
    }

    try {
      if (requireAck) {
        _reliability.sendWithAck(message, (msg) => _sendRaw(msg));
      } else {
        _sendRaw(message);
      }
    } catch (e) {
      LogManager.debug('[WsClient] Send error: $e');
      onError?.call('Send failed: $e');
    }
  }

  /// Send raw message without reliability
  void _sendRaw(WsEnvelope message) {
    final json = message.toJson();
    final text = jsonEncode(json);
    _channel?.sink.add(text);
    LogManager.debug('[WsClient] → Sent: ${message.op}');
  }

  // ========================================
  // Message Handling
  // ========================================

  /// Handle incoming message
  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final envelope = WsEnvelope.fromJson(json);

      LogManager.debug('[WsClient] ← Received: ${envelope.op}');

      // Handle system messages
      if (envelope.op == 'pong') {
        // Heartbeat response
        return;
      }

      if (envelope.op == 'ack') {
        // Acknowledgment
        final msgId = envelope.data?['msgId'] as String?;
        if (msgId != null) {
          _reliability.handleAck(msgId);
        }
        return;
      }

      // Send ACK if message has sequence number
      if (envelope.seq != null) {
        _sendAck(envelope.seq!);
      }

      // Pass to reliability layer
      _reliability.handleMessage(envelope);

      // Notify listeners
      _messageController.add(envelope);
      onMessage?.call(envelope);
    } catch (e) {
      LogManager.debug('[WsClient] Message parse error: $e');
      onError?.call('Invalid message: $e');
    }
  }

  /// Send acknowledgment for a message
  void _sendAck(int seq) {
    _sendRaw(WsEnvelope(
      op: 'ack',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {'seq': seq},
    ));
  }

  // ========================================
  // Connection Events
  // ========================================

  /// Handle connection error
  void _handleError(dynamic error) {
    LogManager.debug('[WsClient] Error: $error');
    onError?.call(error.toString());

    if (_state == WsState.connected) {
      _scheduleReconnect();
    }
  }

  /// Handle disconnection
  void _handleDisconnect() {
    LogManager.debug('[WsClient] Disconnected');

    if (_state != WsState.disconnected) {
      _setState(WsState.reconnecting);
      _scheduleReconnect();
    }
  }

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      LogManager.debug('[WsClient] Max reconnect attempts reached');
      _setState(WsState.disconnected);
      onError
          ?.call('Failed to reconnect after $_maxReconnectAttempts attempts');
      return;
    }

    // Exponential backoff
    final delay = _getReconnectDelay();
    LogManager.debug(
        '[WsClient] Reconnecting in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _doConnect();
    });
  }

  /// Calculate reconnect delay with exponential backoff
  Duration _getReconnectDelay() {
    final delayMs = _initialReconnectDelay.inMilliseconds *
        (1 << _reconnectAttempts); // 2^attempts
    final clampedMs = delayMs.clamp(
      _initialReconnectDelay.inMilliseconds,
      _maxReconnectDelay.inMilliseconds,
    );
    return Duration(milliseconds: clampedMs);
  }

  // ========================================
  // Heartbeat
  // ========================================

  /// Start sending periodic heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (isConnected) {
        _sendRaw(WsEnvelope(
          op: 'ping',
          ts: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    });
  }

  // ========================================
  // State Management
  // ========================================

  /// Update connection state
  void _setState(WsState newState) {
    if (_state == newState) return;

    final oldState = _state;
    _state = newState;

    LogManager.debug('[WsClient] State: $oldState → $newState');

    _stateController.add(newState);
    onStateChange?.call(newState);
  }

  // ========================================
  // Cleanup
  // ========================================

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
    _reliability.dispose();
  }
}

/// WebSocket connection state
enum WsState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}
