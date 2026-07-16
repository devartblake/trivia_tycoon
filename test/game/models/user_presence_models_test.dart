import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/user_presence_models.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _presenceJson({
  String userId = 'uid_1',
  String status = 'PresenceStatus.online',
  String? activity,
  Map<String, dynamic>? gameActivity,
  String? lastSeen,
  Map<String, dynamic>? customData,
}) {
  return {
    'userId': userId,
    'status': status,
    if (activity != null) 'activity': activity,
    if (gameActivity != null) 'gameActivity': gameActivity,
    'lastSeen': lastSeen ?? DateTime.now().toIso8601String(),
    'customData': customData ?? {},
  };
}

Map<String, dynamic> _gameActivityJson({
  String gameType = 'quiz',
  String? gameMode,
  String? currentLevel,
  int? score,
  int? timeRemaining,
  String gameState = 'GameState.playing',
  String? startTime,
  Map<String, dynamic>? metadata,
}) {
  return {
    'gameType': gameType,
    if (gameMode != null) 'gameMode': gameMode,
    if (currentLevel != null) 'currentLevel': currentLevel,
    if (score != null) 'score': score,
    if (timeRemaining != null) 'timeRemaining': timeRemaining,
    'gameState': gameState,
    'startTime': startTime ?? DateTime.now().toIso8601String(),
    'metadata': metadata ?? {},
  };
}

void main() {
  // -------------------------------------------------------------------------
  // PresenceStatus — displayName / iconCode
  // -------------------------------------------------------------------------

  group('PresenceStatus — displayName', () {
    test('online → "Online"',
        () => expect(PresenceStatus.online.displayName, 'Online'));
    test(
        'away → "Away"', () => expect(PresenceStatus.away.displayName, 'Away'));
    test(
        'busy → "Busy"', () => expect(PresenceStatus.busy.displayName, 'Busy'));
    test('inGame → "In Game"',
        () => expect(PresenceStatus.inGame.displayName, 'In Game'));
    test('offline → "Offline"',
        () => expect(PresenceStatus.offline.displayName, 'Offline'));
  });

  group('PresenceStatus — iconCode', () {
    test('each status has a unique icon code', () {
      final codes = PresenceStatus.values.map((s) => s.iconCode).toSet();
      expect(codes.length, PresenceStatus.values.length);
    });

    test('online icon code is 0xe540', () {
      expect(PresenceStatus.online.iconCode, 0xe540);
    });

    test('offline icon code is 0xe5cd', () {
      expect(PresenceStatus.offline.iconCode, 0xe5cd);
    });
  });

  // -------------------------------------------------------------------------
  // GameState — displayName / allowsJoining / allowsSpectating
  // -------------------------------------------------------------------------

  group('GameState — displayName', () {
    test('lobby → "In Lobby"',
        () => expect(GameState.lobby.displayName, 'In Lobby'));
    test('waiting → "Waiting"',
        () => expect(GameState.waiting.displayName, 'Waiting'));
    test('playing → "Playing"',
        () => expect(GameState.playing.displayName, 'Playing'));
    test('paused → "Paused"',
        () => expect(GameState.paused.displayName, 'Paused'));
    test('finished → "Finished"',
        () => expect(GameState.finished.displayName, 'Finished'));
  });

  group('GameState — allowsJoining', () {
    test('true for lobby and waiting', () {
      expect(GameState.lobby.allowsJoining, isTrue);
      expect(GameState.waiting.allowsJoining, isTrue);
    });

    test('false for playing, paused, finished', () {
      expect(GameState.playing.allowsJoining, isFalse);
      expect(GameState.paused.allowsJoining, isFalse);
      expect(GameState.finished.allowsJoining, isFalse);
    });
  });

  group('GameState — allowsSpectating', () {
    test('true only for playing', () {
      expect(GameState.playing.allowsSpectating, isTrue);
    });

    test('false for other states', () {
      for (final s in GameState.values) {
        if (s != GameState.playing) {
          expect(s.allowsSpectating, isFalse,
              reason: '${s.name} should not allow spectating');
        }
      }
    });
  });

  // -------------------------------------------------------------------------
  // UserPresence.createDefault
  // -------------------------------------------------------------------------

  group('UserPresence.createDefault', () {
    test('defaults userId to "current_user" when null', () {
      final p = UserPresence.createDefault();
      expect(p.userId, 'current_user');
    });

    test('uses provided userId', () {
      final p = UserPresence.createDefault(userId: 'uid_me');
      expect(p.userId, 'uid_me');
    });

    test('status is online', () {
      expect(UserPresence.createDefault().status, PresenceStatus.online);
    });

    test('lastSeen is recent', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final p = UserPresence.createDefault();
      expect(p.lastSeen.isAfter(before), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // UserPresence.fromJson
  // -------------------------------------------------------------------------

  group('UserPresence.fromJson', () {
    test('parses userId', () {
      final p = UserPresence.fromJson(_presenceJson(userId: 'uid_42'));
      expect(p.userId, 'uid_42');
    });

    test('parses status using toString() format', () {
      for (final status in PresenceStatus.values) {
        final p =
            UserPresence.fromJson(_presenceJson(status: status.toString()));
        expect(p.status, status, reason: 'Failed for ${status.toString()}');
      }
    });

    test('defaults status to offline for unknown string', () {
      final p = UserPresence.fromJson(_presenceJson(status: 'bogus'));
      expect(p.status, PresenceStatus.offline);
    });

    test('parses optional activity', () {
      final p = UserPresence.fromJson(_presenceJson(activity: 'Playing Quiz'));
      expect(p.activity, 'Playing Quiz');
    });

    test('activity is null when absent', () {
      expect(UserPresence.fromJson(_presenceJson()).activity, isNull);
    });

    test('parses customData map', () {
      final p = UserPresence.fromJson(
          _presenceJson(customData: {'score': 100, 'level': 5}));
      expect(p.customData['score'], 100);
    });

    test('customData defaults to empty when absent', () {
      final json = _presenceJson();
      json.remove('customData');
      final p = UserPresence.fromJson(json);
      expect(p.customData, isEmpty);
    });

    test('parses nested gameActivity', () {
      final p = UserPresence.fromJson(_presenceJson(
        gameActivity: _gameActivityJson(gameType: 'trivia'),
      ));
      expect(p.gameActivity, isNotNull);
      expect(p.gameActivity!.gameType, 'trivia');
    });

    test('gameActivity is null when absent', () {
      expect(UserPresence.fromJson(_presenceJson()).gameActivity, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // UserPresence — computed properties
  // -------------------------------------------------------------------------

  group('UserPresence — isActive', () {
    test('true for online status', () {
      expect(_makePresence(PresenceStatus.online).isActive, isTrue);
    });

    test('true for inGame status', () {
      expect(_makePresence(PresenceStatus.inGame).isActive, isTrue);
    });

    test('false for away, busy, offline', () {
      expect(_makePresence(PresenceStatus.away).isActive, isFalse);
      expect(_makePresence(PresenceStatus.busy).isActive, isFalse);
      expect(_makePresence(PresenceStatus.offline).isActive, isFalse);
    });
  });

  group('UserPresence — isAvailable', () {
    test('true for online, away, inGame', () {
      expect(_makePresence(PresenceStatus.online).isAvailable, isTrue);
      expect(_makePresence(PresenceStatus.away).isAvailable, isTrue);
      expect(_makePresence(PresenceStatus.inGame).isAvailable, isTrue);
    });

    test('false for busy and offline', () {
      expect(_makePresence(PresenceStatus.busy).isAvailable, isFalse);
      expect(_makePresence(PresenceStatus.offline).isAvailable, isFalse);
    });
  });

  group('UserPresence — displayText', () {
    test('online without activity → "Online"', () {
      expect(_makePresence(PresenceStatus.online).displayText, 'Online');
    });

    test('online with activity → activity string', () {
      final p = UserPresence(
        userId: 'u',
        status: PresenceStatus.online,
        activity: 'Playing Trivia',
        lastSeen: DateTime.now(),
      );
      expect(p.displayText, 'Playing Trivia');
    });

    test('away → "Away"', () {
      expect(_makePresence(PresenceStatus.away).displayText, 'Away');
    });

    test('busy without activity → "Busy"', () {
      expect(_makePresence(PresenceStatus.busy).displayText, 'Busy');
    });

    test('inGame without activity → "In Game"', () {
      expect(_makePresence(PresenceStatus.inGame).displayText, 'In Game');
    });

    test('offline → contains "Last seen"', () {
      final p = _makePresence(PresenceStatus.offline,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 5)));
      expect(p.displayText, contains('Last seen'));
    });
  });

  group('UserPresence — statusColor', () {
    test('each status has a unique non-zero color', () {
      final colors = PresenceStatus.values
          .map((s) => _makePresence(s).statusColor)
          .toSet();
      expect(colors.length, PresenceStatus.values.length);
    });

    test('online is green (0xFF3BA55C)', () {
      expect(_makePresence(PresenceStatus.online).statusColor, 0xFF3BA55C);
    });

    test('offline is gray (0xFF747F8D)', () {
      expect(_makePresence(PresenceStatus.offline).statusColor, 0xFF747F8D);
    });

    test('busy is red (0xFFED4245)', () {
      expect(_makePresence(PresenceStatus.busy).statusColor, 0xFFED4245);
    });
  });

  group('UserPresence — _formatLastSeen (via displayText when offline)', () {
    test('just now for sub-1-minute', () {
      final p = _makePresence(PresenceStatus.offline,
          lastSeen: DateTime.now().subtract(const Duration(seconds: 30)));
      expect(p.displayText, 'Last seen just now');
    });

    test('Xm ago for sub-1-hour', () {
      final p = _makePresence(PresenceStatus.offline,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 10)));
      expect(p.displayText, contains('m ago'));
    });

    test('Xh ago for sub-1-day', () {
      final p = _makePresence(PresenceStatus.offline,
          lastSeen: DateTime.now().subtract(const Duration(hours: 3)));
      expect(p.displayText, contains('h ago'));
    });

    test('Xd ago for 1–6 days', () {
      final p = _makePresence(PresenceStatus.offline,
          lastSeen: DateTime.now().subtract(const Duration(days: 3)));
      expect(p.displayText, contains('d ago'));
    });

    test('over a week ago for 7+ days', () {
      final p = _makePresence(PresenceStatus.offline,
          lastSeen: DateTime.now().subtract(const Duration(days: 10)));
      expect(p.displayText, 'Last seen over a week ago');
    });
  });

  // -------------------------------------------------------------------------
  // UserPresence.toJson / copyWith
  // -------------------------------------------------------------------------

  group('UserPresence.toJson', () {
    test('serializes status as toString()', () {
      final p = _makePresence(PresenceStatus.away);
      expect(p.toJson()['status'], PresenceStatus.away.toString());
    });

    test('gameActivity is null in JSON when not set', () {
      expect(_makePresence(PresenceStatus.online).toJson()['gameActivity'],
          isNull);
    });
  });

  group('UserPresence.copyWith', () {
    test('copies status', () {
      final p = _makePresence(PresenceStatus.online)
          .copyWith(status: PresenceStatus.busy);
      expect(p.status, PresenceStatus.busy);
    });

    test('copies activity', () {
      final p = _makePresence(PresenceStatus.online)
          .copyWith(activity: 'Ranked Match');
      expect(p.activity, 'Ranked Match');
    });

    test('copies customData', () {
      final p = _makePresence(PresenceStatus.online)
          .copyWith(customData: {'key': 'value'});
      expect(p.customData['key'], 'value');
    });

    test('preserves unchanged fields', () {
      final original = UserPresence(
        userId: 'u_orig',
        status: PresenceStatus.online,
        lastSeen: DateTime(2025, 1, 1),
      );
      final updated = original.copyWith(status: PresenceStatus.away);
      expect(updated.userId, 'u_orig');
    });
  });

  // -------------------------------------------------------------------------
  // GameActivity.fromJson / toJson / copyWith / computed props
  // -------------------------------------------------------------------------

  group('GameActivity.fromJson', () {
    test('parses gameType and gameState', () {
      final ga = GameActivity.fromJson(_gameActivityJson(
          gameType: 'trivia', gameState: 'GameState.playing'));
      expect(ga.gameType, 'trivia');
      expect(ga.gameState, GameState.playing);
    });

    test('parses all GameState values via toString()', () {
      for (final state in GameState.values) {
        final ga = GameActivity.fromJson(
            _gameActivityJson(gameState: state.toString()));
        expect(ga.gameState, state);
      }
    });

    test('defaults gameState to playing for unknown string', () {
      final ga = GameActivity.fromJson(_gameActivityJson(gameState: 'bogus'));
      expect(ga.gameState, GameState.playing);
    });

    test('parses optional gameMode and currentLevel', () {
      final ga = GameActivity.fromJson(_gameActivityJson(
        gameMode: 'ranked',
        currentLevel: 'Level 5',
      ));
      expect(ga.gameMode, 'ranked');
      expect(ga.currentLevel, 'Level 5');
    });

    test('parses score and timeRemaining', () {
      final ga = GameActivity.fromJson(
          _gameActivityJson(score: 850, timeRemaining: 25));
      expect(ga.score, 850);
      expect(ga.timeRemaining, 25);
    });

    test('optional fields null when absent', () {
      final ga = GameActivity.fromJson(_gameActivityJson());
      expect(ga.gameMode, isNull);
      expect(ga.score, isNull);
      expect(ga.timeRemaining, isNull);
    });

    test('parses metadata map', () {
      final ga = GameActivity.fromJson(
          _gameActivityJson(metadata: {'allowSpectators': true}));
      expect(ga.metadata['allowSpectators'], isTrue);
    });
  });

  group('GameActivity — computed properties', () {
    test('elapsedTime returns positive duration', () {
      final ga = GameActivity(
        gameType: 'quiz',
        gameState: GameState.playing,
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(ga.elapsedTime.inMinutes, greaterThanOrEqualTo(4));
    });

    test('allowsSpectators true when metadata flag set', () {
      final ga = GameActivity(
        gameType: 'quiz',
        gameState: GameState.playing,
        startTime: DateTime.now(),
        metadata: const {'allowSpectators': true},
      );
      expect(ga.allowsSpectators, isTrue);
    });

    test('allowsSpectators false when flag not set', () {
      final ga = GameActivity(
        gameType: 'quiz',
        gameState: GameState.playing,
        startTime: DateTime.now(),
      );
      expect(ga.allowsSpectators, isFalse);
    });

    test('canJoin true for lobby and waiting states', () {
      for (final state in [GameState.lobby, GameState.waiting]) {
        final ga = GameActivity(
          gameType: 'quiz',
          gameState: state,
          startTime: DateTime.now(),
        );
        expect(ga.canJoin, isTrue,
            reason: 'should be joinable in ${state.name}');
      }
    });

    test('canJoin false for playing, paused, finished', () {
      for (final state in [
        GameState.playing,
        GameState.paused,
        GameState.finished
      ]) {
        final ga = GameActivity(
          gameType: 'quiz',
          gameState: state,
          startTime: DateTime.now(),
        );
        expect(ga.canJoin, isFalse);
      }
    });

    test('formattedDuration returns minutes format for short games', () {
      final ga = GameActivity(
        gameType: 'quiz',
        gameState: GameState.playing,
        startTime: DateTime.now().subtract(const Duration(minutes: 12)),
      );
      expect(ga.formattedDuration, contains('m'));
    });

    test('formattedDuration returns hours format for long games', () {
      final ga = GameActivity(
        gameType: 'quiz',
        gameState: GameState.playing,
        startTime:
            DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      );
      expect(ga.formattedDuration, contains('h'));
      expect(ga.formattedDuration, contains('m'));
    });
  });

  group('GameActivity.toJson', () {
    test('serializes gameState as toString()', () {
      final ga = GameActivity(
        gameType: 'trivia',
        gameState: GameState.finished,
        startTime: DateTime(2025, 1, 1),
      );
      expect(ga.toJson()['gameState'], GameState.finished.toString());
    });
  });

  group('GameActivity.copyWith', () {
    test('copies gameState', () {
      final ga = GameActivity(
        gameType: 'quiz',
        gameState: GameState.playing,
        startTime: DateTime(2025),
      ).copyWith(gameState: GameState.finished);
      expect(ga.gameState, GameState.finished);
    });

    test('copies score', () {
      final ga = GameActivity(
        gameType: 'quiz',
        gameState: GameState.playing,
        startTime: DateTime(2025),
      ).copyWith(score: 750);
      expect(ga.score, 750);
    });

    test('preserves unchanged fields', () {
      final ga = GameActivity(
        gameType: 'trivia',
        gameState: GameState.lobby,
        startTime: DateTime(2025),
      ).copyWith(score: 100);
      expect(ga.gameType, 'trivia');
      expect(ga.gameState, GameState.lobby);
    });
  });
}

// ---------------------------------------------------------------------------
// Local helper
// ---------------------------------------------------------------------------

UserPresence _makePresence(PresenceStatus status, {DateTime? lastSeen}) {
  return UserPresence(
    userId: 'uid_test',
    status: status,
    lastSeen: lastSeen ?? DateTime.now(),
  );
}
