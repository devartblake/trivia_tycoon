import '../../core/utils/input_validator.dart';

/// Represents a user's current presence and activity status
class UserPresence {
  final String userId;
  final PresenceStatus status;
  final String? activity;
  final GameActivity? gameActivity;
  final DateTime lastSeen;
  final Map<String, dynamic> customData;

  const UserPresence({
    required this.userId,
    required this.status,
    this.activity,
    this.gameActivity,
    required this.lastSeen,
    this.customData = const {},
  });

  /// Create a default presence for a new user
  factory UserPresence.createDefault({String? userId}) {
    return UserPresence(
      userId: userId ?? 'current_user',
      status: PresenceStatus.online,
      lastSeen: DateTime.now(),
    );
  }

  /// Create from JSON (for network/storage)
  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: InputValidator.safeString(json['userId'] ?? ''),
      status: PresenceStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => PresenceStatus.offline,
      ),
      activity: json['activity'] != null
          ? InputValidator.safeString(json['activity'])
          : null,
      gameActivity: json['gameActivity'] != null
          ? GameActivity.fromJson(json['gameActivity'])
          : null,
      lastSeen:
          DateTime.parse(json['lastSeen'] ?? DateTime.now().toIso8601String()),
      customData: Map<String, dynamic>.from(json['customData'] ?? {}),
    );
  }

  /// Convert to JSON (for network/storage)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': status.toString(),
      'activity': activity,
      'gameActivity': gameActivity?.toJson(),
      'lastSeen': lastSeen.toIso8601String(),
      'customData': customData,
    };
  }

  /// Create a copy with updated fields
  UserPresence copyWith({
    String? userId,
    PresenceStatus? status,
    String? activity,
    GameActivity? gameActivity,
    DateTime? lastSeen,
    Map<String, dynamic>? customData,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      activity: activity ?? this.activity,
      gameActivity: gameActivity ?? this.gameActivity,
      lastSeen: lastSeen ?? this.lastSeen,
      customData: customData ?? this.customData,
    );
  }

  /// Check if user is currently active (online or in-game)
  bool get isActive =>
      status == PresenceStatus.online || status == PresenceStatus.inGame;

  /// Check if user is available for interaction
  bool get isAvailable =>
      status != PresenceStatus.busy && status != PresenceStatus.offline;

  /// Get display text for the presence
  String get displayText {
    switch (status) {
      case PresenceStatus.online:
        return activity?.isNotEmpty == true ? activity! : 'Online';
      case PresenceStatus.away:
        return 'Away';
      case PresenceStatus.busy:
        return activity?.isNotEmpty == true ? activity! : 'Busy';
      case PresenceStatus.inGame:
        return activity?.isNotEmpty == true ? activity! : 'In Game';
      case PresenceStatus.offline:
        return 'Last seen ${_formatLastSeen()}';
    }
  }

  /// Get color associated with this presence status
  int get statusColor {
    switch (status) {
      case PresenceStatus.online:
        return 0xFF3BA55C; // Green
      case PresenceStatus.away:
        return 0xFFFAA61A; // Yellow
      case PresenceStatus.busy:
        return 0xFFED4245; // Red
      case PresenceStatus.inGame:
        return 0xFF5865F2; // Blue
      case PresenceStatus.offline:
        return 0xFF747F8D; // Gray
    }
  }

  String _formatLastSeen() {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'over a week ago';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPresence &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          status == other.status &&
          activity == other.activity &&
          gameActivity == other.gameActivity;

  @override
  int get hashCode =>
      userId.hashCode ^
      status.hashCode ^
      activity.hashCode ^
      gameActivity.hashCode;

  @override
  String toString() {
    return 'UserPresence{userId: $userId, status: $status, activity: $activity}';
  }
}

/// Represents detailed information about a user's current game activity
class GameActivity {
  final String gameType;
  final String? gameMode;
  final String? currentLevel;
  final int? score;
  final int? timeRemaining;
  final GameState gameState;
  final DateTime startTime;
  final Map<String, dynamic> metadata;

  const GameActivity({
    required this.gameType,
    this.gameMode,
    this.currentLevel,
    this.score,
    this.timeRemaining,
    required this.gameState,
    required this.startTime,
    this.metadata = const {},
  });

  /// Create from JSON
  factory GameActivity.fromJson(Map<String, dynamic> json) {
    return GameActivity(
      gameType: InputValidator.safeString(json['gameType'] ?? ''),
      gameMode: json['gameMode'] != null
          ? InputValidator.safeString(json['gameMode'])
          : null,
      currentLevel: json['currentLevel'] != null
          ? InputValidator.safeString(json['currentLevel'])
          : null,
      score: json['score']?.toInt(),
      timeRemaining: json['timeRemaining']?.toInt(),
      gameState: GameState.values.firstWhere(
        (e) => e.toString() == json['gameState'],
        orElse: () => GameState.playing,
      ),
      startTime:
          DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'gameType': gameType,
      'gameMode': gameMode,
      'currentLevel': currentLevel,
      'score': score,
      'timeRemaining': timeRemaining,
      'gameState': gameState.toString(),
      'startTime': startTime.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  GameActivity copyWith({
    String? gameType,
    String? gameMode,
    String? currentLevel,
    int? score,
    int? timeRemaining,
    GameState? gameState,
    DateTime? startTime,
    Map<String, dynamic>? metadata,
  }) {
    return GameActivity(
      gameType: gameType ?? this.gameType,
      gameMode: gameMode ?? this.gameMode,
      currentLevel: currentLevel ?? this.currentLevel,
      score: score ?? this.score,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      gameState: gameState ?? this.gameState,
      startTime: startTime ?? this.startTime,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get elapsed time since game started
  Duration get elapsedTime => DateTime.now().difference(startTime);

  /// Check if game allows spectators
  bool get allowsSpectators => metadata['allowSpectators'] == true;

  /// Check if user can be invited to join
  bool get canJoin =>
      gameState == GameState.lobby || gameState == GameState.waiting;

  /// Get formatted duration string
  String get formattedDuration {
    final duration = elapsedTime;
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameActivity &&
          runtimeType == other.runtimeType &&
          gameType == other.gameType &&
          gameMode == other.gameMode &&
          currentLevel == other.currentLevel &&
          score == other.score &&
          gameState == other.gameState;

  @override
  int get hashCode =>
      gameType.hashCode ^
      gameMode.hashCode ^
      currentLevel.hashCode ^
      score.hashCode ^
      gameState.hashCode;

  @override
  String toString() {
    return 'GameActivity{gameType: $gameType, gameMode: $gameMode, gameState: $gameState}';
  }
}

/// Enum representing different presence statuses
enum PresenceStatus {
  online,
  away,
  busy,
  inGame,
  offline;

  /// Get user-friendly display name
  String get displayName {
    switch (this) {
      case PresenceStatus.online:
        return 'Online';
      case PresenceStatus.away:
        return 'Away';
      case PresenceStatus.busy:
        return 'Busy';
      case PresenceStatus.inGame:
        return 'In Game';
      case PresenceStatus.offline:
        return 'Offline';
    }
  }

  /// Get icon data for this status
  int get iconCode {
    switch (this) {
      case PresenceStatus.online:
        return 0xe540; // Icons.circle
      case PresenceStatus.away:
        return 0xe546; // Icons.schedule
      case PresenceStatus.busy:
        return 0xe14c; // Icons.do_not_disturb
      case PresenceStatus.inGame:
        return 0xe30b; // Icons.sports_esports
      case PresenceStatus.offline:
        return 0xe5cd; // Icons.radio_button_unchecked
    }
  }
}

/// Enum representing different game states
enum GameState {
  lobby,
  waiting,
  playing,
  paused,
  finished;

  /// Get user-friendly display name
  String get displayName {
    switch (this) {
      case GameState.lobby:
        return 'In Lobby';
      case GameState.waiting:
        return 'Waiting';
      case GameState.paused:
        return 'Paused';
      case GameState.playing:
        return 'Playing';
      case GameState.finished:
        return 'Finished';
    }
  }

  /// Check if state allows joining
  bool get allowsJoining =>
      this == GameState.lobby || this == GameState.waiting;

  /// Check if state allows spectating
  bool get allowsSpectating => this == GameState.playing;
}
