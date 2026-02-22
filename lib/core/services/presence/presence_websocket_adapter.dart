import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/networking/ws_client.dart';
import '../../../core/networking/ws_protocol.dart';
import '../../../core/bootstrap/app_init.dart';
import '../../../game/models/user_presence_models.dart';
import 'rich_presence_service.dart';

/// Adapts WebSocket messages to RichPresenceService
class PresenceWebSocketAdapter {
  final RichPresenceService _presenceService;
  StreamSubscription<WsEnvelope>? _messageSubscription;

  bool _isSubscribed = false;
  final Set<String> _subscribedUserIds = {};

  PresenceWebSocketAdapter(this._presenceService);

  /// Initialize and start listening to WebSocket messages
  void initialize() {
    final wsClient = AppInit.wsClient;
    if (wsClient == null) {
      debugPrint('[PresenceWS] WebSocket not available');
      return;
    }

    // Listen to all WebSocket messages
    _messageSubscription = wsClient.messageStream.listen(_handleMessage);

    debugPrint('[PresenceWS] Initialized');
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(WsEnvelope envelope) {
    switch (envelope.op) {
      case 'hello':
        _handleHello(envelope.data);
        break;
      case 'presence.update':
        _handlePresenceUpdate(envelope.data);
        break;
      case 'presence.bulk':
        _handleBulkPresence(envelope.data);
        break;
      default:
      // Ignore other message types
        break;
    }
  }

  /// Handle server hello - subscribe to initial presence
  void _handleHello(Map<String, dynamic>? data) {
    debugPrint('[PresenceWS] Server connected');

    // Send our current presence to server
    updateMyPresence(_presenceService.currentUserPresence);
  }

  /// Handle single presence update
  void _handlePresenceUpdate(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      final userId = data['userId'] as String;
      final status = _parsePresenceStatus(data['status'] as String?);
      final activity = data['activity'] as String?;
      final lastSeen = data['lastSeen'] != null
          ? DateTime.parse(data['lastSeen'] as String)
          : DateTime.now();

      // Parse game activity if present
      GameActivity? gameActivity;
      if (data['gameActivity'] != null) {
        final gameData = data['gameActivity'] as Map<String, dynamic>;
        gameActivity = GameActivity(
          gameType: gameData['gameType'] as String,
          gameMode: gameData['gameMode'] as String?,
          currentLevel: gameData['currentLevel'] as String?,
          score: gameData['score'] as int?,
          timeRemaining: gameData['timeRemaining'] as int?,
          gameState: _parseGameState(gameData['gameState'] as String?),
          startTime: gameData['startTime'] != null
              ? DateTime.parse(gameData['startTime'] as String)
              : DateTime.now(),
          metadata: gameData['metadata'] as Map<String, dynamic>? ?? {},
        );
      }

      final presence = UserPresence(
        userId: userId,
        status: status,
        activity: activity,
        gameActivity: gameActivity,
        lastSeen: lastSeen,
        customData: data['customData'] as Map<String, dynamic>? ?? {},
      );

      // Update presence service
      _presenceService.updateFriendPresence(userId, presence);

      debugPrint('[PresenceWS] Updated: $userId → $status');
    } catch (e) {
      debugPrint('[PresenceWS] Error parsing presence: $e');
    }
  }

  /// Handle bulk presence updates (initial load)
  void _handleBulkPresence(Map<String, dynamic>? data) {
    if (data == null || data['presences'] == null) return;

    try {
      final presences = data['presences'] as List<dynamic>;

      for (final presenceData in presences) {
        _handlePresenceUpdate(presenceData as Map<String, dynamic>);
      }

      debugPrint('[PresenceWS] Loaded ${presences.length} presences');
    } catch (e) {
      debugPrint('[PresenceWS] Error parsing bulk presence: $e');
    }
  }

  /// Subscribe to presence updates for specific users
  void subscribeToUsers(List<String> userIds) {
    if (userIds.isEmpty) return;

    final wsClient = AppInit.wsClient;
    if (wsClient == null || !AppInit.isWebSocketConnected) {
      debugPrint('[PresenceWS] Not connected, cannot subscribe');
      return;
    }

    // Only subscribe to new users
    final newUserIds = userIds.where((id) => !_subscribedUserIds.contains(id)).toList();
    if (newUserIds.isEmpty) return;

    wsClient.send(WsEnvelope(
      op: 'presence.subscribe',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {
        'userIds': newUserIds,
      },
    ));

    _subscribedUserIds.addAll(newUserIds);
    debugPrint('[PresenceWS] Subscribed to ${newUserIds.length} users');
  }

  /// Unsubscribe from presence updates
  void unsubscribeFromUsers(List<String> userIds) {
    if (userIds.isEmpty) return;

    final wsClient = AppInit.wsClient;
    if (wsClient == null) return;

    wsClient.send(WsEnvelope(
      op: 'presence.unsubscribe',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {
        'userIds': userIds,
      },
    ));

    _subscribedUserIds.removeAll(userIds);
    debugPrint('[PresenceWS] Unsubscribed from ${userIds.length} users');
  }

  /// Update my own presence
  void updateMyPresence(UserPresence? presence) {
    if (presence == null) return;

    final wsClient = AppInit.wsClient;
    if (wsClient == null || !AppInit.isWebSocketConnected) return;

    final data = <String, dynamic>{
      'status': presence.status.name,
    };

    if (presence.activity != null) {
      data['activity'] = presence.activity;
    }

    if (presence.gameActivity != null) {
      final gameActivity = presence.gameActivity!;
      data['gameActivity'] = {
        'gameType': gameActivity.gameType,
        if (gameActivity.gameMode != null) 'gameMode': gameActivity.gameMode,
        if (gameActivity.currentLevel != null) 'currentLevel': gameActivity.currentLevel,
        if (gameActivity.score != null) 'score': gameActivity.score,
        if (gameActivity.timeRemaining != null) 'timeRemaining': gameActivity.timeRemaining,
        'gameState': gameActivity.gameState.name,
        'startTime': gameActivity.startTime.toIso8601String(),
        if (gameActivity.metadata.isNotEmpty) 'metadata': gameActivity.metadata,
      };
    }

    if (presence.customData.isNotEmpty) {
      data['customData'] = presence.customData;
    }

    wsClient.send(WsEnvelope(
      op: 'presence.update',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: data,
    ));

    debugPrint('[PresenceWS] Sent presence update: ${presence.status}');
  }

  /// Helper: Parse presence status from string
  PresenceStatus _parsePresenceStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'online':
        return PresenceStatus.online;
      case 'away':
        return PresenceStatus.away;
      case 'busy':
        return PresenceStatus.busy;
      case 'ingame':
      case 'in_game':
        return PresenceStatus.inGame;
      case 'offline':
        return PresenceStatus.offline;
      default:
        return PresenceStatus.offline;
    }
  }

  /// Helper: Parse game state from string
  GameState _parseGameState(String? state) {
    switch (state?.toLowerCase()) {
      case 'lobby':
        return GameState.lobby;
      case 'waiting':
        return GameState.waiting;
      case 'playing':
        return GameState.playing;
      case 'paused':
        return GameState.paused;
      case 'finished':
        return GameState.finished;
      default:
        return GameState.playing;
    }
  }

  /// Cleanup
  void dispose() {
    _messageSubscription?.cancel();
    _subscribedUserIds.clear();
    debugPrint('[PresenceWS] Disposed');
  }
}