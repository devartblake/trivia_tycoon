import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../bootstrap/app_init.dart';
import '../../networking/ws_protocol.dart';
import '../../../game/analytics/models/spin_live_summary.dart';

class SpinAnalyticsWebSocketAdapter {
  StreamSubscription<WsEnvelope>? _messageSubscription;
  final _summaryController = StreamController<SpinLiveSummary>.broadcast();

  Stream<SpinLiveSummary> get summaryStream => _summaryController.stream;

  void initialize({
    required String userName,
    required String userId,
  }) {
    final wsClient = AppInit.wsClient;
    if (wsClient == null || !AppInit.isWebSocketConnected) {
      debugPrint('[SpinWS] WebSocket not connected - live spin summary disabled');
      return;
    }

    _messageSubscription = wsClient.messageStream.listen(
      (envelope) => _handleMessage(
        envelope,
        fallbackUserName: userName,
        fallbackUserId: userId,
      ),
    );

    wsClient.send(WsEnvelope(
      op: 'spin.analytics.subscribe',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {
        'user_id': userId,
      },
    ));

    wsClient.send(WsEnvelope(
      op: 'spin.analytics.get_summary',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {
        'user_id': userId,
      },
    ));

    debugPrint('[SpinWS] Subscribed to live spin analytics for user $userId');
  }

  void _handleMessage(
    WsEnvelope envelope, {
    required String fallbackUserName,
    required String fallbackUserId,
  }) {
    if (envelope.data == null) return;

    final data = envelope.data!;
    switch (envelope.op) {
      case 'spin.analytics.summary':
      case 'spin.analytics.snapshot':
      case 'spin.analytics.updated':
      case 'spin.summary':
        _summaryController.add(
          SpinLiveSummary.fromMap(
            data,
            fallbackUserName: fallbackUserName,
            fallbackUserId: fallbackUserId,
            source: 'websocket:${envelope.op}',
          ),
        );
        break;
      default:
        break;
    }
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _summaryController.close();
  }
}
