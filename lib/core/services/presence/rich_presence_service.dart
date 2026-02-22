import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/services/presence/presence_websocket_adapter.dart';
import '../../../game/models/user_presence_models.dart';
import '../../utils/input_validator.dart';

class RichPresenceService extends ChangeNotifier {
  static final RichPresenceService _instance = RichPresenceService._internal();
  factory RichPresenceService() => _instance;
  RichPresenceService._internal();

  final Map<String, UserPresence> _userPresences = {};
  UserPresence? _currentUserPresence;
  Timer? _presenceUpdateTimer;
  Timer? _heartbeatTimer;

  // ADD: Stream controllers for real-time updates
  final Map<String, StreamController<UserPresence?>> _presenceStreams = {};

  //WebSocket adapter
  PresenceWebSocketAdapter? _wsAdapter;
  bool _useWebSocket = false;

  // Current user's presence
  UserPresence? get currentUserPresence => _currentUserPresence;

  // Get all tracked presences
  Map<String, UserPresence> get allPresences => Map.unmodifiable(_userPresences);

  // Get specific user presence
  UserPresence? getUserPresence(String userId) => _userPresences[userId];

  /// Initialize the presence service
  void initialize({bool useWebSocket = true}) {
    _useWebSocket = useWebSocket;

    if (_useWebSocket) {
      // Use WebSocket for real-time updates
      _wsAdapter = PresenceWebSocketAdapter(this);
      _wsAdapter!.initialize();
      debugPrint('[Presence] Using WebSocket mode');
    } else {
      // Legacy mode - polling with timers
      _startHeartbeat();
      debugPrint('[Presence] Using legacy polling mode');
    }

    _setCurrentUserPresence(UserPresence.createDefault());
  }

  /// Update current user's presence
  Future<void> updateCurrentUserPresence({
    PresenceStatus? status,
    String? activity,
    GameActivity? gameActivity,
    Map<String, dynamic>? customData,
  }) async {
    final currentPresence = _currentUserPresence ?? UserPresence.createDefault();

    final updatedPresence = UserPresence(
      userId: currentPresence.userId,
      status: status ?? currentPresence.status,
      activity: activity != null ? InputValidator.safeString(activity) : currentPresence.activity,
      gameActivity: gameActivity ?? currentPresence.gameActivity,
      lastSeen: DateTime.now(),
      customData: customData ?? currentPresence.customData,
    );

    await _setCurrentUserPresence(updatedPresence);

    // Use WebSocket instead of polling
    if (_useWebSocket && _wsAdapter != null) {
      _wsAdapter!.updateMyPresence(updatedPresence);
    } else {
      await _broadcastPresenceUpdate(updatedPresence);
    }
  }

  /// Set game activity for current user
  Future<void> setGameActivity({
    required String gameType,
    String? gameMode,
    String? currentLevel,
    int? score,
    int? timeRemaining,
    GameState? gameState,
    Map<String, dynamic>? metadata,
  }) async {
    final gameActivity = GameActivity(
      gameType: InputValidator.safeString(gameType),
      gameMode: gameMode != null ? InputValidator.safeString(gameMode) : null,
      currentLevel: currentLevel != null ? InputValidator.safeString(currentLevel) : null,
      score: score,
      timeRemaining: timeRemaining,
      gameState: gameState ?? GameState.playing,
      startTime: DateTime.now(),
      metadata: metadata ?? {},
    );

    await updateCurrentUserPresence(
      status: PresenceStatus.inGame,
      activity: _formatGameActivity(gameActivity),
      gameActivity: gameActivity,
    );
  }

  /// Clear game activity (user finished playing)
  Future<void> clearGameActivity() async {
    await updateCurrentUserPresence(
      status: PresenceStatus.online,
      activity: null,
      gameActivity: null,
    );
  }

  /// Subscribe to presence updates for specific users (friends, group members)
  void subscribeToUsers(List<String> userIds) {
    if (_useWebSocket && _wsAdapter != null) {
      _wsAdapter!.subscribeToUsers(userIds);
    }
  }

  /// Unsubscribe from presence updates
  void unsubscribeFromUsers(List<String> userIds) {
    if (_useWebSocket && _wsAdapter != null) {
      _wsAdapter!.unsubscribeFromUsers(userIds);
    }
  }

  /// Update friend's presence (received from server/network)
  void updateFriendPresence(String userId, UserPresence presence) {
    final safeUserId = InputValidator.safeString(userId);
    if (safeUserId.isEmpty) return;

    _userPresences[safeUserId] = presence;

    // ADD: Broadcast to stream listeners
    _broadcastPresenceToStream(safeUserId, presence);

    notifyListeners();
  }

  /// Remove user from presence tracking
  void removeUserPresence(String userId) {
    final safeUserId = InputValidator.safeString(userId);
    _userPresences.remove(safeUserId);

    // ADD: Broadcast null to stream (user offline)
    _broadcastPresenceToStream(safeUserId, null);

    notifyListeners();
  }

  /// Get formatted presence string for display
  String getFormattedPresence(String userId) {
    final presence = getUserPresence(userId);
    if (presence == null) return 'Offline';

    switch (presence.status) {
      case PresenceStatus.online:
        return presence.activity?.isNotEmpty == true ? presence.activity! : 'Online';
      case PresenceStatus.away:
        return 'Away';
      case PresenceStatus.busy:
        return 'Busy';
      case PresenceStatus.inGame:
        if (presence.gameActivity != null) {
          return _formatGameActivity(presence.gameActivity!);
        }
        return 'In Game';
      case PresenceStatus.offline:
        return 'Offline';
    }
  }

  /// Check if user can be invited to join a game
  bool canUserJoinGame(String userId) {
    final presence = getUserPresence(userId);
    if (presence?.gameActivity == null) return false;

    return presence!.gameActivity!.gameState == GameState.lobby ||
        presence.gameActivity!.gameState == GameState.waiting;
  }

  /// Get users available for spectating
  List<String> getSpectateableUsers() {
    return _userPresences.entries
        .where((entry) =>
    entry.value.gameActivity?.gameState == GameState.playing &&
        entry.value.gameActivity?.metadata['allowSpectators'] == true)
        .map((entry) => entry.key)
        .toList();
  }

  // ADD: Stream method for watching user presence
  /// Watch a specific user's presence in real-time
  Stream<UserPresence?> watchUserPresence(String userId) {
    final safeUserId = InputValidator.safeString(userId);

    // Create stream controller if it doesn't exist
    _presenceStreams[safeUserId] ??= StreamController<UserPresence?>.broadcast();

    // Send initial value
    Future.delayed(Duration.zero, () {
      final presence = _userPresences[safeUserId];
      _broadcastPresenceToStream(safeUserId, presence);
    });

    return _presenceStreams[safeUserId]!.stream;
  }

  // ADD: Helper method to broadcast presence updates to streams
  void _broadcastPresenceToStream(String userId, UserPresence? presence) {
    final controller = _presenceStreams[userId];
    if (controller != null && !controller.isClosed) {
      controller.add(presence);
    }
  }

  /// Dispose and cleanup
  @override
  void dispose() {
    _presenceUpdateTimer?.cancel();
    _heartbeatTimer?.cancel();
    _wsAdapter?.dispose();

    // ADD: Close all stream controllers
    for (final controller in _presenceStreams.values) {
      controller.close();
    }
    _presenceStreams.clear();

    super.dispose();
  }

  // Private methods

  Future<void> _setCurrentUserPresence(UserPresence presence) async {
    _currentUserPresence = presence;
    _userPresences[presence.userId] = presence;

    // ADD: Broadcast to stream
    _broadcastPresenceToStream(presence.userId, presence);

    notifyListeners();
  }

  Future<void> _broadcastPresenceUpdate(UserPresence presence) async {
    // TODO: Implement network broadcast to friends
    // This would typically send the presence update to a server
    // or directly to connected friends via WebSocket/Firebase
    debugPrint('Broadcasting presence update: ${presence.activity}');
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_currentUserPresence != null) {
        _broadcastPresenceUpdate(_currentUserPresence!);
      }
    });
  }

  String _formatGameActivity(GameActivity activity) {
    final buffer = StringBuffer();

    switch (activity.gameState) {
      case GameState.lobby:
        buffer.write('In ${activity.gameType} lobby');
        if (activity.gameMode != null) {
          buffer.write(' (${activity.gameMode})');
        }
        break;
      case GameState.playing:
        buffer.write('Playing ${activity.gameType}');
        if (activity.currentLevel != null) {
          buffer.write(' - ${activity.currentLevel}');
        }
        if (activity.score != null) {
          buffer.write(' (Score: ${activity.score})');
        }
        break;
      case GameState.paused:
        buffer.write('Paused ${activity.gameType}');
      case GameState.waiting:
        buffer.write('Waiting for players');
        if (activity.gameMode != null) {
          buffer.write(' - ${activity.gameMode}');
        }
        break;
      case GameState.finished:
        buffer.write('Finished ${activity.gameType}');
        if (activity.score != null) {
          buffer.write(' (Score: ${activity.score})');
        }
        break;
    }

    return buffer.toString();
  }
}

// Extension methods for easy access
extension PresenceServiceExtension on RichPresenceService {
  /// Quick method to set quiz game activity
  Future<void> setQuizActivity({
    required String category,
    String? difficulty,
    int? questionNumber,
    int? totalQuestions,
    int? currentScore,
    bool allowSpectators = false,
  }) async {
    await setGameActivity(
      gameType: 'Quiz',
      gameMode: category,
      currentLevel: difficulty != null && questionNumber != null && totalQuestions != null
          ? '$difficulty - Q$questionNumber/$totalQuestions'
          : difficulty,
      score: currentScore,
      metadata: {
        'category': category,
        'difficulty': difficulty,
        'questionNumber': questionNumber,
        'totalQuestions': totalQuestions,
        'allowSpectators': allowSpectators,
      },
    );
  }

  /// Set multiplayer lobby activity
  Future<void> setMultiplayerLobbyActivity({
    required String gameMode,
    int? playerCount,
    int? maxPlayers,
  }) async {
    await setGameActivity(
      gameType: 'Multiplayer Quiz',
      gameMode: gameMode,
      gameState: GameState.lobby,
      metadata: {
        'playerCount': playerCount,
        'maxPlayers': maxPlayers,
        'allowSpectators': true,
      },
    );
  }

  /// Set custom study activity
  Future<void> setStudyActivity(String subject) async {
    await updateCurrentUserPresence(
      status: PresenceStatus.busy,
      activity: 'Studying $subject',
    );
  }
}
