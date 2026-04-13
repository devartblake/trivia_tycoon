import 'dart:async';
import '../../bootstrap/app_init.dart';
import '../../networking/ws_client.dart';
import '../../networking/ws_protocol.dart';
import '../../../game/analytics/models/spin_live_summary.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class SpinAnalyticsWebSocketAdapter {
  StreamSubscription<WsEnvelope>? _messageSubscription;
  final _summaryController = StreamController<SpinLiveSummary>.broadcast();
  String? _userName;
  String? _userId;
  bool _hasSubscribed = false;

  Stream<SpinLiveSummary> get summaryStream => _summaryController.stream;

  void initialize({
    required String userName,
    required String userId,
  }) {
    _userName = userName;
    _userId = userId;

    if (_hasSubscribed) {
      requestLatestSummary();
      return;
    }

    final wsClient = AppInit.wsClient;
    if (wsClient == null || !AppInit.isWebSocketConnected) {
      LogManager.debug('[SpinWS] WebSocket not connected - live spin summary disabled');
      return;
    }

    _hasSubscribed = true;

    _messageSubscription = wsClient.messageStream.listen(
      (envelope) => _handleMessage(
        envelope,
        fallbackUserName: userName,
        fallbackUserId: userId,
      ),
    );

    _subscribe(wsClient: wsClient, userId: userId);
    requestLatestSummary();

    LogManager.debug('[SpinWS] Subscribed to live spin analytics for user $userId');
  }

  void requestLatestSummary() {
    final wsClient = AppInit.wsClient;
    final userId = _userId;
    if (wsClient == null || !AppInit.isWebSocketConnected || userId == null) {
      return;
    }

    wsClient.send(WsEnvelope(
      op: 'spin.analytics.get_summary',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {'user_id': userId},
    ));
  }

  void _subscribe({required WsClient wsClient, required String userId}) {
    wsClient.send(WsEnvelope(
      op: 'spin.analytics.subscribe',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {'user_id': userId},
    ));
  }

  void _handleMessage(
    WsEnvelope envelope, {
    required String fallbackUserName,
    required String fallbackUserId,
  }) {
    switch (envelope.op) {
      case 'hello':
        final wsClient = AppInit.wsClient;
        final userId = _userId;
        if (wsClient != null && userId != null) {
          _subscribe(wsClient: wsClient, userId: userId);
          requestLatestSummary();
        }
        break;
      case 'spin.analytics.summary':
      case 'spin.analytics.snapshot':
      case 'spin.analytics.updated':
      case 'spin.summary':
        final data = envelope.data;
        if (data == null) return;
        final payload = (data['summary'] is Map<String, dynamic>)
            ? data['summary'] as Map<String, dynamic>
            : data;

        _summaryController.add(
          SpinLiveSummary.fromMap(
            payload,
            fallbackUserName: _userName ?? fallbackUserName,
            fallbackUserId: _userId ?? fallbackUserId,
            source: 'websocket:${envelope.op}',
          ),
        );
        break;
      default:
        break;
    }
  }

  Future<void> dispose() async {
    final wsClient = AppInit.wsClient;
    final userId = _userId;
    if (wsClient != null && AppInit.isWebSocketConnected && userId != null) {
      wsClient.send(WsEnvelope(
        op: 'spin.analytics.unsubscribe',
        ts: DateTime.now().millisecondsSinceEpoch,
        data: {'user_id': userId},
      ));
    }

    _hasSubscribed = false;
    await _messageSubscription?.cancel();
    await _summaryController.close();
  }
}
