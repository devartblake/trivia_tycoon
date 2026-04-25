import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'ws_client.dart';
import 'ws_protocol.dart';

/// Unified client that combines REST (ApiService/Dio) with WebSocket (WsClient).
///
/// Use [tycoonApiClientEnhancedProvider] to obtain an instance.
///
/// Lifecycle:
/// - Call [connectWs()] when the app enters the foreground or after login.
/// - Call [disconnectWs()] on logout or when the app goes to background.
/// - REST calls go through [api] (existing ApiService — caching, auth, retries).
/// - Real-time messages go through [ws] (WsClient — reliability layer, ACKs).
class TycoonApiClientEnhanced {
  final ApiService api;
  final WsClient ws;

  TycoonApiClientEnhanced({required this.api, required this.ws});

  // -------------------------------------------------------------------------
  // WebSocket lifecycle helpers
  // -------------------------------------------------------------------------

  Future<void> connectWs() => ws.connect();

  Future<void> disconnectWs() => ws.disconnect();

  bool get isConnected => ws.isConnected;

  // -------------------------------------------------------------------------
  // Typed message helpers
  // -------------------------------------------------------------------------

  /// Send a message that does not need an ACK.
  void send(WsEnvelope message) => ws.send(message);

  /// Send a message that requires an ACK; retried up to [WsReliability._maxRetries] times.
  void sendReliable(WsEnvelope message) => ws.sendReliable(message);

  /// Broadcast stream of incoming envelopes.
  Stream<WsEnvelope> get messages => ws.messageStream;

  /// Broadcast stream of [WsState] changes.
  Stream<WsState> get connectionState => ws.stateStream;
}
