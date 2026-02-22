import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'ws_protocol.dart';

/// Reliability layer for WebSocket messages
///
/// Features:
/// - Message acknowledgments
/// - Automatic retries
/// - Duplicate detection
/// - Message ordering
class WsReliability {
  // Pending messages waiting for ACK
  final _pendingMessages = HashMap<String, _PendingMessage>();

  // Received sequence numbers (for duplicate detection)
  final _receivedSeqs = <int>{};

  // UUID generator for message IDs
  final _uuid = const Uuid();

  // Configuration
  static const Duration _ackTimeout = Duration(seconds: 5);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Send a message that requires acknowledgment
  void sendWithAck(
      WsEnvelope message,
      void Function(WsEnvelope) sendFn,
      ) {
    // Generate unique message ID
    final msgId = _uuid.v4();

    // Add msgId to message data
    final messageWithId = WsEnvelope(
      op: message.op,
      seq: message.seq,
      ts: message.ts,
      data: {
        ...?message.data,
        'msgId': msgId,
      },
    );

    // Send immediately
    sendFn(messageWithId);

    // Track for retries
    _trackMessage(msgId, messageWithId, sendFn);
  }

  /// Track a message for acknowledgment
  void _trackMessage(
      String msgId,
      WsEnvelope message,
      void Function(WsEnvelope) sendFn,
      ) {
    final pending = _PendingMessage(
      msgId: msgId,
      message: message,
      sendFn: sendFn,
      sentAt: DateTime.now(),
      retries: 0,
    );

    _pendingMessages[msgId] = pending;

    // Schedule ACK timeout
    pending.timeoutTimer = Timer(_ackTimeout, () {
      _handleAckTimeout(msgId);
    });
  }

  /// Handle acknowledgment received from server
  void handleAck(String msgId) {
    final pending = _pendingMessages.remove(msgId);

    if (pending != null) {
      pending.timeoutTimer?.cancel();
      debugPrint('[WsReliability] ✅ ACK received for $msgId');
    }
  }

  /// Handle ACK timeout - retry message
  void _handleAckTimeout(String msgId) {
    final pending = _pendingMessages[msgId];

    if (pending == null) return;

    if (pending.retries >= _maxRetries) {
      debugPrint('[WsReliability] ❌ Max retries reached for $msgId');
      _pendingMessages.remove(msgId);
      return;
    }

    debugPrint('[WsReliability] ⏱️ ACK timeout for $msgId, retrying...');

    // Retry after delay
    Timer(_retryDelay, () {
      if (_pendingMessages.containsKey(msgId)) {
        pending.retries++;
        pending.sentAt = DateTime.now();
        pending.sendFn(pending.message);

        // Schedule new timeout
        pending.timeoutTimer = Timer(_ackTimeout, () {
          _handleAckTimeout(msgId);
        });
      }
    });
  }

  /// Handle incoming message - check for duplicates
  bool handleMessage(WsEnvelope message) {
    if (message.seq == null) {
      return true; // No sequence number, accept
    }

    if (_receivedSeqs.contains(message.seq)) {
      debugPrint('[WsReliability] Duplicate message seq=${message.seq}, ignoring');
      return false; // Duplicate
    }

    _receivedSeqs.add(message.seq!);

    // Limit size of received set (keep last 1000)
    if (_receivedSeqs.length > 1000) {
      final toRemove = _receivedSeqs.length - 1000;
      _receivedSeqs.removeAll(_receivedSeqs.take(toRemove));
    }

    return true; // New message
  }

  /// Reset reliability state (on disconnect)
  void reset() {
    // Cancel all pending timeouts
    for (final pending in _pendingMessages.values) {
      pending.timeoutTimer?.cancel();
    }

    _pendingMessages.clear();
    _receivedSeqs.clear();

    debugPrint('[WsReliability] Reset');
  }

  /// Get pending message count
  int get pendingCount => _pendingMessages.length;

  /// Dispose resources
  void dispose() {
    reset();
  }
}

/// Represents a message waiting for acknowledgment
class _PendingMessage {
  final String msgId;
  final WsEnvelope message;
  final void Function(WsEnvelope) sendFn;
  DateTime sentAt;
  int retries;
  Timer? timeoutTimer;

  _PendingMessage({
    required this.msgId,
    required this.message,
    required this.sendFn,
    required this.sentAt,
    required this.retries,
  });
}